import 'dart:convert';
import 'dart:io';

import 'package:dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every language must be complete: adding one is an `app_xx.arb`, a `values-xx/strings.xml`
/// and a line in `locales_config.xml` (docs/localization.md).
void main() {
  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

  final template = arb('en');
  final keys = template.keys.where((k) => !k.startsWith('@')).toSet();
  final locales = [for (final l in AppLocalizations.supportedLocales) l.languageCode];

  for (final locale in locales.where((l) => l != 'en')) {
    test('$locale has every key and placeholder', () {
      final translation = arb(locale);
      expect(translation.keys.where((k) => !k.startsWith('@')).toSet(), keys);
      for (final key in keys) {
        final placeholders = (template['@$key'] as Map<String, dynamic>?)?['placeholders'] as Map<String, dynamic>?;
        for (final name in placeholders?.keys ?? const <String>[]) {
          expect(translation[key], contains('{$name'), reason: '$locale: $key lost {$name}');
        }
      }
    });

    test('$locale has the Android notification strings', () {
      expect(File('android/app/src/main/res/values-$locale/strings.xml').existsSync(), isTrue);
    });
  }

  test("Android's per-app language list matches the app's languages", () {
    final config = File('android/app/src/main/res/xml/locales_config.xml').readAsStringSync();
    final listed = RegExp(r'android:name="([\w-]+)"').allMatches(config).map((m) => m[1]).toSet();
    expect(listed, locales.toSet());
  });

  testWidgets('Italian resolves through the app delegates, with plurals', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Text(l10n.navCalls);
          },
        ),
      ),
    );
    expect(find.text('Chiamate'), findsOneWidget);
    expect(l10n.deleteCallsTitle(3), 'Eliminare 3 chiamate?');
    expect(l10n.deleteCallsTitle(1), 'Eliminare la chiamata?');
  });
}
