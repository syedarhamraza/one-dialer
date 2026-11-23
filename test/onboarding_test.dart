import 'package:dialer/features/setup/onboarding_screen.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<String, Object?> health = {};

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.syedarhamraza.dialer/telecom'),
      (call) async => call.method == 'getCallHealth' ? health : null,
    );
    // permission_handler: 1 = granted.
    messenger.setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (_) async => 1);
  });

  Future<void> open(WidgetTester tester, VoidCallback onDone, {Locale? locale}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingScreen(onDone: onDone),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('walks through the three pages to Get started', (tester) async {
    health = {'notificationsEnabled': false, 'fullScreenAllowed': true};
    var done = 0;
    await open(tester, () => done++);
    expect(find.text('Make it yours'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Answering calls'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Ready for calls'), findsOneWidget);
    expect(find.text('Notifications are off'), findsOneWidget);
    expect(find.text('All set'), findsNothing);
    expect(done, 0);

    await tester.tap(find.text('Get started'));
    expect(done, 1);
  });

  testWidgets('health page says All set when nothing is missing', (tester) async {
    health = {'notificationsEnabled': true, 'fullScreenAllowed': true};
    await open(tester, () {});
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('All set'), findsOneWidget);
  });

  testWidgets('Skip finishes right away', (tester) async {
    var done = 0;
    await open(tester, () => done++);
    await tester.tap(find.text('Skip'));
    expect(done, 1);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final size in [const Size(360, 640), const Size(420, 933)]) {
      testWidgets('no overflow in ${locale.languageCode} at ${size.width.toInt()} dp', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        health = {};
        await open(tester, () {}, locale: locale);
        // Every page, with the health check's rows all showing (the longest one).
        for (var page = 0; page < 3; page++) {
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(PageView), Offset(-size.width, 0));
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
