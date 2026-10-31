import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import '../core/haptics/haptics.dart';

/// Authentic Samsung One UI toggle switch matching One UI specifications.
///
/// Visual Specifications:
/// - Compact 40×23dp pill-shaped track.
/// - 17dp crisp white circular thumb with 3dp padding from track edges.
/// - Smooth 200ms cubic slide animation.
/// - Samsung One UI accent blue track when active, dark slate (#38383A) when inactive.
/// - Subtle soft drop shadow on the white thumb.
/// - Integrated light haptic feedback on toggle.
class OneUISwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeTrackColor;

  /// Defaults to a dark slate on dark pages and ColorOS's light grey on light ones.
  final Color? inactiveTrackColor;

  const OneUISwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor = OneUITheme.accentBlue,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () {
          Haptics.select();
          onChanged(!value);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          width: 40,
          height: 23,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.5),
            color: value
                ? activeTrackColor
                : inactiveTrackColor ?? (context.palette.isLight ? const Color(0xFFD1D1D6) : const Color(0xFF38383A)),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 17,
            height: 17,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2.5, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}
