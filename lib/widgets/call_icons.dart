import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The call screen's thin-line glyphs (ColorOS 17's look, drawn from simple shapes, not traced).
enum CallIconShape { mute, record, notes, more, speaker, bluetooth, headset, hold, addCall, video }

/// Draws [shape] like an [Icon]: sized and coloured by [IconTheme] unless given.
class CallIcon extends StatelessWidget {
  const CallIcon(this.shape, {super.key, this.color, this.size});
  final CallIconShape shape;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return CustomPaint(
      size: Size.square(size ?? theme.size ?? 24),
      painter: _CallIconPainter(shape, color ?? theme.color ?? Colors.white),
    );
  }
}

class _CallIconPainter extends CustomPainter {
  const _CallIconPainter(this.shape, this.color);
  final CallIconShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 24-unit grid, like Material's icons.
    canvas.scale(size.width / 24);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void bar(double x, double y1, double y2) => canvas.drawLine(Offset(x, y1), Offset(x, y2), line);
    switch (shape) {
      case CallIconShape.mute:
        canvas.drawRRect(RRect.fromLTRBR(9, 3, 15, 14.5, const Radius.circular(3)), line);
        canvas.drawArc(Rect.fromCircle(center: const Offset(12, 11), radius: 6), 0, math.pi, false, line);
        bar(12, 17, 20.5);
        canvas.drawLine(const Offset(4.5, 4.5), const Offset(19.5, 19.5), line);
      case CallIconShape.record:
        const heights = [3.0, 8, 12, 17, 11, 7, 3];
        for (var i = 0; i < heights.length; i++) {
          bar(3 + i * 3.0, 12 - heights[i] / 2, 12 + heights[i] / 2);
        }
      case CallIconShape.notes:
        // The sheet with its lines cut out (even-odd), so no save layer is needed.
        final sheet = Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(RRect.fromLTRBR(5, 3, 19, 21, const Radius.circular(2.5)));
        for (final (y, right) in [(8.0, 15.5), (11.75, 15.5), (15.5, 12.5)]) {
          sheet.addRRect(RRect.fromLTRBR(8.5, y - .8, right, y + .8, const Radius.circular(.8)));
        }
        canvas.drawPath(sheet, fill);
      case CallIconShape.more:
        for (final y in [5.5, 12.0, 18.5]) {
          canvas.drawCircle(Offset(12, y), 1.9, fill);
        }
      case CallIconShape.speaker:
        final cone = Path()
          ..moveTo(3.5, 9.5)
          ..lineTo(7.5, 9.5)
          ..lineTo(12, 5)
          ..lineTo(12, 19)
          ..lineTo(7.5, 14.5)
          ..lineTo(3.5, 14.5)
          ..close();
        canvas.drawPath(cone, fill);
        canvas.drawPath(cone, line..strokeWidth = 1.2);
        line.strokeWidth = 1.45;
        for (final r in [3.5, 7.0]) {
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(13, 12), radius: r),
            -math.pi / 4,
            math.pi / 2,
            false,
            line,
          );
        }
      case CallIconShape.bluetooth:
        final rune = Path()
          ..moveTo(6.5, 7.5)
          ..lineTo(17, 16.5)
          ..lineTo(11.5, 21)
          ..lineTo(11.5, 3)
          ..lineTo(17, 7.5)
          ..lineTo(6.5, 16.5);
        canvas.drawPath(rune, line);
      case CallIconShape.headset:
        canvas.drawArc(Rect.fromCircle(center: const Offset(12, 13), radius: 8), math.pi, math.pi, false, line);
        for (final left in [3.0, 15.5]) {
          canvas.drawRRect(RRect.fromLTRBR(left, 12.5, left + 5.5, 20.5, const Radius.circular(2)), fill);
        }
      case CallIconShape.hold:
        // Solid bars as tall as the other glyphs; a stroke this long reads thinner than the row's shapes.
        for (final left in [7.2, 14.0]) {
          canvas.drawRRect(RRect.fromLTRBR(left, 4.5, left + 2.8, 19.5, const Radius.circular(1.4)), fill);
        }
      case CallIconShape.addCall:
        bar(12, 5, 19);
        canvas.drawLine(const Offset(5, 12), const Offset(19, 12), line);
      case CallIconShape.video:
        canvas.drawRRect(RRect.fromLTRBR(2.5, 6.5, 15, 17.5, const Radius.circular(2.5)), fill);
        final lens = Path()
          ..moveTo(16.5, 10.5)
          ..lineTo(21.5, 7.5)
          ..lineTo(21.5, 16.5)
          ..lineTo(16.5, 13.5)
          ..close();
        canvas.drawPath(lens, fill);
        canvas.drawPath(lens, line..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_CallIconPainter old) => old.shape != shape || old.color != color;
}
