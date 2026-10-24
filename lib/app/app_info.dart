/// Store-facing app details.
abstract final class AppInfo {
  static const name = 'One Dialer';

  /// Required by Google Play for apps using call-log and phone permissions. Must be live before release
  /// (source: `docs/privacy-policy.md`).
  static const privacyPolicyUrl = 'https://syedarhamraza.github.io/one-dialer/privacy/';

  static const developerName = 'Syed Arham Raza';
  static const developerGithub = 'syedarhamraza';

  /// Where Settings › Help & feedback › Send feedback mails to (not shown in the app).
  static const feedbackEmail = 'arhamraza399@gmail.com';
}
