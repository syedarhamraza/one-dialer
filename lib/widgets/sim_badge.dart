import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// SIM slot number knocked out of a small grey SIM card, grey like the text beside it.
class SimBadge extends StatelessWidget {
  const SimBadge({super.key, required this.label, this.color, this.height = 16});

  final String label;

  /// Defaults to the theme's secondary text grey.
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(height * 23 / 24, height),
        painter: _SimBadgePainter(label: label, color: color ?? context.palette.textSecondary),
      ),
    );
  }
}

/// Drawn on a 23×24 grid. The number is cut out of the card, so it shows whatever is behind the
/// row (the page or a card).
class _SimBadgePainter extends CustomPainter {
  _SimBadgePainter({required this.label, required this.color});

  final String label;
  final Color color;

  static final _sim = Path()
    ..moveTo(5, 2.5)
    ..lineTo(14.2, 2.5)
    ..lineTo(19, 7.3)
    ..lineTo(19, 20)
    ..quadraticBezierTo(19, 21.5, 17.5, 21.5)
    ..lineTo(5, 21.5)
    ..quadraticBezierTo(3.5, 21.5, 3.5, 20)
    ..lineTo(3.5, 4)
    ..quadraticBezierTo(3.5, 2.5, 5, 2.5)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.height / 24);
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 23, 24), Paint());
    canvas.drawPath(_sim, Paint()..color = color);
    // A thin stroke of the same grey softens the cut corner like the other glyphs' rounding.
    canvas.drawPath(
      _sim,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round,
    );
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
          foreground: Paint()..blendMode = BlendMode.dstOut,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(11.25, 12.6) - Offset(text.width / 2, text.height / 2));
    text.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SimBadgePainter old) => old.label != label || old.color != color;
}
