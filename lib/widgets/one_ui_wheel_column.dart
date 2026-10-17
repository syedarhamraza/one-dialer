import 'package:flutter/material.dart';

/// One Samsung One UI scroll-wheel column: flat (not a 3D drum), three rows tall,
/// the centre item full strength and its neighbours dimmed.
/// Shared by [OneUITimeWheel] and [OneUIDateWheel] so both pickers look identical.
class OneUIWheelColumn extends StatelessWidget {
  static const double itemExtent = 96;

  final FixedExtentScrollController controller;
  final int count;
  final bool looping;
  final double width;
  final String Function(int index) label;
  final String Function(int index) semanticsLabel;
  final ValueChanged<int> onSelected;
  final TextStyle style;

  const OneUIWheelColumn({
    super.key,
    required this.controller,
    required this.count,
    required this.looping,
    required this.width,
    required this.label,
    required this.semanticsLabel,
    required this.onSelected,
    required this.style,
  });

  Widget _item(int index) => Semantics(
    label: semanticsLabel(index),
    child: Center(child: Text(label(index), style: style)),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: itemExtent * 3,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: itemExtent,
        physics: const FixedExtentScrollPhysics(),
        // Flat, Samsung-style wheel rather than a 3D drum.
        diameterRatio: 100,
        perspective: 0.001,
        overAndUnderCenterOpacity: 0.25,
        onSelectedItemChanged: (index) => onSelected(index % count),
        childDelegate: looping
            ? ListWheelChildLoopingListDelegate(children: [for (var i = 0; i < count; i++) _item(i)])
            : ListWheelChildBuilderDelegate(builder: (_, i) => _item(i), childCount: count),
      ),
    );
  }
}
