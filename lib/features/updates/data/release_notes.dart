import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';

import '../../../core/config/changelog.dart';

/// Play doesn't say what's in an update, so `tool/release.ps1` publishes each release's notes
/// here (via `tool/export_changelog.dart`).
const releaseNotesUrl = 'https://syedarhamraza.github.io/one-dialer/changelog.json';

/// The notes for build [code] from the website, or null when the site has another build's
/// notes or can't be reached.
Future<ChangelogEntry?> fetchReleaseNotes(int code) async {
  const timeout = Duration(seconds: 5);
  final client = HttpClient()..connectionTimeout = timeout;
  // Beta-only timing (docs/beta-only.md); Performance Monitoring can't see Dart's HttpClient itself.
  HttpMetric? metric;
  try {
    metric = FirebasePerformance.instance.newHttpMetric(releaseNotesUrl, HttpMethod.Get);
    await metric.start();
  } catch (_) {
    metric = null; // Firebase isn't set up (tests, builds without google-services.json)
  }
  try {
    final response = await (await client.getUrl(Uri.parse(releaseNotesUrl))).close().timeout(timeout);
    metric?.httpResponseCode = response.statusCode;
    if (response.statusCode != HttpStatus.ok) return null;
    return parseReleaseNotes(await response.transform(utf8.decoder).join().timeout(timeout), code);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
    unawaited(metric?.stop().catchError((_) {}));
  }
}

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
