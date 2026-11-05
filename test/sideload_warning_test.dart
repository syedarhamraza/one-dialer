import 'package:dialer/app/sideload_warning.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  Future<void> launch(WidgetTester tester, String? installer, {bool release = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => warnIfSideloaded(context, release: release, installer: () async => installer),
            child: const Text('launch'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();
  }

  testWidgets('installed from Play: no warning', (tester) async {
    await launch(tester, 'com.android.vending');
    expect(find.text('Not from Google Play'), findsNothing);
  });

  testWidgets('debug and profile builds: no warning', (tester) async {
    await launch(tester, null, release: false);
    expect(find.text('Not from Google Play'), findsNothing);
  });

  testWidgets('sideloaded copy: warned once, never again', (tester) async {
    await launch(tester, null);
    expect(find.text('Not from Google Play'), findsOneWidget);
    await tester.tap(find.text('Keep using'));
    await tester.pumpAndSettle();
    expect(find.text('Not from Google Play'), findsNothing);

    await launch(tester, null);
    expect(find.text('Not from Google Play'), findsNothing);
  });
}
