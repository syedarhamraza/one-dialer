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
  /// when it releases that version (as `date: Changelog.inDevelopment` or the quoted string).
  static const String inDevelopment = 'In development';

  static const List<ChangelogEntry> entries = [
    ChangelogEntry(
      version: '1.0.0-beta.7',
      date: Changelog.inDevelopment,
      changes: [
        'New glossy Phone and Contacts icons. Prefer the old ones? Settings › App icon › Classic',
        'After updating, add the Phone icon to your home screen again from the app drawer',
        'Liquid glass: turn it on in Settings › Display & effects › Glass & blur, for the nav bar alone or for buttons and menus too',
        'A new ColorOS-style green Call button with our own handset, on the keypad, the call screen and every green button',
        'Dual SIM: each Call button shows its SIM number in the corner of the handset',
        'Settings is grouped by topic, with pictures that preview display and dialing choices',
        'Conference calls: Merge appears whenever two calls can be joined, and the merged call shows as one call',
        'Call screen edge glow: Classic, Soft or Bold, in Settings › Answer buttons',
        'Return to call shows a handset with sound waves, and always sits beside the nav bar',
        'Contact pages get cleaner rows with thin icons, the ringtone\'s name and a two-line call log',
        'Keypad: tap and hold the number to copy or paste, and numbers typed with 00 find your saved contacts',
        'Light mode: clearer see-through glass and new ColorOS 17 alerts',
        'Add call during a call opens the keypad',
        'The call screen shows the caller\'s photo right away and opens faster',
        'Fixed four crashes reported from earlier betas',
        'A copy that wasn\'t installed from Google Play now says so once, since it won\'t get updates',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-beta.6',
      date: 'Nov 2026',
      changes: [
        'New ColorOS 17 incoming call ball: drag it to answer or decline, and it springs into End',
        'Settings › Incoming call reminders, Answer/End calls and Answer buttons pages, with Answer call direction and Announce incoming calls',
        'Active call buttons get the Answer ball\'s glass finish',
        'Return to call opens the call screen and sits beside the nav bar',
        'Phones with 4 GB of RAM start with reduced visual and call screen effects',
        'Fixed the Calls list freezing with a long call history when Hide blocked calls is on',
        'Fixed a crash when a call ends just as you tap a call button',
        'Fixed rare crashes when opening the app, from a phone link, or in a cloned copy of the app',
        'The app sends anonymous usage statistics (Firebase Analytics, no advertising ID) to help improve it',
        'Performance reports now show how smooth each tap and tab switch was, and can tell when the screen stops responding to touches',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-beta.5',
      date: 'Oct 2026',
      changes: [
        'Light mode gets the ColorOS 17 glass look, with soft shadows under buttons and bars',
        'Calls from other calling apps show in Calls on Android 16.1 and later',
        'The back swipe previews the page behind on every screen',
        'Settings › Reduce visual effects: full, reduced or off (no blur), for phones that lag or freeze',
        'Settings › Call screen effects: the same choice for the call screen',
        'Severe slowdowns can now send limited performance diagnostics to help improve responsiveness',
        'Settings › Help & feedback › Report lag lets you send recent diagnostics and copy a report ID',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-beta.4',
      date: 'Oct 2026',
      changes: [
        'Block & filter and the contact picker can now be searched',
        'Adding a contact whose number or name is already saved (also from a QR code) asks first',
        'Merging duplicate contacts asks first',
        'Swipe to call or message on Calls and Contacts rows is removed: tap the row or its info button',
        'Call history asks before deleting and updates immediately; private blocked-call entries can also be deleted',
        'Hide blocked calls now also hides older calls from numbers on your block list',
        'Dual SIM: Settings › Tap a recent call can be set to Choose SIM and call',
        'Contacts ⋮ › Manage contacts: profile pictures, contacts without numbers, accounts to display, sort and name format, default save location, import and export .vcf, SIM card contacts and merging duplicates',
        'Updated the keypad Add to Contacts menu and removed keypad menu icons',
        'Contact QR codes include all phone numbers in a camera-friendly format',
        'Adding a contact from a scanned QR code or another app now keeps all its numbers',
        'New green frosted-glass icons for Phone and Contacts, with matching notification icons',
        'A polished call screen: its own colourful backdrop, bigger menus, glassy buttons and a smoother Answer animation',
        'Call notes can be deleted and show under the number in Calls',
        'The call audio menu names each Bluetooth device',
        'Incoming calls appear faster; answering opens the call screen, with one "Call ended"',
        'Missed-call notifications show the time, stay dismissed, and clear when you open the app',
        'Typed digits sit above the keypad, and long numbers shrink to fit',
        'Settings › Help & feedback',
        'Back uses Android\'s predictive back gesture',
        'Pages bounce gently at their ends, and the contact QR code has a new look',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-beta.3',
      date: 'Oct 2026',
      changes: [
        'Much smoother menus, contact pages and keypad, especially on Samsung Galaxy and other Snapdragon phones',
        'Tapping a recent call now opens its details instead of calling. Prefer the old way? Settings › Tap a recent call › Write in keypad',
        'Dual SIM: two Call buttons on the keypad, or choose the SIM each time (Settings › Choose SIM for calls)',
        'A new contact page: Call, Message and Video (Google Meet) buttons, WhatsApp, SIM card for calls and where the contact is saved',
        'A new contact editor: choose where to save (phone, SIM or Google account)',
        'New contact now slides up from the bottom, like the keypad',
        'Alerts and menus now match the frosted glass look of the rest of the app',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-beta.2',
      date: 'Oct 2026',
      changes: [
        'Contacts redesigned: favourites under a star, My contact card and My groups, an A–Z index, and tap to open a contact',
        'A new contact page: big photo, Call and Message buttons, all numbers, ringtone and your recent calls with this contact',
        'A new contact editor: Cancel and Done at the top, pick where to save, and Show more for extra fields',
        'The keypad is now frosted glass, with glass keys that match the rest of the app',
        'The app now looks the same on every phone, scaling to your screen size',
        'Smoother switching between Calls and Contacts',
        'Fixed menus opening in the wrong place on smaller phones',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0-beta.1',
      date: 'Oct 2026',
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
