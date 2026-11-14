import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'cached_paint.dart';

/// The update / about artwork, in the app's greens: a deep green sky lit by a soft aurora, and
/// two sheets of silk made of fine threads of light, twisting through a bright fold as they
/// sweep up to the right. Rendered to an image once ([CachedPaint]), so page slides only draw
/// that image.
class CosArtwork extends StatelessWidget {
  const CosArtwork({super.key, this.fadeToBlack = 0, this.waveShift = 0, this.blur = 0, this.dim = 0});

  /// How much of the bottom fades into the black page (0 = none, .5 = the lower half).
  final double fadeToBlack;

  /// Moves the silk down by this share of the height, leaving sky for text.
  final double waveShift;

  /// Softens the whole artwork, behind text on the cards.
  final double blur;

  /// A black wash over the artwork (0 to 1), so text on it reads clearly.
  final double dim;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return CachedPaint(
      painter: _ArtworkPainter(fadeToBlack, waveShift, dim, palette.isLight, palette.page),
      blur: blur,
    );
  }
}

Paint _blur(Color color, double sigma) => Paint()
  ..color = color
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.fade, this.shift, this.dim, this.light, this.page);

  final double fade;
  final double shift;
  final double dim;

  /// Light mode: a pale mint sky, softer shadows, a white wash for [dim], fading into [page].
  final bool light;
  final Color page;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, rect = Offset.zero & size;
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: light
              ? const [Color(0xFFF3FBF6), Color(0xFFE2F4E9), Color(0xFFC9EAD7)]
              : const [Color(0xFF020C08), Color(0xFF05201A), Color(0xFF0A3426)],
          stops: const [0, .55, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.translate(0, h * shift);
    // Aurora behind the silk: green rising on the right, teal low on the left, a mint spark.
    final glow = light ? .55 : 1.0;
    canvas.drawCircle(Offset(w * .8, h * .6), w * .5, _blur(Color.fromRGBO(47, 174, 82, .34 * glow), w * .22));
    canvas.drawCircle(Offset(w * .1, h * .88), w * .42, _blur(Color.fromRGBO(14, 138, 122, .3 * glow), w * .2));
    canvas.drawCircle(Offset(w * .98, h * .36), w * .2, _blur(Color.fromRGBO(139, 240, 176, .22 * glow), w * .14));

    // Two sheets of silk crossing: the wide one sweeps up to the right, a fainter one answers it.
    _silk(canvas, w, h, const [.68, .98, .40, .80, .92, .46, .52, .10], 110, 1);
    _silk(canvas, w, h, const [.50, .66, .90, .70, .40, .66, .78, 1.00], 60, .45);
    canvas.restore();

    if (dim > 0) {
      canvas.drawRect(rect, Paint()..color = (light ? Colors.white : Colors.black).withValues(alpha: dim));
    }

    if (fade > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [page.withValues(alpha: 0), page.withValues(alpha: 0), page],
            stops: [0, 1 - fade, 1],
          ).createShader(rect),
      );
    }
  }

  /// A sheet of silk, drawn as [count] fine threads of light. [y] holds, as shares of the
  /// height, where the first and the last thread sit at the left edge, at the two control points
  /// and at the right edge; a pair that runs the other way twists the sheet, so the threads
  /// gather into a bright fold and fan out again. Sheen bands run across the threads.
  void _silk(Canvas canvas, double w, double h, List<double> y, int count, double strength) {
    // The thread's alpha goes into its colours: a modulate colour filter leaves the colour at
    // full strength under BlendMode.plus on Impeller, which burns the whole sheet out to white.
    ui.Gradient shader(double alpha) => ui.Gradient.linear(
      Offset.zero,
      Offset(w, 0),
      [
        for (final c
            in light
                ? const [Color(0x001E8A43), Color(0xFF2FAE52), Color(0xFF0E6E46), Color(0xFF2FAE52), Color(0x001E8A43)]
                : const [Color(0x002FAE52), Color(0xFF2FAE52), Color(0xFFD6FFE6), Color(0xFF4CC77C), Color(0x000E6E46)])
          c.withValues(alpha: c.a * alpha),
      ],
      const [0, .22, .56, .82, 1],
    );
    for (var i = 0; i < count; i++) {
      final u = i / (count - 1);
      // Each point moves across the sheet at its own pace, so the threads cross along a soft
      // fold instead of all meeting at one point.
      double at(int k) => h * (y[k] + (y[k + 1] - y[k]) * math.pow(u, const [1, 1.7, .6, 1.25][k ~/ 2]));
      final thread = Path()
        ..moveTo(-w * .1, at(0))
        ..cubicTo(w * .28, at(2), w * .58, at(4), w * 1.1, at(6));
      final sheen = .5 + .5 * math.sin(u * math.pi * 5 + 1);
      final alpha = strength * math.pow(math.sin(math.pi * u), .7) * (.12 + .88 * sheen * sheen);
      // Every sixth thread also lays a soft wide glow, the body of the sheet.
      if (i % 6 == 0) {
        canvas.drawPath(
          thread,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .03
            ..shader = shader(alpha * .16)
            ..blendMode = light ? BlendMode.srcOver : BlendMode.plus
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .018),
        );
      }
      canvas.drawPath(
        thread,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..shader = shader(alpha * .42)
          ..blendMode = light ? BlendMode.srcOver : BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(_ArtworkPainter old) => this != old;

  @override
  bool operator ==(Object other) =>
      other is _ArtworkPainter &&
      other.fade == fade &&
      other.shift == shift &&
      other.dim == dim &&
      other.light == light &&
      other.page == page;

  @override
  int get hashCode => Object.hash(fade, shift, dim, light, page);
}
