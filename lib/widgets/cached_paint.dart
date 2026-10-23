import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints [painter] into an image once per size (and again only when the painter changes),
/// then just draws that image, as [CallBodyArtwork] does for the call glass. Impeller has no
/// raster cache, so a painter full of blurs would otherwise be re-rendered on every frame of a
/// page slide. [blur] softens the whole image when it's made, at no per-frame cost.
class CachedPaint extends StatefulWidget {
  const CachedPaint({super.key, required this.painter, this.blur = 0, this.child});

  final CustomPainter painter;
  final double blur;
  final Widget? child;

  @override
  State<CachedPaint> createState() => _CachedPaintState();
}

class _CachedPaintState extends State<CachedPaint> {
  _ImagePainter? _cache;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final old = _cache;
    if (old == null || old.ratio != ratio || old.blur != widget.blur || widget.painter.shouldRepaint(old.painter)) {
      old?.dispose();
      _cache = _ImagePainter(widget.painter, ratio, widget.blur);
    }
    return CustomPaint(painter: _cache, size: Size.infinite, child: widget.child);
  }

  @override
  void dispose() {
    _cache?.dispose();
    super.dispose();
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.painter, this.ratio, this.blur);

  final CustomPainter painter;
  final double ratio;
  final double blur;
  ui.Image? _image;
  Size? _size;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_image == null || _size != size) {
      final recorder = ui.PictureRecorder();
      final recording = Canvas(recorder)..scale(ratio);
      if (blur > 0) {
        // Blurred edges would pull in transparency; clamp keeps them the artwork's colours.
        recording.saveLayer(
          null,
          Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp),
        );
      }
      painter.paint(recording, size);
      if (blur > 0) recording.restore();
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
  bool shouldRepaint(_ImagePainter old) => old.painter != painter || old.ratio != ratio || old.blur != blur;
}
