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

  /// A lit button's colour (see [solidBody]): its glow is drawn here, outside the press's clip,
  /// which would otherwise cut it off.
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
      child: child,
    );
    final color = glowColor;
    if (color == null) return press;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: solidBody(color, shape).shadows),
      child: press,
    );
  }
}
