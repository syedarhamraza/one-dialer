import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'liquid_body.dart';
import 'press_glow.dart';

/// How strong the call-glass edge glow is on the main app's chrome: softer than on
/// the call screen, where the controls sit on a dark gradient.
const double kMainGlassGlow = .6;

/// The main app's call glass at full effects, by Settings › "Dark mode edge glow": how
/// strongly the body (wash, glow and lips) is drawn, and its 3D edges. Classic is the
/// original look ([classicOpacity] per control); soft (the default) is half the glass, like
/// ColorOS 17's Phone, with brighter edges; bold brightens and thickens them more.
GlassLook mainGlass(BuildContext context, {double classicOpacity = 1}) =>
    // Light mode has one look: soft's edges at full strength (halved, the light wash reads grey).
    context.palette.isLight
    ? (opacity: 1, edges: glassLook('soft').edges)
    : glassLook(OneUIEffectsController.instance.glassStyle, classicOpacity: classicOpacity);

/// The connected call screen's control look for floating chrome: the backdrop blurred
/// behind, the call body's milky wash, all-round edge glow and top lip, and its press
/// (squeeze, stretch toward the finger, glow). A circle, or squircle-ended with [radius].
///
/// Below full visual effects it's OneSpend's flat One UI glass instead
/// ([OneUIEffectsController.oneUIFill]): over a blur when reduced, solid when off.
class CallGlass extends StatelessWidget {
  const CallGlass({super.key, this.radius, this.blur = true, required this.child});

  final double? radius;
  final Widget child;

  /// False draws the same body without reading the backdrop, for glass that sits on the
  /// plain page (in the scrolling content), where a blur shows nothing but costs a pass.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final fx = OneUIEffectsController.instance;
    bool liquid() => fx.liquidControls && blur; // read live: the builder below rebuilds on fx
    Widget body(BuildContext context) {
      // Settings › "Glass style" › Liquid glass: the glass package's own (its own backdrop read).
      if (liquid()) return liquidBody(context, radius: radius ?? 999);
      if (fx.isFull) {
        final look = mainGlass(context);
        if (!blur) {
          return CallBodyArtwork(
            radius: radius,
            glow: kMainGlassGlow,
            opacity: look.opacity,
            edges: look.edges,
            child: const SizedBox.expand(),
          );
        }
        // Grouped: inside the shell's tabs, every glass control shares one backdrop read (see
        // MainShell), as do a pushed page's (DialerApp's page transition); the nav bar blurs on its own.
        return BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: fx.blurSigma, sigmaY: fx.blurSigma),
          // From a cached image, like the keypad keys: drawn live, its blurred strokes were
          // re-rendered every frame of a press (the press scales them).
          child: CallBodyArtwork(
            radius: radius,
            glow: kMainGlassGlow,
            opacity: look.opacity,
            edges: look.edges,
            child: const SizedBox.expand(),
          ),
        );
      }
      final fill = ColoredBox(
        color: fx.oneUIFill(light: context.palette.isLight),
        child: const SizedBox.expand(),
      );
      if (fx.isOff || !blur) return fill;
      return BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: fx.blurSigma, sigmaY: fx.blurSigma),
        child: fill,
      );
    }

    // Claims vertical drags that start on it, so holding and moving a pill inside a
    // scrolling page plays the press instead of scrolling the page.
    return ListenableBuilder(
      listenable: fx,
      builder: (context, _) => GestureDetector(
        onVerticalDragStart: _ignoreDrag,
        child: PressGlow(
          radius: radius ?? 999,
          // Below full visual effects light mode is flat One UI: no shadows.
          shadows: context.palette.isLight && fx.isFull && !liquid() ? OneUIPalette.lightGlassShadow : null,
          // Only the frosted body is clipped; the content draws on top unclipped, so a
          // springy thumb can overshoot the edge.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                // Liquid glass shapes itself: a clip around it would only cost a layer.
                child: liquid()
                    ? body(context)
                    : radius == null
                    ? ClipOval(child: body(context))
                    : ClipRSuperellipse(borderRadius: BorderRadius.all(Radius.circular(radius!)), child: body(context)),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  static void _ignoreDrag(DragStartDetails _) {}
}
