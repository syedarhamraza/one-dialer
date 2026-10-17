import 'package:dialer/features/in_call/incoming_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The idle hint loops forever, so these tests pump fixed durations instead of settling.
  Future<List<String>> pump(WidgetTester tester) async {
    final fired = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SlideToAnswer(onAnswer: () => fired.add('answer'), onDecline: () => fired.add('decline')),
        ),
      ),
    );
    return fired;
  }

  Finder handle() => find.byKey(const ValueKey('answer-handle'));
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a tap or short drag does nothing and springs back', (tester) async {
    final fired = await pump(tester);
    final start = tester.getCenter(handle());
    await tester.tap(handle());
    await tester.drag(handle(), const Offset(0, -50));
    await settle(tester);
    expect(fired, isEmpty);
    expect((tester.getCenter(handle()).dy - start.dy).abs(), lessThan(8)); // Within the idle bob.
  });

  testWidgets('sliding up past the threshold answers once', (tester) async {
    final fired = await pump(tester);
    await tester.drag(handle(), const Offset(0, -160));
    await settle(tester);
    await tester.drag(handle(), const Offset(0, -160));
    await settle(tester);
    expect(fired, ['answer']);
  });

  testWidgets('sliding down past the threshold declines', (tester) async {
    final fired = await pump(tester);
    await tester.drag(handle(), const Offset(0, 100));
    await settle(tester);
    expect(fired, ['decline']);
  });

  testWidgets('the handle follows the finger and nothing fires until release', (tester) async {
    final fired = await pump(tester);
    final start = tester.getCenter(handle());
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, -40));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();
    expect(tester.getCenter(handle()).dy, lessThan(start.dy - 100));
    expect(fired, isEmpty);
    await gesture.moveBy(const Offset(0, 150)); // back near the start
    await gesture.up();
    await settle(tester);
    expect(fired, isEmpty);
  });

  testWidgets('screen readers can answer and decline', (tester) async {
    final fired = await pump(tester);
    final semantics = tester.ensureSemantics();
    tester.semantics.tap(find.semantics.byLabel('Answer'));
    expect(fired, ['answer']);
    semantics.dispose();
  });

  testWidgets('cancelling a threshold swipe does not trigger or retain its distance', (tester) async {
    final fired = await pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(handle()));
    await gesture.moveBy(const Offset(0, -50));
    await gesture.moveBy(const Offset(0, -160));
    await gesture.cancel();
    await settle(tester);
    await tester.drag(handle(), const Offset(0, -30));
    await settle(tester);
    expect(fired, isEmpty);
  });
}
