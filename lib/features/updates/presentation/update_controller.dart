import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/prefs/dialer_prefs.dart';
import '../data/update_service.dart';

/// State of Settings › Software update.
enum UpdateStatus {
  notChecked,
  checking,
  upToDate,
  available,

  /// Play is downloading the update in the background; the app stays usable.
  downloading,

  /// The download finished; "Install and restart" finishes the update.
  readyToInstall,
  notFromPlay,

  /// There's no network connection, so Play wasn't asked.
  offline,
  failed,
}

/// How "Download and install" ended.
enum UpdateDownloadResult { started, declined, offline, failed }

/// Checks Google Play for a newer One Dialer, downloads it in the background (Play's
/// flexible flow) and installs it when the user taps "Install and restart".
///
/// If auto-check is on (Software update › Auto download, off by default), the app calls
/// [autoCheck] once per launch, after the first frame. That result only shows as a dot on
/// the Software update row and on its page, never as a pop-up.
class UpdateController extends ChangeNotifier {
  final UpdateService service;
  final DialerPrefs? settings;
  final NetworkStatus _network;

  /// A tapped check shows its dots at least this long, so a fast answer doesn't flash.
  final Duration minCheckDuration;

  UpdateController({
    required this.service,
    this.settings,
    NetworkStatus? network,
    this.minCheckDuration = Duration.zero,
  }) : _network = network ?? const AnyNetworkStatus();

  static final UpdateController instance = UpdateController(
    service: PlayUpdateService(),
    settings: DialerPrefs.instance,
    network: ConnectivityNetworkStatus(),
    minCheckDuration: const Duration(milliseconds: 900),
  );

  UpdateStatus _status = UpdateStatus.notChecked;
  AutoUpdateCheck _autoCheck = AutoUpdateCheck.never;
  DateTime? _lastChecked;
  bool _installing = false;
  StreamSubscription<UpdateDownloadState>? _downloadStates;
  Timer? _resumedDownloadWatch;

  UpdateStatus get status => _status;
  DateTime? get lastChecked => _lastChecked;

  /// Something new to act on (drives the orange dot): found, downloading or ready.
  bool get updateAvailable =>
      _status == UpdateStatus.available ||
      _status == UpdateStatus.downloading ||
      _status == UpdateStatus.readyToInstall;
  bool get installing => _installing;

  /// When the launch check runs (Software update › Auto download).
  AutoUpdateCheck get autoCheckMode => _autoCheck;

  /// Reads the saved [autoCheckMode]. Called once at launch (`main()`).
  Future<void> loadPreferences() async {
    final saved = await settings?.getAutoUpdateCheck();
    _autoCheck = AutoUpdateCheck.values.asNameMap()[saved] ?? AutoUpdateCheck.never;
    notifyListeners();
  }

  Future<void> setAutoCheck(AutoUpdateCheck mode) async {
    if (mode == _autoCheck) return;
    _autoCheck = mode;
    notifyListeners();
    await settings?.setAutoUpdateCheck(mode.name);
  }

  /// The once-per-launch check, honouring [autoCheckMode]. Offline it stays quiet.
  /// Returns whether it asked Play.
  Future<bool> autoCheck() async {
    switch (_autoCheck) {
      case AutoUpdateCheck.never:
        return false;
      case AutoUpdateCheck.wifiOnly:
        if (!await _network.onUnmeteredNetwork()) return false;
      case AutoUpdateCheck.always:
        if (!await _network.isConnected()) return false;
    }
    await check(quick: true);
    return true;
  }

  /// Asks Play for updates. Returns the new status. Without a connection Play isn't asked
  /// and the status is [UpdateStatus.offline]. [quick] skips [minCheckDuration].
  Future<UpdateStatus> check({bool quick = false}) async {
    if (_status == UpdateStatus.checking) return _status;
    // A download in progress, or one waiting to install, is still the answer.
    if (_status == UpdateStatus.downloading || _status == UpdateStatus.readyToInstall) return _status;
    _set(UpdateStatus.checking);
    final minimum = quick || minCheckDuration == Duration.zero
        ? Future<void>.value()
        : Future<void>.delayed(minCheckDuration);
    if (!await _network.isConnected()) {
      await minimum;
      _set(UpdateStatus.offline);
      return _status;
    }
    final result = await service.check();
    await minimum;
    _lastChecked = DateTime.now();
    switch (result) {
      case UpdateCheckResult.upToDate:
        _set(UpdateStatus.upToDate);
      case UpdateCheckResult.available:
        _set(UpdateStatus.available);
      case UpdateCheckResult.downloading:
        _set(UpdateStatus.downloading);
        _watchResumedDownload();
      case UpdateCheckResult.downloaded:
        _set(UpdateStatus.readyToInstall);
      case UpdateCheckResult.inProgress:
        // Play's guidance: an immediate update that was interrupted should be resumed.
        _set(UpdateStatus.available);
        await install();
      case UpdateCheckResult.notFromPlay:
        _set(UpdateStatus.notFromPlay);
      case UpdateCheckResult.failed:
        _set(UpdateStatus.failed);
    }
    return _status;
  }

