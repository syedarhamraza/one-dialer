import 'dart:convert';

import 'package:dialer/core/config/changelog.dart';
import 'package:dialer/features/updates/data/release_notes.dart';
import 'package:dialer/features/updates/data/update_service.dart';
import 'package:dialer/features/updates/presentation/update_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _PlayOffers extends NoopUpdateService {
  _PlayOffers(this.availableVersionCode);

  @override
  final int? availableVersionCode;

  @override
  Future<UpdateCheckResult> check() async => UpdateCheckResult.available;
}

void main() {
  test('the exported notes read back only for their own build', () {
    final entry = Changelog.entries[1];
    final json = jsonEncode(releaseNotesJson(entry, 8));
    final read = parseReleaseNotes(json, 8)!;
    expect(read.version, entry.version);
    expect(read.changes, entry.changes);
    expect(parseReleaseNotes(json, 9), isNull);
  });

  test("an update shows the website's notes for the offered build, never the installed ones", () async {
    final asked = <int>[];
    final controller = UpdateController(
      service: _PlayOffers(9),
      releaseNotes: (code) async {
        asked.add(code);
        return code == 9 ? const ChangelogEntry(version: '1.0.0-beta.6', date: 'Nov 2026', changes: ['New']) : null;
      },
    );
    await controller.check();
    await pumpEventQueue();
    expect(asked, [9]);
    expect(controller.updateNotes!.version, '1.0.0-beta.6');

    final none = UpdateController(service: _PlayOffers(10), releaseNotes: (_) async => null);
    await none.check();
    await pumpEventQueue();
    expect(none.updateNotes, isNull);
  });
}
