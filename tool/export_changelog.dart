// Writes one release's notes as JSON for the website, which the app shows on Software update
// when Play offers that build. Run by tool/release.ps1:
//   dart run tool/export_changelog.dart <versionName> <versionCode> <outFile>
import 'dart:convert';
import 'dart:io';

import 'package:dialer/core/config/changelog.dart';
import 'package:dialer/features/updates/data/release_notes.dart';

void main(List<String> args) {
  if (args.length != 3 || int.tryParse(args[1]) == null) {
    stderr.writeln('Usage: dart run tool/export_changelog.dart <versionName> <versionCode> <outFile>');
    exit(64);
  }
  final entry = Changelog.entries.where((e) => e.version == args[0]).firstOrNull;
  if (entry == null) {
    stderr.writeln('No changelog entry for ${args[0]}.');
    exit(1);
  }
  final json = const JsonEncoder.withIndent('  ').convert(releaseNotesJson(entry, int.parse(args[1])));
  File(args[2])
    ..createSync(recursive: true)
    ..writeAsStringSync('$json\n');
  stdout.writeln('Wrote ${args[2]}');
}
