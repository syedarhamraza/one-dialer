import 'package:flutter/material.dart';

/// Soft radial glow placed behind a glass hero card (as the first child of its `Stack`).
/// The colour reflects the card's state and cross-fades when it changes.
class OneUIAmbientGlow extends StatelessWidget {
  final Color color;
  final Alignment center;
  final double radius;

  /// Opacity of [color] at each of [stops]; the last is usually 0.
  final List<double> alphas;
  final List<double> stops;

  static const Duration duration = Duration(milliseconds: 500);

  const OneUIAmbientGlow({
    super.key,
    required this.color,
    this.center = const Alignment(0.0, -0.2),
    this.radius = 1.05,
    this.alphas = const [0.26, 0.11, 0.02, 0.0],
    this.stops = const [0.0, 0.50, 0.85, 1.0],
  }) : assert(alphas.length == stops.length);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            final c = value ?? color;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: center,
                  radius: radius,
                  colors: [for (final a in alphas) c.withValues(alpha: a)],
                  stops: stops,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
