// Writes the translator templates in translations/ from the English text (TRANSLATING.md).
// Run after adding or changing English strings: dart run tool/l10n_template.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
  final template = <String, dynamic>{
    '@@locale': 'xx',
    for (final e in english.entries)
      if (!e.key.startsWith('@')) e.key: e.key == 'languageName' ? "Your language's name, written in your language" : e.value,
  };
  Directory('translations').createSync();
  File('translations/app_xx.arb').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(template)}\n');
  File('android/app/src/main/res/values/strings.xml').copySync('translations/strings_xx.xml');
}
