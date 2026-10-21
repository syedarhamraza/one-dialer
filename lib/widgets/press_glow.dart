import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../features/in_call/call_controls.dart';

/// The call screen's press for ordinary buttons: the glass package's glow and stretch with no
/// glass body (the transparent style draws no shader, so the main engine needs no
/// `LiquidGlassWidgets.initialize()`). Taps and semantics stay with the button inside.
class PressGlow extends StatelessWidget {
  const PressGlow({super.key, this.radius = 999, this.glowColor, required this.child});

  /// Corner radius; the default is clamped to a pill at any height.
  final double radius;

  /// A lit button's colour (see [solidBody]): its glow is drawn here (the button's own body
  /// draws none), outside the press's clip, which would otherwise cut it off. Softer than
  /// the call screen's, to match the main app's gentler glass glow.
  final Color? glowColor;
  final Widget child;

  static void _noTap() {}

  @override
  Widget build(BuildContext context) {
    final press = GlassButton.custom(
      style: GlassButtonStyle.transparent,
      onTap: _noTap,
      excludeFromSemantics: true,
      canRequestFocus: false,
      shape: LiquidRoundedRectangle(borderRadius: radius),
      // The package's own finger glow (radius 1.6, its dark/light colour), minus its sigma-16
      // mask blur: on a gradient this wide the blur changes under 1/255, but it blurred a
      // circle 1.6× the button offscreen on every pointer move (~30 ms a frame on the menu card).
      glowRadius: 1.6,
      glowBlurRadius: 0,
      glowColor: GlassTheme.brightnessOf(context) == Brightness.dark
          ? const Color(0x12FFFFFF)
          : const Color(0x1AFFFFFF),
      child: child,
    );
    final color = glowColor;
    if (color == null) return press;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: solidBody(color, shape, glow: .22).shadows),
      child: press,
    );
  }
}
