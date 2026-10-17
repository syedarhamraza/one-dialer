import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_wheel_column.dart';
import '../core/haptics/haptics.dart';

/// Samsung One UI style scroll-wheel date picker (month  day  year), the date counterpart
/// of [OneUITimeWheel]. Keeps the selection inside [firstDate]..[lastDate] by springing
/// back when the user scrolls past either end, and clamps the day to the month's length.
///
/// Use a `GlobalKey<OneUIDateWheelState>` to call [OneUIDateWheelState.animateTo].
class OneUIDateWheel extends StatefulWidget {
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  const OneUIDateWheel({
    super.key,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  State<OneUIDateWheel> createState() => OneUIDateWheelState();
}

class OneUIDateWheelState extends State<OneUIDateWheel> {
  static const Duration _animation = Duration(milliseconds: 380);
  static final List<String> _monthNames = [for (var m = 1; m <= 12; m++) DateFormat.MMM().format(DateTime(2000, m))];

  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _yearController;

  late int _year;
  late int _month; // 1–12
  late int _day; // 1–31

  /// True while wheels are driven programmatically, so passing items don't tick or re-clamp.
  bool _animating = false;

  DateTime get _first => _dateOnly(widget.firstDate);
  DateTime get _last => _dateOnly(widget.lastDate);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime get _current => DateTime(_year, _month, _day);

  DateTime _clampToRange(DateTime d) {
    final date = _dateOnly(d);
    if (date.isBefore(_first)) return _first;
    if (date.isAfter(_last)) return _last;
    return date;
  }

  @override
  void initState() {
    super.initState();
    final start = _clampToRange(widget.date);
    _year = start.year;
    _month = start.month;
    _day = start.day;
    // The month wheel loops, so it starts far from index 0 to scroll both ways freely.
    _monthController = FixedExtentScrollController(initialItem: 12 * 100 + (_month - 1));
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _yearController = FixedExtentScrollController(initialItem: _year - _first.year);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  static int _nearestLoopingIndex(int current, int value, int length) {
    final delta = ((value - current) % length + length) % length;
    return delta > length ~/ 2 ? current + delta - length : current + delta;
  }

  void _onWheelChanged() {
    if (_animating) return;
    Haptics.select();

    // Keep the day valid for the selected month (e.g. Mar 31 -> Feb 28).
    final maxDay = daysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dayController.hasClients) _dayController.jumpToItem(maxDay - 1);
      });
    }

    // Spring back inside the allowed range.
    final clamped = _clampToRange(_current);
    if (clamped != _current) {
      animateTo(clamped);
      return;
    }
    setState(() {});
    widget.onChanged(_current);
  }

  /// Smoothly scrolls every wheel to [date] (clamped to the allowed range).
  Future<void> animateTo(DateTime date) async {
    final target = _clampToRange(date);
    _year = target.year;
    _month = target.month;
    _day = target.day;
    setState(() {}); // Day count may change before the day wheel animates.
    _animating = true;
    try {
      await Future.wait([
        _monthController.animateToItem(
          _nearestLoopingIndex(_monthController.selectedItem, _month - 1, 12),
          duration: _animation,
          curve: Curves.easeOutCubic,
        ),
        _dayController.animateToItem(_day - 1, duration: _animation, curve: Curves.easeOutCubic),
        _yearController.animateToItem(_year - _first.year, duration: _animation, curve: Curves.easeOutCubic),
      ]);
    } finally {
      _animating = false;
    }
    // Wheels report intermediate items while animating; settle on the exact target.
    _year = target.year;
    _month = target.month;
    _day = target.day;
    if (mounted) setState(() {});
    widget.onChanged(target);
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 52,
      fontWeight: FontWeight.w600,
      height: 1,
      letterSpacing: -1.0,
      color: OneUITheme.textPrimary,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    // Scales down on narrow phones instead of overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OneUIWheelColumn(
            controller: _monthController,
            count: 12,
            looping: true,
            width: 120,
            label: (i) => _monthNames[i],
            semanticsLabel: (i) => DateFormat.MMMM().format(DateTime(2000, i + 1)),
            onSelected: (i) {
              _month = i + 1;
              _onWheelChanged();
            },
            style: style,
          ),
          const SizedBox(width: 12),
          OneUIWheelColumn(
            controller: _dayController,
            count: daysInMonth(_year, _month),
            looping: false,
            width: 84,
            label: (i) => '${i + 1}',
            semanticsLabel: (i) => 'Day ${i + 1}',
            onSelected: (i) {
              _day = i + 1;
              _onWheelChanged();
            },
            style: style,
          ),
          const SizedBox(width: 12),
          OneUIWheelColumn(
            controller: _yearController,
            count: _last.year - _first.year + 1,
            looping: false,
            width: 140,
            label: (i) => '${_first.year + i}',
            semanticsLabel: (i) => 'Year ${_first.year + i}',
            onSelected: (i) {
              _year = _first.year + i;
              _onWheelChanged();
            },
            style: style,
          ),
        ],
      ),
    );
  }
}
