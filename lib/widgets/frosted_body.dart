import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The glass package's press (squeeze, stretch toward the finger, glow) with no glass body, as
/// on the call screen's controls. It reads raw pointer events only, so taps and semantics stay
/// with [child].
class GlassPress extends StatelessWidget {
  const GlassPress({super.key, this.radius, required this.child});
  final double? radius;
  final Widget child;

  static void _taps() {}

  @override
  Widget build(BuildContext context) => GlassButton.custom(
    style: GlassButtonStyle.transparent,
    onTap: _taps,
    excludeFromSemantics: true,
    canRequestFocus: false,
    shape: radius == null ? const LiquidOval() : LiquidRoundedSuperellipse(borderRadius: radius!),
    child: child,
  );
}

/// ColorOS 17's frosted body (milky wash, edge glow, lips) over whatever blur is behind it: a
/// circle, or a squircle-ended shape with [radius]. Only the artwork is rasterized, once per
/// size, so a glass press or the keypad's scale reuses it.
class FrostedBody extends StatefulWidget {
  const FrostedBody({super.key, required this.radius, required this.child});
  final double? radius;
  final Widget child;

  @override
  State<FrostedBody> createState() => _FrostedBodyState();
}

class _FrostedBodyState extends State<FrostedBody> {
  _CachedBodyPainter? _painter;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    if (_painter == null || _painter!.radius != widget.radius || _painter!.ratio != ratio) {
      _painter?.dispose();
      _painter = _CachedBodyPainter(widget.radius, ratio);
    }
    return CustomPaint(painter: _painter, child: widget.child);
  }

  @override
  void dispose() {
    _painter?.dispose();
    super.dispose();
  }
}

class _CachedBodyPainter extends CustomPainter {
  _CachedBodyPainter(this.radius, this.ratio);
  final double? radius;
  final double ratio;
  ui.Image? _image;
  Size? _size;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_image == null || _size != size) {
      final recorder = ui.PictureRecorder();
      final recording = Canvas(recorder)..scale(ratio);
      _TintedBody(radius).paint(recording, size);
      final picture = recorder.endRecording();
      final image = picture.toImageSync((size.width * ratio).ceil(), (size.height * ratio).ceil());
      picture.dispose();
      _image?.dispose();
      _image = image;
      _size = size;
    }
    canvas.drawImageRect(
      _image!,
      Rect.fromLTWH(0, 0, size.width * ratio, size.height * ratio),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  void dispose() => _image?.dispose();

  @override
  bool shouldRepaint(_CachedBodyPainter oldDelegate) => radius != oldDelegate.radius || ratio != oldDelegate.ratio;
}

/// The milky wash, edge glow and lips drawn over each control's frosted blur.
class _TintedBody extends CustomPainter {
  const _TintedBody(this.radius);
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = bodyPath(rect, radius);
    // An even milky wash over the blur, a little lighter toward the bottom.
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33FFFFFF), Color(0x2BFFFFFF), Color(0x3DFFFFFF)],
          stops: [0, .5, 1],
        ).createShader(rect),
    );
    // The ColorOS glow: a soft light hugging every edge, shallow so the centre stays clear, and
    // weaker along the top. A blurred stroke clipped to the shape keeps it inside.
    canvas
      ..save()
      ..clipPath(shape)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x10FFFFFF), Color(0x2BFFFFFF), Color(0x3DFFFFFF)],
            stops: [0, .5, 1],
          ).createShader(rect),
      )
      ..restore();
    // A brighter glow right on the border, strongest along the bottom.
    canvas
      ..save()
      ..clipPath(shape)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Top a little softer, the sides softer still, the bottom brightest.
            colors: [Color(0x33FFFFFF), Color(0x26FFFFFF), Color(0x26FFFFFF), Color(0x6EFFFFFF)],
            stops: [0, .25, .75, 1],
          ).createShader(rect),
      )
      ..restore();
    // The 3D lip: clearer along the top edge, fainter along the bottom, and faded out toward the
    // sides so it doesn't wrap round the rounded ends.
    canvas
      ..saveLayer(rect, Paint())
      ..drawPath(
        bodyPath(rect.deflate(.5), radius == null ? null : radius! - .5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x3BFFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x1FFFFFFF)],
            stops: [0, .3, .7, 1],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = const LinearGradient(
            colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
            stops: [.12, .32, .68, .88],
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_TintedBody oldDelegate) => oldDelegate.radius != radius;
}

/// A circle, or a superellipse whose ends are ColorOS's soft oval rather than a true semicircle.
Path bodyPath(Rect rect, double? radius) => radius == null
    ? (Path()..addOval(rect))
    : (Path()..addRSuperellipse(RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius))));
