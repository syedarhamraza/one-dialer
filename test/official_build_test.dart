import 'package:dialer/app/official_build.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('only our three signing certificates are official; an unknown hash never nags', () {
    for (final hash in officialCertHashes) {
      expect(isOfficialCert(hash), isTrue);
      expect(isOfficialCert(hash.toUpperCase()), isTrue);
    }
    expect(isOfficialCert(null), isTrue);
    expect(isOfficialCert(''), isTrue);
    expect(isOfficialCert('0' * 64), isFalse);
    expect(isOfficialCert('${officialCertHashes.first.substring(1)}0'), isFalse);
  });

  Future<void> launch(WidgetTester tester, bool official) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => noteIfUnofficial(context, official: () async => official),
            child: const Text('launch'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();
  }

  testWidgets('an official build shows no notice', (tester) async {
    await launch(tester, true);
    expect(find.text('Unofficial build'), findsNothing);
  });

  testWidgets('an unofficial build credits the original once, never again', (tester) async {
    await launch(tester, false);
    expect(find.text('Unofficial build'), findsOneWidget);
    expect(find.textContaining('Based on One Dialer by Syed Arham Raza'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await launch(tester, false);
    expect(find.text('Unofficial build'), findsNothing);
  });
}
