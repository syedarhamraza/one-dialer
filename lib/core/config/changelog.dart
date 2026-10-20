/// Release notes shown on Settings › Software update › Changelog, newest first.
///
/// `tool/release.ps1` adds an entry for each new version name in pubspec.yaml; fill in
/// its changes before uploading. Notes can also be written ahead as an
/// [Changelog.inDevelopment] entry for the next version. A test checks that the newest
/// released entry matches pubspec.
/// Several uploads of the same name (`-Rebuild`) share one entry.
class ChangelogEntry {
  /// The version name from pubspec.yaml, e.g. `1.0.0-beta.1` (see [AppVersion]).
  final String version;

  /// Release date as shown to users (e.g. "Oct 2026"), or a status like "In development".
  final String date;
  final List<String> changes;

  const ChangelogEntry({required this.version, required this.date, required this.changes});
}

class Changelog {
  const Changelog._();

  /// Date of notes written ahead of their release. `tool/release.ps1` stamps the month
  /// when it releases that version, so entries spell it out as a quoted string.
  static const String inDevelopment = 'In development';

  static const List<ChangelogEntry> entries = [
    ChangelogEntry(
      version: '1.0.0-beta.1',
      date: 'In development',
      changes: [
        'One Dialer is now in open beta. Thank you for testing!',
        'A new look: frosted glass buttons, nav bar and menus, styled like the call screen',
        'Calls: All and Missed tabs, a big title and flat rows; tap a call to call back, ⓘ for details',
        'Buttons morph smoothly: All | Missed becomes Add to contact while you type, and Select all while selecting',
        'Menus pop open beside their button; slide your finger across and lift to pick',
        'Scrolling Calls tucks the keypad away, and it springs back up from the dialpad button',
        'Typed-number matches now look like your call list',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-alpha.1',
      date: 'Oct 2026',
      changes: [
        'One Dialer is now in closed testing on Google Play. Thank you for trying it!',
        'Keypad with contact search, speed dial and dual-SIM calling',
        'Calls and Contacts tabs, with swipe to call or message',
        'Full-screen incoming calls, and a call screen over your wallpaper',
        'Block numbers, hidden callers or everyone not in your contacts',
        'Quick decline messages',
        'Check for updates in Settings › Software update',
      ],
    ),
  ];
}

/// Build details passed in at build time (see tool/release.ps1). Empty in plain
/// `flutter run` builds.
class BuildInfo {
  const BuildInfo._();

  /// Short git commit the build was made from.
  static const String commit = String.fromEnvironment('GIT_SHA');
}
