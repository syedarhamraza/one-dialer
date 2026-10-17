import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// Samsung One UI Custom Radio Button Component
///
/// Features:
/// - Unselected: Muted outline stroke
/// - Selected: Accent-filled circle with a centered inner dot
/// - Smooth animated transitions
class OneUIRadio extends StatelessWidget {
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final double size;

  const OneUIRadio({
    super.key,
    required this.isSelected,
    this.selectedColor = OneUITheme.accentBlue,
    this.unselectedColor = const Color(0xFF5E5E62),
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? selectedColor : unselectedColor, width: isSelected ? 2.0 : 1.6),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Container(
              width: size * 0.48,
              height: size * 0.48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: selectedColor),
            )
          : null,
    );
  }
}
