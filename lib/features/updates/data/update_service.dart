import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:package_info_plus/package_info_plus.dart';

/// What Google Play says about updates for this install.
enum UpdateCheckResult {
  /// This is the newest version on the user's Play track.
  upToDate,

  /// A newer version can be installed now.
  available,

  /// An immediate update started earlier didn't finish (e.g. the app was closed); resume it.
  inProgress,

  /// A background (flexible) download is under way.
  downloading,

  /// A background download finished and is waiting to be installed.
  downloaded,

  /// Not installed from Google Play (a `flutter run` or sideloaded build), or Play is missing.
  notFromPlay,

  /// Play couldn't be reached.
  failed,
}

/// How an install attempt ended.
enum UpdateInstallResult { started, declined, failed }

/// Progress of a background (flexible) download, as Play reports it. The plugin gives no
/// byte counts, so the page shows an indeterminate state.
enum UpdateDownloadState { pending, downloading, downloaded, failed, canceled }

/// When One Dialer checks Google Play for updates on its own, at launch
/// (Software update › Auto download).
enum AutoUpdateCheck {
  never('Never'),
  wifiOnly('Using Wi-Fi only'),
  always('Using Wi-Fi or mobile data');

  final String label;

  const AutoUpdateCheck(this.label);
}

/// What network the phone is on: any at all (a check needs one), and whether it's
/// unmetered (for [AutoUpdateCheck.wifiOnly]).
abstract class NetworkStatus {
  Future<bool> isConnected();
  Future<bool> onUnmeteredNetwork();
}

/// Used in tests: always on Wi-Fi.
class AnyNetworkStatus implements NetworkStatus {
  const AnyNetworkStatus();

  @override
  Future<bool> isConnected() async => true;

  @override
  Future<bool> onUnmeteredNetwork() async => true;
}

/// Wi-Fi or ethernet counts as unmetered. If the plugin fails, assume connected (Play then
/// says whether it can be reached) but metered.
class ConnectivityNetworkStatus implements NetworkStatus {
  @override
  Future<bool> isConnected() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> onUnmeteredNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }
}

/// Platform boundary for Google Play in-app updates.
abstract class UpdateService {
  Future<UpdateCheckResult> check();

  /// Opens Play's full-screen updater. Only valid right after [check] returned
  /// [UpdateCheckResult.available] or [UpdateCheckResult.inProgress].
  Future<UpdateInstallResult> installNow();

  /// Asks Play to download the update in the background, after its small confirmation
  /// sheet. Completes once the download has finished, or when the user declines.
  /// Only valid right after [check] returned [UpdateCheckResult.available].
  Future<UpdateInstallResult> startDownload();

  /// Background download progress, while one runs.
  Stream<UpdateDownloadState> get downloadStates;

  /// Installs a finished background download. Play shows a brief screen and restarts the app.
  Future<bool> installDownloaded();
}

/// Used in tests and on platforms without Google Play.
class NoopUpdateService implements UpdateService {
  @override
  Future<UpdateCheckResult> check() async => UpdateCheckResult.notFromPlay;

  @override
  Future<UpdateInstallResult> installNow() async => UpdateInstallResult.failed;

  @override
  Future<UpdateInstallResult> startDownload() async => UpdateInstallResult.failed;

  @override
  Stream<UpdateDownloadState> get downloadStates => const Stream.empty();

  @override
  Future<bool> installDownloaded() async => false;
}

/// Google Play In-App Updates: a background (flexible) download when Play allows one, its
/// full-screen (immediate) updater otherwise. Needs a foreground activity, so call it after
/// the first frame, not during startup.
class PlayUpdateService implements UpdateService {
  /// Package name of the Play Store, the installer of every copy Play can update
  /// (Production, testing tracks and internal app sharing alike).
  static const playStoreInstaller = 'com.android.vending';

  // Play Core install error codes meaning "no Play to update from".
  static const _notFromPlayCodes = ['-10', '-9', '-3']; // app not owned, Play Store missing, API unavailable

  final bool _isAndroid;
  final Future<String?> Function() _installer;

  /// Whether the last [check] said Play allows a background download.
  bool _flexibleAllowed = true;

