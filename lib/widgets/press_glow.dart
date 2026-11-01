import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart';

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
    if (color == null && shadows == null) return press;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [...?shadows, if (color != null) ...?solidBody(color, shape, glow: .22).shadows],
      ),
      child: press,
    );
  }
}

/// A lit (green) button's body and press: the call screen's shaded body, light from below and
/// coloured glow at full visual effects; a flat One UI [color] fill with the same press below.
/// Switches live.
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
      builder: (context, child) {
        // The glass style's 3D edges, so the green buttons match the glass around them (none
        // past the solid button's own glow with classic). At the glass's opacity too: the glass
        // draws its edges through it, and a little softer still: over solid green they read stronger.
        final look = fx.isFull ? mainGlass(context) : null;
        final scale = (look?.opacity ?? 1) * .7;
        final edges = look == null || look.edges == GlassEdges.callScreen
            ? GlassEdges.callScreen
            : GlassEdges(
                strength: look.edges.strength * scale,
                bottomLip: look.edges.bottomLip * scale,
                lip: look.edges.lip,
              );
        return PressGlow(
          radius: radius,
          glowColor: fx.isFull ? color : null,
          child: Container(
            decoration: fx.isFull ? solidBody(color, shape, glow: 0) : ShapeDecoration(color: color, shape: shape),
            foregroundDecoration: fx.isFull ? solidGlow(shape, strength: edges.strength) : null,
            child: edges == GlassEdges.callScreen
                ? child
                // From a cached image: drawn live, the lips' side fade was a save layer every frame.
                : CallBodyArtwork(
                    radius: shape is CircleBorder ? null : double.infinity,
                    edges: edges,
                    lipsOnly: true,
                    child: child!,
                  ),
          ),
        );
      },
      child: child,
    );
  }
}
