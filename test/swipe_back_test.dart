import 'package:dialer/app/dialer_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pushPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
          pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: GroupedSlide()}),
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Center(child: Text('page'))),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
  }

  final middle = const Offset(400, 300); // test screen is 800 x 600

  testWidgets('a long drag from mid-screen pops the page', (tester) async {
    await pushPage(tester);
    await tester.timedDragFrom(middle, const Offset(500, 0), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsNothing);
  });

  testWidgets('a short slow drag snaps back', (tester) async {
    await pushPage(tester);
    await tester.timedDragFrom(middle, const Offset(150, 0), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('a leftward drag does nothing', (tester) async {
    await pushPage(tester);
    await tester.dragFrom(middle, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
  });
}
