import 'package:dialer/features/in_call/incoming_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<String>> pump(WidgetTester tester) async {
    final fired = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SwipeCircle(color: Colors.green, icon: Icons.call, label: 'Answer', onTriggered: () => fired.add('x')),
        ),
      ),
    );
    return fired;
  }

  testWidgets('a tap or short drag does not answer', (tester) async {
    final fired = await pump(tester);
    await tester.tap(find.byIcon(Icons.call));
    await tester.drag(find.byIcon(Icons.call), const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(fired, isEmpty);
  });

  testWidgets('dragging past the threshold answers once', (tester) async {
    final fired = await pump(tester);
    await tester.drag(find.byIcon(Icons.call), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(fired, ['x']);
  });

  testWidgets('the button stays fixed while the swipe arms and resets', (tester) async {
    await pump(tester);
    final icon = find.byIcon(Icons.call);
    final center = tester.getCenter(icon);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, -50));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(tester.getCenter(icon), center);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getCenter(icon), center);
  });

  testWidgets('nothing happens until the finger lifts, and sliding back cancels', (tester) async {
    final fired = await pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.call)));
    await gesture.moveBy(const Offset(0, -60));
    await gesture.moveBy(const Offset(0, -140)); // well past the threshold, still holding
    await tester.pump();
    expect(fired, isEmpty);

    await gesture.moveBy(const Offset(0, 170)); // back near the start
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fired, isEmpty);
  });

  testWidgets('screen readers can activate it', (tester) async {
    final fired = await pump(tester);
    final semantics = tester.ensureSemantics();
    tester.semantics.tap(find.semantics.byLabel('Answer'));
    expect(fired, ['x']);
    semantics.dispose();
  });
}
