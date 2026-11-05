import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';

/// The call screen's press for ordinary buttons: the glass package's glow and stretch with no
/// glass body (the transparent style draws no shader, so the main engine needs no
/// `LiquidGlassWidgets.initialize()`). Taps and semantics stay with the button inside.
class PressGlow extends StatelessWidget {
  const PressGlow({super.key, this.radius = 999, this.glowColor, this.shadows, required this.child});

  /// Corner radius; the default is clamped to a pill at any height.
  final double radius;

  /// A lit button's colour (see [solidBody]): its glow is drawn here (the button's own body
  /// draws none), outside the press's clip, which would otherwise cut it off. Softer than
  /// the call screen's, to match the main app's gentler glass glow.
  final Color? glowColor;

  /// Drop shadows (light mode's glass), drawn outside the press's clip like [glowColor]'s glow.
  final List<BoxShadow>? shadows;
  final Widget child;

  static void _noTap() {}

  @override
  Widget build(BuildContext context) {
    final full = OneUIEffectsController.instance.isFull;
    final press = GlassButton.custom(
      style: GlassButtonStyle.transparent,
      // Below full effects there's no glass, so no glass lighting on press either (the even white
      // lift while held, and the finger glow below): just the squeeze.
      ambientBaseLight: full ? null : 0,
      onTap: _noTap,
      excludeFromSemantics: true,
      canRequestFocus: false,
      shape: LiquidRoundedRectangle(borderRadius: radius),
      // The package's own finger glow (radius 1.6, its dark/light colour), minus its sigma-16
      // mask blur: on a gradient this wide the blur changes under 1/255, but it blurred a
      // circle 1.6× the button offscreen on every pointer move (~30 ms a frame on the menu card).
      glowRadius: 1.6,
      glowBlurRadius: 0,
      // Light mode's white glass hides a white glow: a faint shade instead.
      glowColor: !full
          ? Colors.transparent
          : context.palette.isLight
          ? const Color(0x0F000000)
          : GlassTheme.brightnessOf(context) == Brightness.dark
          ? const Color(0x12FFFFFF)
          : const Color(0x1AFFFFFF),
      child: child,
    );
    final color = glowColor;
    if (color == null && shadows == null) return press;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          ...?shadows,
          if (color != null) ...?solidBody(color, shape, glow: .22, light: context.palette.isLight).shadows,
        ],
      ),
      child: press,
    );
  }
}

/// A lit (green) button's body and press, ColorOS's keypad Call look: at full visual effects a
/// flat fill with a thin rim (light on top, a brighter green underneath), a soft shadow and a
/// coloured press glow; a flat One UI [color] fill with the same press below. Switches live.
class LitButton extends StatelessWidget {
  const LitButton({super.key, required this.color, required this.shape, this.radius = 999, required this.child});

  final Color color;
  final OutlinedBorder shape;

  /// The press's corner radius (see [PressGlow.radius]).
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fx = OneUIEffectsController.instance;
    return ListenableBuilder(
      listenable: fx,
      builder: (context, child) => PressGlow(
        radius: radius,
        glowColor: fx.isFull ? color : null,
        child: Container(
          decoration: ShapeDecoration(
            color: color,
            shape: shape,
            shadows: fx.isFull
                ? [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: fx.isFull ? CustomPaint(foregroundPainter: _RimPainter(shape, color), child: child) : child,
        ),
      ),
      child: child,
    );
  }
}

/// [LitButton]'s rim: faint white along the top, clear through the middle, a brighter
/// green along the bottom.
class _RimPainter extends CustomPainter {
  _RimPainter(this.shape, this.color);

  final OutlinedBorder shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 1.5;
    final rect = (Offset.zero & size).deflate(width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: .35),
          Colors.white.withValues(alpha: 0),
          Color.lerp(color, Colors.white, .12)!.withValues(alpha: 0),
          Color.lerp(color, Colors.white, .12)!,
        ],
        stops: const [0, .3, .6, 1],
      ).createShader(rect);
    canvas.drawPath(shape.getOuterPath(rect), paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.shape != shape || old.color != color;
}
