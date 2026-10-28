import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// The one floating "glass" surface used by every piece of floating chrome: the nav
/// bar, header buttons, search capsules, Cancel | Save pills, action bars, menus,
/// sheets and modals.
///
/// It follows **Settings › Appearance › 3D floating elements**:
/// - **Flat:** translucent fill + background blur, no outline and no gradient, with
///   only a soft ambient shadow (none for [OneUIGlassElevation.modal]).
/// - **3D:** a top-lit vertical gradient body, a rim light that is bright on the top
///   edge and fades down the sides, and a soft drop shadow.
///
/// [progress] (0–1) fades the whole surface in while the [child] stays fully visible.
/// Collapsing headers use it to grow a backing behind their buttons as you scroll.
class OneUIGlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final OneUIGlassElevation elevation;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final double progress;

  /// Animates size/padding changes (the fill itself always tracks the 3D setting).
  final Duration duration;

  const OneUIGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(OneUITheme.radiusPill)),
    this.elevation = OneUIGlassElevation.floating,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.progress = 1.0,
    this.duration = const Duration(milliseconds: 250),
  });

  /// A circular button surface of [size].
  const OneUIGlassSurface.circle({
    super.key,
    required this.child,
    required double size,
    this.elevation = OneUIGlassElevation.floating,
    this.progress = 1.0,
    this.duration = const Duration(milliseconds: 250),
  }) : width = size,
       height = size,
       borderRadius = const BorderRadius.all(Radius.circular(999)),
       padding = null,
       alignment = Alignment.center;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final fx = OneUIEffectsController.instance;
        final t = progress.clamp(0.0, 1.0);
        final isModal = elevation == OneUIGlassElevation.modal;

        final body = AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          padding: padding,
          alignment: alignment,
          decoration: t <= 0.05
              ? null
              : BoxDecoration(
                  color: fx.floating3dEffect ? null : _fade(isModal ? fx.modalColor : fx.floatingColor, t),
                  gradient: (isModal ? fx.modalGradient : fx.floatingGradient)?.scale(t),
                  borderRadius: borderRadius,
                ),
          // Glass keeps the dark look in light mode too.
          child: Theme(data: OneUITheme.darkTheme, child: child),
        );

        // Fully faded out: no blur, clip or shadow work at all.
        if (t <= 0.05) return body;

        final rim = fx.floatingRimGradient;
        final shadows = [
          for (final s in fx.glassShadow(elevation)) t >= 1.0 ? s : s.copyWith(color: _fade(s.color, t)),
        ];

        return DecoratedBox(
          decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: fx.blurSigma * t, sigmaY: fx.blurSigma * t),
              child: rim == null
                  ? body
                  : CustomPaint(
                      foregroundPainter: OneUIRimPainter(gradient: rim, borderRadius: borderRadius, opacity: t),
                      child: body,
                    ),
            ),
          ),
        );
      },
    );
  }

  static Color _fade(Color c, double t) => c.withValues(alpha: c.a * t);
}

/// Strokes a rounded-rect outline with a gradient: the 3D "rim light" on glass
/// surfaces and the selected nav capsule.
class OneUIRimPainter extends CustomPainter {
  final Gradient gradient;
  final BorderRadius borderRadius;
  final double opacity;
  final double strokeWidth;

  const OneUIRimPainter({
    required this.gradient,
    required this.borderRadius,
    this.opacity = 1.0,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final rrect = borderRadius.toRRect(rect).deflate(inset);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.scale(opacity).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(OneUIRimPainter old) =>
      old.gradient != gradient ||
      old.borderRadius != borderRadius ||
      old.opacity != opacity ||
      old.strokeWidth != strokeWidth;
}
