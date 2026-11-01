import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';

import '../../../core/config/changelog.dart';
import 'release_notes_json.dart';

export 'release_notes_json.dart';

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
