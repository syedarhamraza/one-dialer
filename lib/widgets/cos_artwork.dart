import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cached_paint.dart';

/// The update / about artwork, after ColorOS 17's, in polished glass and the app's greens: a
/// deep green sky, a glossy glass ribbon sweeping up to the right (crisp rim on its crest, a
/// shine along it, a soft shadow below) and a glass sphere resting on it (the ribbon refracted
/// inside, a rim bright at the top left, a soft inner edge light, a curved reflection, a contact
/// shadow). Rendered to an image once ([CachedPaint]), so page slides only draw that image.
class CosArtwork extends StatelessWidget {
  const CosArtwork({super.key, this.fadeToBlack = 0, this.waveShift = 0, this.blur = 0, this.dim = 0});

  /// How much of the bottom fades into the black page (0 = none, .5 = the lower half).
  final double fadeToBlack;

  /// Moves the ribbon and sphere down by this share of the height, leaving sky for text.
  final double waveShift;

  /// Softens the whole artwork, behind text on the cards.
  final double blur;

  /// A black wash over the artwork (0 to 1), so text on it reads clearly.
  final double dim;

  @override
  Widget build(BuildContext context) => CachedPaint(painter: _ArtworkPainter(fadeToBlack, waveShift, dim), blur: blur);
}

Paint _blur(Color color, double sigma) => Paint()
  ..color = color
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.fade, this.shift, this.dim);

  final double fade;
  final double shift;
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, rect = Offset.zero & size;
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020C08), Color(0xFF05201A), Color(0xFF0A3426)],
          stops: [0, .55, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.translate(0, h * shift);
    canvas.drawCircle(Offset(w * .6, h * .7), w * .7, _blur(const Color(0x442FAE52), 120));

    // The ribbon's crest, low left to high right, and the whole band.
    Path crest(double dy) => Path()
      ..moveTo(-w * .2, h * .86 + dy)
      ..cubicTo(w * .2, h * .70 + dy, w * .45, h * .80 + dy, w * .7, h * .62 + dy)
      ..cubicTo(w * .85, h * .52 + dy, w * 1.0, h * .46 + dy, w * 1.2, h * .48 + dy);
    final ribbon = crest(0)
      ..lineTo(w * 1.2, h * .66)
      ..cubicTo(w * 1.0, h * .64, w * .85, h * .72, w * .7, h * .82)
      ..cubicTo(w * .45, h * 1.0, w * .2, h * .92, -w * .2, h * 1.06)
      ..close();
    final waveRect = Rect.fromLTWH(0, h * .45, w, h * .6);

    // Soft shadow under the ribbon.
    canvas.save();
    canvas.translate(0, 16);
    canvas.drawPath(ribbon, _blur(const Color(0x8C000000), 22));
    canvas.restore();

    // The ribbon's glass: mint toward the crest, deeper green toward the underside.
    void ribbonBody(double brighten) => canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            for (final c in const [Color(0xF28BF0B0), Color(0xD92FAE52), Color(0xB30E6E46), Color(0x990A3A2C)])
              Color.lerp(c, Colors.white, brighten)!,
          ],
          stops: const [0, .3, .65, 1],
        ).createShader(waveRect),
    );
    ribbonBody(0);

    // Shine running along the ribbon, just below its crest.
    canvas.save();
    canvas.clipPath(ribbon);
    canvas.drawPath(
      crest(h * .035),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .035
        ..color = const Color(0x73FFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .01),
    );
    canvas.drawPath(
      crest(h * .02),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xCCFFFFFF),
    );
    canvas.restore();
    // Crisp rim along the crest.
    canvas.drawPath(
      crest(0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = const LinearGradient(colors: [Color(0x66FFFFFF), Color(0xF2FFFFFF), Color(0x99E8FFF0)])
            .createShader(waveRect),
    );

    // The sphere, resting on the ribbon.
    final c = Offset(w * .62, h * .6);
    final r = w * .3;
    final sphere = Rect.fromCircle(center: c, radius: r);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * .95), width: r * 1.6, height: r * .35),
      _blur(const Color(0x99000000), r * .14),
    );
    canvas.drawCircle(c, r * 1.15, _blur(const Color(0x332FAE52), r * .3));

    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));
    // Seen through the glass: lighter sky, the ribbon shifted and brighter.
    canvas.drawRect(sphere, Paint()..color = const Color(0x24FFFFFF));
    canvas.save();
    canvas.translate(-r * .14, -r * .12);
    ribbonBody(.22);
    canvas.restore();
    // Body: clear in the centre, the glass thickening (and lighter) toward the edge.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x00FFFFFF), Color(0x0AFFFFFF), Color(0x47E8FFF0)],
          stops: [0, .72, 1],
        ).createShader(sphere),
    );
    // A cooler shade low on the right, where the glass turns from the light.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.75, .8),
          radius: .8,
          colors: [Color(0x400B3D24), Color(0x000B3D24)],
        ).createShader(sphere),
    );
    // A slim curved reflection in the upper left.
    final reflect = Rect.fromCircle(center: c + Offset(r * .04, r * .06), radius: r * .86);
    canvas.drawArc(
      reflect,
      math.pi * 1.08,
      math.pi * .5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .07
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .025)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8CFFFFFF), Color(0x26FFFFFF), Color(0x00FFFFFF)],
        ).createShader(reflect),
    );
    canvas.restore();

    // Soft inner edge light, then the crisp rim: bright top left, a mint return bottom right.
    canvas.drawCircle(
      c,
      r - r * .04,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .08
        ..color = const Color(0x1FFFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .03),
    );
    canvas.drawCircle(
      c,
      r - .8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..shader = const SweepGradient(
          colors: [
            Color(0x80C8FFE0),
            Color(0x26FFFFFF),
            Color(0x33FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xB3FFFFFF),
            Color(0x80C8FFE0),
          ],
          stops: [0, .25, .5, .65, .8, 1],
        ).createShader(sphere),
    );
    canvas.drawCircle(c + Offset(-r * .52, -r * .55), r * .04, _blur(Colors.white, r * .025));
    canvas.restore();

    if (dim > 0) canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: dim));

    if (fade > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0x00000000), Color(0x00000000), Color(0xFF000000)],
            stops: [0, 1 - fade, 1],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_ArtworkPainter old) => old.fade != fade || old.shift != shift || old.dim != dim;

  @override
  bool operator ==(Object other) => other is _ArtworkPainter && other.fade == fade && other.shift == shift && other.dim == dim;

  @override
  int get hashCode => Object.hash(fade, shift, dim);
}
