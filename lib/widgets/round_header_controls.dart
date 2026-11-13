import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../l10n/l10n.dart';
import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart';

/// A header icon on its own round grey background (search, menu, cancel).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CallGlass(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        // Exactly 48: Material would pad a smaller one to a 48 dp tap target anyway.
        style: IconButton.styleFrom(
          foregroundColor: context.palette.textPrimary,
          fixedSize: const Size.square(48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 26),
      ),
    );
  }
}

/// Segmented tabs in a grey pill (All | Missed), the selected one on a lighter thumb
/// that slides between them.
class FilterTabs extends StatefulWidget {
  const FilterTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.bare = false,
    this.blur = true,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Without its own glass body, for a parent that draws one (the Calls header morph).
  final bool bare;

  /// False skips the backdrop blur ([CallGlass.blur]), for tabs on the plain page.
  final bool blur;

  /// The thumb's spring; the floating menu's highlight moves on it too.
  static Curve get thumbSpring => _FilterTabsState.thumbSpring;

  /// The pill's size for [count] tabs.
  static Size sizeFor(int count) =>
      Size(count * _FilterTabsState._tabWidth + 2 * _FilterTabsState._inset, _FilterTabsState._height);

  @override
  State<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<FilterTabs> {
  late int _index = widget.index;

  @override
  void didUpdateWidget(FilterTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) _index = widget.index;
  }

  /// Moves the highlight this frame and hands the (heavier) list change to the next,
  /// so the slide starts without waiting on the rebuild.
  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(i));
  }

  static const double _tabWidth = 74;
  static const double _height = 48; // as tall as the round buttons
  static const double _inset = 4;

  /// Springier than the call screen's toggle: it swings past the tab and settles back.
  static final thumbSpring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 260, ratio: .6),
    const Duration(milliseconds: 600),
  );

  static const _thumb = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(_height / 2 - _inset)),
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      child: SizedBox(
        width: _tabWidth * widget.labels.length,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Slid by a paint-only transform on its own layer, so the move doesn't
            // re-lay out the pill or repaint the blur behind it each frame.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _tabWidth,
              child: RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _index * _tabWidth),
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                  curve: thumbSpring,
                  builder: (context, x, child) => Transform.translate(offset: Offset(x, 0), child: child),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: context.palette.isLight ? const Color(0x14000000) : const Color(0x3DFFFFFF),
                      shape: _thumb,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < widget.labels.length; i++)
                  Semantics(
                    button: true,
                    selected: i == _index,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _select(i),
                      child: SizedBox(
                        width: _tabWidth,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: i == _index ? context.palette.textPrimary : context.palette.textSecondary,
                            ),
                            // Scales a long label (Italian) down instead of wrapping it.
                            child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.labels[i], maxLines: 1)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return widget.bare ? content : CallGlass(radius: _height / 2, blur: widget.blur, child: content);
  }
}

/// A selection-mode header pill's label (Cancel, Select all / Deselect all): ColorOS's text
/// pill, without its glass, so a header can morph the glass around it. A changed label
/// cross-fades.
class SelectionPillLabel extends StatelessWidget {
  const SelectionPillLabel({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  static const double _padding = 18;

  static TextStyle _style(BuildContext context) =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: context.palette.textPrimary);

  /// The pill's width for [text]: measured, so it fits any language.
  static double widthFor(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(_style(context))),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return (width + 2 * _padding).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: Center(
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
            child: Text(text, key: ValueKey(text), maxLines: 1, softWrap: false, style: _style(context)),
          ),
        ),
      ),
    );
  }
}

