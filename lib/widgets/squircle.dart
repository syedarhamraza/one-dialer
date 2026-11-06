import 'package:flutter/painting.dart';

/// ColorOS 17's smooth "squircle" corners for rounded rectangles, while circles and
/// stadium pills (every corner at least half the short side) stay exactly round: a
/// superellipse there flattens the ends.
class SquircleBorder extends RoundedSuperellipseBorder {
  const SquircleBorder({super.side, super.borderRadius});

  /// True when every corner reaches half the short side, so the shape is a circle or a stadium.
  static bool isRound(BorderRadius r, Rect rect) {
    final half = rect.shortestSide / 2 - 0.5;
    return [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight].every((c) => c.x >= half && c.y >= half);
  }

  /// The outline of [r] over [rect]: a squircle, or a plain rounded rect when it's round.
  static Path pathFor(BorderRadius r, Rect rect) =>
      isRound(r, rect) ? (Path()..addRRect(r.toRRect(rect))) : (Path()..addRSuperellipse(r.toRSuperellipse(rect)));

  bool _round(Rect rect, TextDirection? d) => isRound(borderRadius.resolve(d), rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => pathFor(borderRadius.resolve(textDirection), rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _round(rect, textDirection)
      ? (Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(side.strokeInset)))
      : super.getInnerPath(rect, textDirection: textDirection);

  @override
  void paintInterior(Canvas canvas, Rect rect, Paint paint, {TextDirection? textDirection}) {
    if (_round(rect, textDirection)) {
      canvas.drawRRect(borderRadius.resolve(textDirection).toRRect(rect), paint);
    } else {
      super.paintInterior(canvas, rect, paint, textDirection: textDirection);
    }
  }

  @override
  ShapeBorder scale(double t) => SquircleBorder(side: side.scale(t), borderRadius: borderRadius * t);

  @override
  SquircleBorder copyWith({BorderSide? side, BorderRadiusGeometry? borderRadius}) =>
      SquircleBorder(side: side ?? this.side, borderRadius: borderRadius ?? this.borderRadius);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is SquircleBorder
      ? SquircleBorder(
          side: BorderSide.lerp(a.side, side, t),
          borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is SquircleBorder
      ? SquircleBorder(
          side: BorderSide.lerp(side, b.side, t),
          borderRadius: BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t),
        )
      : super.lerpTo(b, t);
}
