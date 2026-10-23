import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/app_info.dart';
import 'cached_paint.dart';

/// The app's version mark, over [CosArtwork]: the version ("1.0") in polished glass, then
/// "One Dialer" lit from above and the channel ("Beta 3") in mint, all centred. [size] is
/// the numeral's height; everything scales with it. Rendered to one image ([CachedPaint]),
/// so its blurs and glass edges cost nothing per frame.
class VersionMark extends StatelessWidget {
  const VersionMark({super.key, required this.version, this.channel, this.size = 140});

  final String version;
  final String? channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final height = _GlassTextPainter.glassHeight(size) + _GlassTextPainter.textHeight(size, channel != null);
    return Semantics(
      label: [AppInfo.name, version, ?channel].join(' '),
      // The image is larger than the layout by a margin on every side, so the glow and the
      // shadow fade out instead of stopping at the image's edge.
      child: SizedBox(
        width: size * 2.3,
        height: height,
        child: OverflowBox(
          maxWidth: size * 2.3 + _GlassTextPainter.margin(size) * 2,
          maxHeight: height + _GlassTextPainter.margin(size) * 2,
          child: CachedPaint(painter: _GlassTextPainter(version, channel, size)),
        ),
      ),
    );
  }
}

/// Glass letters: the glyphs are drawn once, then the glass is painted inside them (srcIn), so
/// the frosted body, the glossy streak and the edge light stay within the letters. A soft drop
/// shadow and a green glow sit behind.
class _GlassTextPainter extends CustomPainter {
  _GlassTextPainter(this.text, this.channel, this.size);

  final String text;
  final String? channel;
  final double size;

  /// The numeral's area, with room for its glow.
  static double glassHeight(double size) => size * 1.15;

  /// The name and the channel under it.
  static double textHeight(double size, bool channel) => size * (.04 + .23 * 1.25 + (channel ? .23 * .56 * 1.3 : 0));

  TextPainter _layout(Paint? stroke) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        // A bundled font: system fonts differ by phone, and some draw bold digits from
        // overlapping contours that the glass rim would trace twice.
        fontFamily: 'GlassNumeral',
        fontSize: size,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -size * .015,
        color: stroke == null ? Colors.white : null,
        foreground: stroke,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size box) {
    final m = margin(size);
    canvas.translate(m, m);
    final inner = Size(box.width - m * 2, box.height - m * 2);
    _paintGlass(canvas, Size(inner.width, glassHeight(size)));
    _paintName(canvas, inner);
  }

  /// Room around the mark for its glow (blurred about .19 × [size]) to fade out fully.
  static double margin(double size) => size * .7;

  /// "One Dialer" lit from above with a soft green glow, and the channel in mint, centred
  /// under the numeral.
  void _paintName(Canvas canvas, Size box) {
    final nameSize = size * .23;
    final name = TextPainter(
      text: TextSpan(
        text: AppInfo.name,
        style: TextStyle(
          fontSize: nameSize,
          fontWeight: FontWeight.w500,
          letterSpacing: -nameSize * .02,
          foreground: Paint()
            ..shader = ui.Gradient.linear(Offset.zero, Offset(0, nameSize * 1.2), const [
              Colors.white,
              Color(0xFFCFF7DD),
            ]),
          shadows: const [Shadow(color: Color(0x662FAE52), blurRadius: 18)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var y = glassHeight(size) + size * .04;
    canvas.save();
    canvas.translate((box.width - name.width) / 2, y);
    name.paint(canvas, Offset.zero);
    canvas.restore();
    y += name.height;
    if (channel case final channel?) {
      final tag = TextPainter(
        text: TextSpan(
          text: channel,
          style: TextStyle(fontSize: nameSize * .56, fontWeight: FontWeight.w400, color: const Color(0xFF8BF0B0)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tag.paint(canvas, Offset((box.width - tag.width) / 2, y));
    }
  }

  void _paintGlass(Canvas canvas, Size box) {
    final glyphs = _layout(null);
    final at = Offset((box.width - glyphs.width) / 2, (box.height - glyphs.height) / 2);
    final r = at & glyphs.size;

    // A glyph-shaped layer of one colour, blurred: the shadow and the glow.
    void halo(double sigma, Offset offset, Color color) {
      canvas.saveLayer(null, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
      glyphs.paint(canvas, at + offset);
      canvas.drawRect(
        r.inflate(sigma * 4),
        Paint()
          ..color = color
          ..blendMode = BlendMode.srcIn,
      );
      canvas.restore();
    }

    halo(size * .1, Offset(0, size * .07), const Color(0x8C000000));
    halo(size * .19, Offset.zero, const Color(0x732FAE52));

    // A layer the shape of the glyphs, then [paint] drawn inside it.
    void inside(void Function() paint) {
      canvas.saveLayer(r.inflate(4), Paint());
      glyphs.paint(canvas, at);
      canvas.saveLayer(r.inflate(4), Paint()..blendMode = BlendMode.srcIn);
      paint();
      canvas.restore();
      canvas.restore();
    }

    // Frosted body: bright at the top, clearer in the middle, catching light at the bottom.
    inside(
      () => canvas.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x9EFFFFFF), Color(0x47E8FFF0), Color(0x2E8BF0B0), Color(0x7A8BF0B0)],
            stops: [0, .4, .72, 1],
          ).createShader(r),
      ),
    );
    // Glossy streak sloping across the upper part, with a crisp line along its top.
    inside(() {
      canvas.translate(r.center.dx, r.top + r.height * .3);
      canvas.rotate(-.14);
      final band = Rect.fromLTWH(-r.width * .8, 0, r.width * 1.6, r.height * .22);
      canvas.drawRect(
        band,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xE6FFFFFF), Color(0x80FFFFFF), Color(0x1AFFFFFF), Color(0x00FFFFFF)],
            stops: [0, .18, .6, 1],
          ).createShader(band),
      );
      canvas.drawRect(
        Rect.fromLTWH(band.left, -r.height * .012, band.width, r.height * .018),
        Paint()
          ..color = Colors.white
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.height * .004),
      );
    });
    // A cooler shade low on the right, where the glass turns from the light.
    inside(
      () => canvas.drawRect(
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(.9, 1),
            radius: .9,
            colors: [Color(0x330B3D24), Color(0x000B3D24)],
          ).createShader(r),
      ),
    );

    // Edge light: a wide soft inner edge (kept inside the letters) and a crisp rim, bright at
    // the top left with a mint return at the bottom right.
    for (final (width, colors, inner) in [
      (size * .05, const [Color(0x47FFFFFF), Color(0x08FFFFFF), Color(0x338BF0B0)], true),
      (size * .012, const [Color(0xFFFFFFFF), Color(0x66FFFFFF), Color(0x1AFFFFFF), Color(0xCCC8FFE0)], false),
    ]) {
      canvas.saveLayer(r.inflate(width), Paint());
      _layout(
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = Colors.white,
      ).paint(canvas, at);
      canvas.drawRect(
        r.inflate(width),
        Paint()
          ..blendMode = BlendMode.srcIn
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
            stops: colors.length == 4 ? const [0, .3, .65, 1] : null,
          ).createShader(r),
      );
      if (inner) {
        canvas.saveLayer(r.inflate(width), Paint()..blendMode = BlendMode.dstIn);
        glyphs.paint(canvas, at);
        canvas.restore();
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlassTextPainter old) => old.text != text || old.channel != channel || old.size != size;

  @override
  bool operator ==(Object other) =>
      other is _GlassTextPainter && other.text == text && other.channel == channel && other.size == size;

  @override
  int get hashCode => Object.hash(text, channel, size);
}