/// A subpage's header that morphs into selection mode like the Calls tab's: Back grows into
/// Cancel, the trailing button (or nothing) into Select all, the title into [selectionTitle].
/// Only the pills' contents fade; the glass itself just changes width.
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({
    super.key,
    required this.selecting,
    required this.title,
    required this.selectionTitle,
    required this.allSelected,
    required this.onCancel,
    required this.onToggleSelectAll,
    this.onBack,
    this.trailingIcon,
    this.trailingTooltip,
    this.onTrailing,
  });

  final bool selecting;
  final String title;
  final String selectionTitle;
  final bool allSelected;
  final VoidCallback onCancel;
  final VoidCallback onToggleSelectAll;
  final VoidCallback? onBack;
  final IconData? trailingIcon;
  final String? trailingTooltip;
  final VoidCallback? onTrailing;

  static const double _button = 48;
  static const double _gap = 14;

  static final _morphSpring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 240, ratio: .78),
    const Duration(milliseconds: 550),
  );

  static double _out(double t) => (1 - t * 2).clamp(0.0, 1.0);
  static double _in(double t) => (t * 2 - 1).clamp(0.0, 1.0);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  Widget _icon(BuildContext context, IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      foregroundColor: context.palette.textPrimary,
      fixedSize: const Size.square(_button),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: Icon(icon, size: 26),
  );

  /// A glass pill [width] wide at morph point [sel], showing [idle] then [active].
  Widget _pill(double sel, double width, Widget? idle, Widget active, double activeWidth) => SizedBox(
    width: width,
    height: _button,
    child: CallGlass(
      radius: _button / 2,
      // Clipped only mid-morph, as in the Calls header.
      child: ClipRSuperellipse(
        borderRadius: const BorderRadius.all(Radius.circular(_button / 2)),
        clipBehavior: sel == 0 || sel == 1 ? Clip.none : Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (idle != null)
              IgnorePointer(
                ignoring: selecting,
                child: Opacity(opacity: _out(sel), child: idle),
              ),
            IgnorePointer(
              ignoring: !selecting,
              child: Opacity(
                opacity: _in(sel),
                child: OverflowBox(minWidth: activeWidth, maxWidth: activeWidth, child: active),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final cancelWidth = SelectionPillLabel.widthFor(context, l10n.cancel);
    final selectAllText = allSelected ? l10n.deselectAll : l10n.selectAll;
    final selectAllWidth = SelectionPillLabel.widthFor(context, selectAllText);
    final trailing = trailingIcon == null ? null : _icon(context, trailingIcon!, trailingTooltip ?? '', onTrailing);
    const titleStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3);
    return SizedBox(
      height: _button,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: selecting ? 1 : 0),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 550),
        curve: _morphSpring,
        builder: (context, sel, _) {
          final lead = _lerp(_button, cancelWidth, sel);
          // "N selected" centred on the header, kept clear of the wider pill on both sides.
          final side = math.max(cancelWidth, selectAllWidth) + _gap;
          return Stack(
            children: [
              Positioned.fill(
                left: side,
                right: side,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _in(sel),
                    child: Center(
                      child: Text(selectionTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _pill(
                    sel,
                    lead,
                    _icon(
                      context,
                      Icons.arrow_back_rounded,
                      l10n.back,
                      onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                    SelectionPillLabel(text: l10n.cancel, onTap: onCancel),
                    cancelWidth,
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: Opacity(
                      opacity: _out(sel),
                      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
                    ),
                  ),
                  // The right pill's width also follows its label (Select all ⇄ Deselect all).
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: selectAllWidth),
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                    curve: FilterTabs.thumbSpring,
                    builder: (context, labelWidth, _) {
                      final from = trailing == null ? 0.0 : _button;
                      if (sel == 0 && trailing == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _pill(
                          sel,
                          _lerp(from, labelWidth, sel).clamp(0.0, labelWidth + 6),
                          trailing,
                          SelectionPillLabel(text: selectAllText, onTap: onToggleSelectAll),
                          labelWidth,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// How far a tab's big title has gone under its header bar (0 to 1), fed from the list's
/// scroll offset; [titleTop] is where the title's text starts below the bar.
class TitleCollapse extends ValueNotifier<double> {
  TitleCollapse({required this.titleTop}) : super(0);

  final double titleTop;

  /// The title's travel under the bar: the big one fades over the first half, the small one
  /// over the second, so the two never show at once.
  static const double _span = 44;

  /// For a `NotificationListener<ScrollUpdateNotification>` around the tab's list.
  bool track(ScrollUpdateNotification n) {
    if (n.depth == 0) value = ((n.metrics.pixels - titleTop) / _span).clamp(0.0, 1.0);
    return false;
  }
}

/// The small title that takes the big one's place at the left of the header bar
/// (ColorOS), fading and rising in as [collapse] goes from 0 to 1.
class HeaderTitle extends StatelessWidget {
  const HeaderTitle({
    super.key,
    required this.collapse,
    required this.text,
    this.hidden = false,
    this.centered = false,
  });

  final TitleCollapse collapse;
  final String text;

  /// In the middle of the bar, between the selection pills (ColorOS's "N selected").
  final bool centered;

  /// While the header uses its left side (selecting, typing), or a pill would cover it.
  final bool hidden;

  static const double _left = 20;

  static TextStyle _style(BuildContext context, double shown) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: context.palette.textPrimary.withValues(alpha: shown),
  );

  /// Where [text] ends, as this title draws it: for headers that must keep their pills clear of it.
  static double rightEdge(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(_style(context, 1))),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return _left + width;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centered ? 0 : _left,
      right: centered ? 0 : null,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          // Hiding fades, so a header can cross-fade two titles (Contacts ↔ N selected).
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: hidden ? 0 : 1),
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
            builder: (context, visible, _) => ValueListenableBuilder(
              valueListenable: collapse,
              builder: (context, t, _) {
                final shown = visible * (t * 2 - 1).clamp(0.0, 1.0);
                // Not there at all while hidden, so screen readers don't read it twice.
                if (shown == 0) return const SizedBox.shrink();
                return Transform.translate(
                  offset: Offset(0, (1 - shown) * 10),
                  // Smaller between the pills, as ColorOS draws it.
                  child: Text(
                    text,
                    maxLines: 1,
                    style: _style(context, shown).copyWith(fontSize: centered ? 18 : null),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The big title fading out as [collapse] rises, by its colour (no Opacity layer).
class BigTitle extends StatelessWidget {
  const BigTitle({super.key, required this.collapse, required this.text});

  final TitleCollapse collapse;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: collapse,
      builder: (context, t, _) => Text(
        text,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: context.palette.textPrimary.withValues(alpha: (1 - t * 2).clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}
