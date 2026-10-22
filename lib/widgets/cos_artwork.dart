import 'package:flutter/material.dart';

/// ColorOS 17's update/about artwork: a deep navy-to-violet sky, a warm orange-to-magenta
/// wave across it and a soft glass circle. Painted, so it's crisp at any size and costs no
/// blur or image decode.
class CosArtwork extends StatelessWidget {
  const CosArtwork({super.key});

  @override
  Widget build(BuildContext context) => const RepaintBoundary(child: CustomPaint(painter: _ArtworkPainter()));
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101A45), Color(0xFF2A2C7A), Color(0xFF4A2F86), Color(0xFF1B1238)],
          stops: [0, 0.35, 0.6, 1],
        ).createShader(rect),
    );

    // A pale band above the wave, as the light catching its crest.
    final glow = Path()
      ..moveTo(0, h * 0.40)
      ..cubicTo(w * 0.30, h * 0.30, w * 0.55, h * 0.56, w, h * 0.46)
      ..lineTo(w, h * 0.54)
      ..cubicTo(w * 0.55, h * 0.64, w * 0.30, h * 0.40, 0, h * 0.50)
      ..close();
    canvas.drawPath(
      glow,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFF9FB4FF).withValues(alpha: .55), const Color(0xFFE6B8FF).withValues(alpha: .25)],
        ).createShader(rect),
    );

    // The warm wave.
    final wave = Path()
      ..moveTo(0, h * 0.50)
      ..cubicTo(w * 0.30, h * 0.40, w * 0.55, h * 0.66, w, h * 0.54)
      ..lineTo(w, h * 0.72)
      ..cubicTo(w * 0.60, h * 0.84, w * 0.30, h * 0.60, 0, h * 0.70)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFF9A4D), Color(0xFFF2533C), Color(0xFFC23A7E)],
        ).createShader(rect),
    );

    // The glass circle, lit from the top left.
    final center = Offset(w * 0.74, h * 0.60);
    final radius = w * 0.30;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [Colors.white.withValues(alpha: .26), const Color(0xFF8C6CFF).withValues(alpha: .14)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .22),
    );
  }

  @override
  bool shouldRepaint(_ArtworkPainter oldDelegate) => false;
}