  /// Forgets a finished check that found nothing to act on (up to date, offline, failed,
  /// not from Play), so Software update offers "Check for updates" again when reopened.
  /// A found, downloading or downloaded update is kept. Doesn't notify: it's called while
  /// the page is being built, and nothing else shows these statuses.
  void resetSettledResult() {
    switch (_status) {
      case UpdateStatus.upToDate || UpdateStatus.offline || UpdateStatus.failed || UpdateStatus.notFromPlay:
        _status = UpdateStatus.notChecked;
      default:
        break;
    }
  }

  /// Downloads the available update in the background; Play first shows its small
  /// confirmation sheet. While it runs the status is [UpdateStatus.downloading], then
  /// [UpdateStatus.readyToInstall].
  Future<UpdateDownloadResult> download() async {
    if (_status == UpdateStatus.downloading) return UpdateDownloadResult.started;
    if (_status != UpdateStatus.available) return UpdateDownloadResult.failed;
    if (!await _network.isConnected()) return UpdateDownloadResult.offline;

    _set(UpdateStatus.downloading);
    _downloadStates ??= service.downloadStates.listen(_onDownloadState);
    switch (await service.startDownload()) {
      case UpdateInstallResult.started:
        // The download is done (Play's full-screen fallback restarts the app by itself).
        if (_status == UpdateStatus.downloading) _downloaded();
        return UpdateDownloadResult.started;
      case UpdateInstallResult.declined:
        _stopWatching();
        _set(UpdateStatus.available);
        return UpdateDownloadResult.declined;
      case UpdateInstallResult.failed:
        _stopWatching();
        // A "failed" from the progress stream may already have reset the status.
        if (_status == UpdateStatus.downloading) _set(UpdateStatus.available);
        return UpdateDownloadResult.failed;
    }
  }

  /// Installs the finished download. Play shows a brief screen and restarts One Dialer.
  Future<bool> installAndRestart() async {
    if (_status != UpdateStatus.readyToInstall || _installing) return false;
    _installing = true;
    notifyListeners();
    try {
      return await service.installDownloaded();
    } finally {
      _installing = false;
      notifyListeners();
    }
  }

  /// Opens Play's full-screen updater, used to resume an interrupted immediate update.
  /// Play restarts the app when it's done.
  Future<UpdateInstallResult> install() async {
    if (_installing) return UpdateInstallResult.started;
    if (_status != UpdateStatus.available) {
      if (await check() != UpdateStatus.available) return UpdateInstallResult.failed;
    }
    _installing = true;
    notifyListeners();
    try {
      return await service.installNow();
    } finally {
      _installing = false;
      notifyListeners();
    }
  }

  void _onDownloadState(UpdateDownloadState state) {
    switch (state) {
      case UpdateDownloadState.pending || UpdateDownloadState.downloading:
        if (_status != UpdateStatus.downloading) _set(UpdateStatus.downloading);
      case UpdateDownloadState.downloaded:
        _downloaded();
      case UpdateDownloadState.failed || UpdateDownloadState.canceled:
        _stopWatching();
        if (_status == UpdateStatus.downloading) _set(UpdateStatus.available);
    }
  }

  void _downloaded() {
    _stopWatching();
    if (_status == UpdateStatus.readyToInstall) return;
    _set(UpdateStatus.readyToInstall);
  }

  /// A download started in an earlier session has no progress stream here (the plugin only
  /// reports downloads it started), so ask Play now and then until it's done.
  void _watchResumedDownload() {
    _resumedDownloadWatch?.cancel();
    _resumedDownloadWatch = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_status != UpdateStatus.downloading) {
        _stopWatching();
        return;
      }
      switch (await service.check()) {
        case UpdateCheckResult.downloaded:
          _downloaded();
        case UpdateCheckResult.available:
          _stopWatching();
          _set(UpdateStatus.available);
        default:
          break;
      }
    });
  }

  void _stopWatching() {
    _resumedDownloadWatch?.cancel();
    _resumedDownloadWatch = null;
    unawaited(_downloadStates?.cancel());
    _downloadStates = null;
  }

  void _set(UpdateStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopWatching();
    super.dispose();
  }
}