  PlayUpdateService({@visibleForTesting bool? isAndroid, @visibleForTesting Future<String?> Function()? installer})
    : _isAndroid = isAndroid ?? Platform.isAndroid,
      _installer = installer ?? _installerStore;

  static Future<String?> _installerStore() async {
    try {
      return (await PackageInfo.fromPlatform()).installerStore;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UpdateCheckResult> check() async {
    if (!_isAndroid) return UpdateCheckResult.notFromPlay;
    // Play answers "no update" for copies it didn't install (e.g. `flutter run`), so ask first.
    if (await _installer() != playStoreInstaller) return UpdateCheckResult.notFromPlay;
    try {
      final info = await play.InAppUpdate.checkForUpdate();
      _flexibleAllowed = info.flexibleUpdateAllowed;
      // A background download started earlier (maybe in a previous session) shows up here.
      switch (info.installStatus) {
        case play.InstallStatus.downloaded:
          return UpdateCheckResult.downloaded;
        case play.InstallStatus.pending || play.InstallStatus.downloading:
          return UpdateCheckResult.downloading;
        default:
          break;
      }
      switch (info.updateAvailability) {
        case play.UpdateAvailability.updateAvailable:
          return info.flexibleUpdateAllowed || info.immediateUpdateAllowed
              ? UpdateCheckResult.available
              : UpdateCheckResult.upToDate;
        case play.UpdateAvailability.developerTriggeredUpdateInProgress:
          return UpdateCheckResult.inProgress;
        case play.UpdateAvailability.updateNotAvailable:
          return UpdateCheckResult.upToDate;
        case play.UpdateAvailability.unknown:
          return UpdateCheckResult.failed;
      }
    } on MissingPluginException {
      return UpdateCheckResult.notFromPlay;
    } on PlatformException catch (e) {
      final message = e.message ?? '';
      if (_notFromPlayCodes.any((code) => message.contains('($code)') || message.startsWith('$code:'))) {
        return UpdateCheckResult.notFromPlay;
      }
      debugPrint('Update check failed: ${e.code} ${e.message}');
      return UpdateCheckResult.failed;
    } catch (e) {
      debugPrint('Update check failed: ${e.runtimeType}');
      return UpdateCheckResult.failed;
    }
  }

  @override
  Future<UpdateInstallResult> installNow() async {
    try {
      return switch (await play.InAppUpdate.performImmediateUpdate()) {
        play.AppUpdateResult.success => UpdateInstallResult.started,
        play.AppUpdateResult.userDeniedUpdate => UpdateInstallResult.declined,
        play.AppUpdateResult.inAppUpdateFailed => UpdateInstallResult.failed,
      };
    } catch (e, stack) {
      debugPrint('Update install failed: $e\n$stack');
      return UpdateInstallResult.failed;
    }
  }

  @override
  Future<UpdateInstallResult> startDownload() async {
    // Some updates (e.g. high priority ones) only allow Play's full-screen flow.
    if (!_flexibleAllowed) return installNow();
    try {
      return switch (await play.InAppUpdate.startFlexibleUpdate()) {
        play.AppUpdateResult.success => UpdateInstallResult.started,
        play.AppUpdateResult.userDeniedUpdate => UpdateInstallResult.declined,
        play.AppUpdateResult.inAppUpdateFailed => UpdateInstallResult.failed,
      };
    } catch (e, stack) {
      debugPrint('Update download failed: $e\n$stack');
      return UpdateInstallResult.failed;
    }
  }

  @override
  Stream<UpdateDownloadState> get downloadStates => play.InAppUpdate.installUpdateListener
      .map(
        (status) => switch (status) {
          play.InstallStatus.pending => UpdateDownloadState.pending,
          play.InstallStatus.downloading => UpdateDownloadState.downloading,
          play.InstallStatus.downloaded => UpdateDownloadState.downloaded,
          play.InstallStatus.failed => UpdateDownloadState.failed,
          play.InstallStatus.canceled => UpdateDownloadState.canceled,
          _ => null,
        },
      )
      .where((state) => state != null)
      .cast<UpdateDownloadState>();

  @override
  Future<bool> installDownloaded() async {
    try {
      await play.InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (e, stack) {
      debugPrint('Update install failed: $e\n$stack');
      return false;
    }
  }
}
