import 'package:dialer/features/in_call/incoming_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  Rect? released;
  // The idle hint loops forever, so these tests pump fixed durations instead of settling.
  Future<List<String>> pump(WidgetTester tester, {bool oneButton = false}) async {
    final fired = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: SwipeUpButton(
            color: Colors.green,
            icon: Icons.call,
            label: 'Answer',
            onTriggered: (ball, _) {
              fired.add('answer');
              released = ball;
            },
            onSwipeDown: oneButton ? (_, _) => fired.add('decline') : null,
          ),
        ),
      ),
    );
    return fired;
  }

  Finder button() => find.byKey(const ValueKey('swipe-Answer'));
  Future<void> settle(WidgetTester tester) async {
    // The glass package's bouncy spring takes a little over a second to come to rest.
    for (var i = 0; i < 15; i++) {
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

  testWidgets('the ball only moves straight up and reports where it was let go', (tester) async {
    final fired = await pump(tester);
    final start = tester.getRect(button());
    final gesture = await tester.startGesture(start.center);
    await gesture.moveBy(const Offset(-20, -20));
    await gesture.moveBy(const Offset(-80, -100));
    await tester.pump();
    final held = tester.getRect(button());
    expect(held.center.dx, closeTo(start.center.dx, 1)); // Sideways is ignored.
    expect(held.center.dy, lessThan(start.center.dy - 80));
    await gesture.up();
    await settle(tester);
    expect(fired, ['answer']);
    expect(released!.center.dx, closeTo(held.center.dx, 1));
    expect(released!.center.dy, closeTo(held.center.dy, 1));
  });

  testWidgets('touching the ball grows it a little without acting', (tester) async {
    final fired = await pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(button()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<AnimatedScale>(find.ancestor(of: button(), matching: find.byType(AnimatedScale))).scale, 1.08);
    await gesture.up();
    await settle(tester);
    expect(tester.widget<AnimatedScale>(find.ancestor(of: button(), matching: find.byType(AnimatedScale))).scale, 1);
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

  testWidgets('1 button: up answers, down declines', (tester) async {
    var fired = await pump(tester, oneButton: true);
    await tester.drag(button(), const Offset(0, 160));
    await settle(tester);
    expect(fired, ['decline']);

    await tester.pumpWidget(const SizedBox()); // a fresh button
    fired = await pump(tester, oneButton: true);
    await tester.drag(button(), const Offset(0, 50)); // short: springs back
    await settle(tester);
    await tester.drag(button(), const Offset(0, -160));
    await settle(tester);
    expect(fired, ['answer']);
  });
}
