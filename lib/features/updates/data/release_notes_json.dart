import 'dart:convert';

import '../../../core/config/changelog.dart';

// No Flutter or Firebase imports: tool/export_changelog.dart runs this under plain `dart run`.

/// Reads `changelog.json` ({version, code, date, changes}); null unless it's build [code]'s.
ChangelogEntry? parseReleaseNotes(String json, int code) {
  if (jsonDecode(json) case {'version': String version, 'code': int c, 'date': String date, 'changes': List changes}
      when c == code) {
    return ChangelogEntry(version: version, date: date, changes: changes.whereType<String>().toList());
  }
  return null;
}

/// What `tool/export_changelog.dart` writes for [entry], built as [code].
Map<String, Object> releaseNotesJson(ChangelogEntry entry, int code) => {
  'version': entry.version,
  'code': code,
  'date': entry.date,
  'changes': entry.changes,
};
