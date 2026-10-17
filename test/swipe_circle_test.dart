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
          child: SwipeUpButton(
            color: Colors.green,
            icon: Icons.call,
            label: 'Answer',
            onTriggered: () => fired.add('answer'),
          ),
        ),
      ),
    );
    return fired;
  }

  Finder button() => find.byKey(const ValueKey('swipe-Answer'));
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a tap, sideways or short drag does nothing and springs back', (tester) async {
    final fired = await pump(tester);
    final start = tester.getCenter(button());
    await tester.tap(button());
    await tester.drag(button(), const Offset(0, -50));
    await tester.drag(button(), const Offset(0, 80)); // Downward never fires.
    await settle(tester);
    expect(fired, isEmpty);
    expect(tester.getCenter(button()), start);
  });

  testWidgets('sliding up past the threshold fires once', (tester) async {
    final fired = await pump(tester);
    await tester.drag(button(), const Offset(0, -160));
    await settle(tester);
    await tester.drag(button(), const Offset(0, -160));
    await settle(tester);
    expect(fired, ['answer']);
  });

  testWidgets('the button follows the finger and nothing fires until release', (tester) async {
    final fired = await pump(tester);
    final start = tester.getCenter(button());
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, -40));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(tester.getCenter(button()).dy, lessThan(start.dy - 80));
    expect(fired, isEmpty);
    await gesture.moveBy(const Offset(0, 130)); // back near the start
    await gesture.up();
    await settle(tester);
    expect(fired, isEmpty);
  });

  testWidgets('screen readers can activate it', (tester) async {
    final fired = await pump(tester);
    final semantics = tester.ensureSemantics();
    tester.semantics.tap(find.semantics.byLabel('Answer'));
    expect(fired, ['answer']);
    semantics.dispose();
  });

  testWidgets('cancelling a threshold swipe does not trigger or retain its distance', (tester) async {
    final fired = await pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(button()));
    await gesture.moveBy(const Offset(0, -50));
    await gesture.moveBy(const Offset(0, -160));
    await gesture.cancel();
    await settle(tester);
    await tester.drag(button(), const Offset(0, -30));
    await settle(tester);
    expect(fired, isEmpty);
  });
}
