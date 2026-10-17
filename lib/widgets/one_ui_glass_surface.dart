import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/one_ui_theme.dart';

/// Dialer change from OneSpend: rendered as liquid glass (`liquid_glass_widgets`) instead
/// of a translucent fill with a backdrop blur; the size, padding and API are unchanged.
///
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

  /// Dark tints keep text readable over the black pages; modals carry more text.
  static const _floatingTint = Color(0x5C1C1C20);
  static const _modalTint = Color(0x9E18181C);

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final body = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      child: child,
    );

    // Fully faded out: no glass work at all.
    if (t <= 0.05) return body;

    final radius = borderRadius.topLeft.x;
    final isModal = elevation == OneUIGlassElevation.modal;
    return GlassContainer(
      useOwnLayer: true,
      // Premium for the bottom bars (nav, action, Cancel | Save); standard elsewhere.
      quality: elevation == OneUIGlassElevation.navbar ? GlassQuality.premium : GlassQuality.standard,
      shape: radius >= 999 ? const LiquidOval() : LiquidRoundedSuperellipse(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      settings: LiquidGlassSettings(
        visibility: t,
        glassColor: isModal ? _modalTint : _floatingTint,
        thickness: isModal ? 14 : 22,
        blur: isModal ? 12 : 6,
      ),
      child: body,
    );
  }
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
