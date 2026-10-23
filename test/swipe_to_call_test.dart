import 'package:dialer/widgets/swipe_to_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final actions = <String>[];
  setUp(() {
    actions.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.syedarhamraza.dialer/telecom'),
      (call) async {
        if (call.method == 'sendSms' || call.method == 'placeCall') actions.add(call.method);
        return null;
      },
    );
  });
  Future<void> open(WidgetTester tester, {bool enabled = true}) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            SwipeToCallOrMessage(
              number: '123',
              enabled: enabled,
              child: const SizedBox(height: 80, child: Text('row')),
            ),
            const SizedBox(height: 1500),
          ],
        ),
      ),
    ),
  );
  testWidgets('short high velocity flick does not message', (tester) async {
    await open(tester);
    await tester.fling(find.text('row'), const Offset(-100, 0), 3000);
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
  });
  testWidgets('vertical and diagonal scrolling never acts', (tester) async {
    for (final delta in [const Offset(0, -300), const Offset(-450, -350)]) {
      await open(tester);
      await tester.drag(find.text('row'), delta);
      await tester.pumpAndSettle();
      expect(actions, isEmpty);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('deliberate half-width swipe acts once on release', (tester) async {
    await open(tester);
    final gesture = await tester.startGesture(const Offset(700, 40));
    await gesture.moveBy(const Offset(-450, 0));
    await tester.pump();
    expect(actions, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(actions, ['sendSms']);
  });
  testWidgets('cancelled gestures and selection do not act', (tester) async {
    await open(tester);
    final gesture = await tester.startGesture(const Offset(700, 40));
    await gesture.moveBy(const Offset(-450, 0));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    await open(tester, enabled: false);
    await tester.drag(find.text('row'), const Offset(-450, 0));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
  });
}
