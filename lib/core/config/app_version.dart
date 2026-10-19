import 'package:package_info_plus/package_info_plus.dart';

/// Release channel, from the pre-release part of the version name.
enum ReleaseChannel {
  alpha('Alpha'),
  beta('Beta'),
  release('');

  final String label;

  const ReleaseChannel(this.label);
}

/// The app version, as set in pubspec.yaml: `MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE`.
///
/// The name (`1.0.0-beta.2`) is what users see; the code (`5`) is the Android
/// versionCode and goes up by one with every Play upload. See `tool/release.ps1`.
class AppVersion {
  final int major;
  final int minor;
  final int patch;
  final ReleaseChannel channel;

  /// N in `-beta.N`; 0 for releases.
  final int preNumber;

  /// Android versionCode; null when unknown.
  final int? code;

  /// The version name exactly as built, e.g. `1.0.0-beta.2`.
  final String name;

  const AppVersion._({
    required this.name,
    required this.major,
    required this.minor,
    required this.patch,
    required this.channel,
    required this.preNumber,
    required this.code,
  });

  static final RegExp _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta)\.(\d+))?$');

  /// Parses a version name and optional build code. Returns null for names that don't
  /// follow the scheme.
  static AppVersion? tryParse(String name, [String? code]) {
    final match = _pattern.firstMatch(name.trim());
    if (match == null) return null;
    final pre = match.group(4);
    return AppVersion._(
      name: name.trim(),
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      channel: pre == null ? ReleaseChannel.release : ReleaseChannel.values.byName(pre),
      preNumber: match.group(5) == null ? 0 : int.parse(match.group(5)!),
      code: code == null ? null : int.tryParse(code.trim()),
    );
  }

  /// Reads the `"1.0.0-beta.2 (5)"` form stored in backup files.
  static AppVersion? tryParseStored(String stored) {
    final match = RegExp(r'^(\S+)(?:\s+\((\d+)\))?$').firstMatch(stored.trim());
    if (match == null) return null;
    return tryParse(match.group(1)!, match.group(2));
  }

  /// `1.0.0`
  String get number => '$major.$minor.$patch';

  bool get isPreRelease => channel != ReleaseChannel.release;

  /// `Beta 2`, or empty for releases.
  String get channelLabel => isPreRelease ? '${channel.label} $preNumber' : '';

  /// `1.0.0 Beta 2`, or `1.0.0` for releases.
  String get label => isPreRelease ? '$number $channelLabel' : number;

  /// `1.0.0 Beta 2 (build 5)`.
  String get full => code == null ? label : '$label (build $code)';

  /// How backups store the version: `1.0.0-beta.2 (5)`.
  String get stored => code == null ? name : '$name ($code)';

  static Future<AppVersion?>? _current;

  /// The running app's version (cached). Null if the platform can't say.
  static Future<AppVersion?> current() => _current ??= () async {
    try {
      final info = await PackageInfo.fromPlatform();
      return tryParse(info.version, info.buildNumber);
    } catch (_) {
      return null;
    }
  }();

  /// A label for any stored or reported version string, falling back to the raw text.
  static String describe(String raw) => tryParseStored(raw)?.label ?? raw;
}
