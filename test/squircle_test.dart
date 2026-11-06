import 'package:dialer/widgets/squircle.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('circles and stadiums stay round', () {
    const r = BorderRadius.all(Radius.circular(24));
    expect(SquircleBorder.isRound(r, const Rect.fromLTWH(0, 0, 48, 48)), isTrue);
    expect(SquircleBorder.isRound(r, const Rect.fromLTWH(0, 0, 160, 48)), isTrue);
    expect(SquircleBorder.isRound(const BorderRadius.all(Radius.circular(999)), const Rect.fromLTWH(0, 0, 300, 68)), isTrue);
  });

  test('rounded rectangles become squircles', () {
    const r = BorderRadius.all(Radius.circular(26));
    expect(SquircleBorder.isRound(r, const Rect.fromLTWH(0, 0, 200, 100)), isFalse);
    // Only the top corners rounded (the keypad sheet).
    expect(
      SquircleBorder.isRound(const BorderRadius.vertical(top: Radius.circular(28)), const Rect.fromLTWH(0, 0, 400, 56)),
      isFalse,
    );
  });

  test('copies keep the round check', () {
    const b = SquircleBorder(borderRadius: BorderRadius.all(Radius.circular(26)));
    expect(b.scale(0.5), isA<SquircleBorder>());
    expect(b.copyWith(), isA<SquircleBorder>());
  });
}
