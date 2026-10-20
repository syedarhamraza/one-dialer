import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'press_glow.dart';

/// The connected call screen's control look for floating chrome: the backdrop blurred
/// behind, the call body's milky wash, all-round edge glow and top lip, and its press
/// (squeeze, stretch toward the finger, glow). A circle, or squircle-ended with [radius].
class CallGlass extends StatelessWidget {
  const CallGlass({super.key, this.radius, required this.child});

  final double? radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sigma = OneUIEffectsController.instance.blurSigma;
    final body = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: CustomPaint(painter: TintedCallBody(radius), child: const SizedBox.expand()),
    );
    // Claims vertical drags that start on it, so holding and moving a pill inside a
    // scrolling page plays the press instead of scrolling the page.
    return GestureDetector(
      onVerticalDragStart: _ignoreDrag,
      child: PressGlow(
        radius: radius ?? 999,
        // Only the frosted body is clipped; the content draws on top unclipped, so a
        // springy thumb can overshoot the edge.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: radius == null
                  ? ClipOval(child: body)
                  : ClipRSuperellipse(borderRadius: BorderRadius.all(Radius.circular(radius!)), child: body),
            ),
            child,
          ],
        ),
      ),
    );
  }

  static void _ignoreDrag(DragStartDetails _) {}
}
