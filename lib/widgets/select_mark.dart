import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// A list row's selection circle. It always occupies the same slot in the row (empty when
/// not selecting), so entering selection mode doesn't shift and rebuild the row's children.
class SelectMark extends StatelessWidget {
  const SelectMark({super.key, required this.selected, required this.gap});

  /// null when not selecting.
  final bool? selected;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    if (selected == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(right: gap),
      child: Icon(
        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: selected ? OneUITheme.accentBlue : OneUITheme.textTertiary,
      ),
    );
  }
}
