import 'package:dialer/app/dialer_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> push(WidgetTester tester, {required bool reduced}) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduced);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        theme: ThemeData(platform: TargetPlatform.android),
        builder: (context, child) => ReducedMotionPages(child: child!),
        home: const Text('home'),
      ),
    );
    key.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('page')));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Remove animations makes page pushes instant', (tester) async {
    await push(tester, reduced: true);
    expect(find.text('home'), findsNothing);
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('pages still animate normally', (tester) async {
    await push(tester, reduced: false);
    expect(find.text('home'), findsOneWidget); // Still covered mid-transition.
    await tester.pumpAndSettle();
    expect(find.text('home'), findsNothing);
  });
}
