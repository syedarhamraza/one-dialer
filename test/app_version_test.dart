import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/core/config/app_version.dart';
import 'package:dialer/core/config/changelog.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('a release', () {
      final v = AppVersion.tryParse('1.2.3', '42')!;
      expect((v.major, v.minor, v.patch), (1, 2, 3));
      expect(v.channel, ReleaseChannel.release);
      expect(v.isPreRelease, isFalse);
      expect(v.label, '1.2.3');
      expect(v.full, '1.2.3 (build 42)');
      expect(v.stored, '1.2.3 (42)');
    });

    test('alpha and beta pre-releases', () {
      final alpha = AppVersion.tryParse('2.0.0-alpha.3')!;
      expect(alpha.channel, ReleaseChannel.alpha);
      expect(alpha.label, '2.0.0 Alpha 3');
      expect(alpha.code, isNull);

      final beta = AppVersion.tryParse('1.0.0-beta.2', '5')!;
      expect(beta.channelLabel, 'Beta 2');
      expect(beta.full, '1.0.0 Beta 2 (build 5)');
    });

    test('names outside the scheme are rejected', () {
      expect(AppVersion.tryParse('1.0'), isNull);
      expect(AppVersion.tryParse('1.0.0-rc.1'), isNull);
      expect(AppVersion.tryParse('1.0.0-beta'), isNull);
    });
  });

  test('stored versions from backups are described, old ones included', () {
    expect(AppVersion.describe('1.0.0-beta.1 (1)'), '1.0.0 Beta 1');
    expect(AppVersion.describe('1.0.0 (151)'), '1.0.0');
    expect(AppVersion.describe('something else'), 'something else');
  });

  group('pubspec.yaml', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final parts = line.substring('version:'.length).trim().split('+');

    test('follows MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE', () {
      expect(parts, hasLength(2), reason: 'pubspec version needs a +CODE');
      expect(AppVersion.tryParse(parts[0]), isNotNull, reason: '"${parts[0]}" is not a valid version name');
      expect(int.parse(parts[1]), greaterThanOrEqualTo(1));
    });

    test('Changelog has notes for the current version', () {
      // Notes for the next versions may be written ahead, "In development", above it.
      final entries = Changelog.entries;
      final ahead = entries.takeWhile((e) => e.date == Changelog.inDevelopment && e.version != parts[0]).length;
      expect(
        entries[ahead].version,
        parts[0],
        reason: 'Add a ChangelogEntry for ${parts[0]} at the top of lib/core/config/changelog.dart',
      );
    });

    test('notes written ahead name a valid version', () {
      final first = Changelog.entries.first;
      expect(AppVersion.tryParse(first.version), isNotNull, reason: '"${first.version}" is not a valid version name');
    });
  });
}
