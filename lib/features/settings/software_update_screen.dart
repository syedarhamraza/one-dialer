import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/config/changelog.dart';
import '../updates/data/update_service.dart';
import '../updates/presentation/update_controller.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_ambient_glow.dart';
import '../../widgets/one_ui_cancel_save_pill.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import 'changelog_screen.dart';
import '../../core/haptics/haptics.dart';

/// Settings › Software update, in the style of One UI's own Software update page:
/// the version over a soft glow, the result of the last check, and one big button.
/// Google Play in-app updates do the work: the update downloads in the background while
/// the app stays usable, then "Install and restart" finishes it.
class SoftwareUpdateScreen extends StatefulWidget {
  const SoftwareUpdateScreen({super.key});

  static Future<void> open(BuildContext context) {
    Haptics.tap();
    return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SoftwareUpdateScreen()));
  }

  @override
  State<SoftwareUpdateScreen> createState() => _SoftwareUpdateScreenState();
}

class _SoftwareUpdateScreenState extends State<SoftwareUpdateScreen> {
  final GlobalKey _moreKey = GlobalKey();

  /// The transition shared by the button and the status text, so they change together.
  static const transition = Duration(milliseconds: 220);

  late final UpdateController _updates = UpdateController.instance..resetSettledResult();
  late UpdateStatus _lastStatus = _updates.status;

  /// Set while [_download] reports the end of a download itself (declined, failed).
  bool _downloadEnding = false;

  @override
  void initState() {
    super.initState();
    _updates.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _updates.removeListener(_onStatusChanged);
    super.dispose();
  }

  /// A background download that Play gives up on goes back to "Download and install";
  /// say why.
  void _onStatusChanged() {
    final previous = _lastStatus;
    _lastStatus = _updates.status;
    if (previous == UpdateStatus.downloading && _lastStatus == UpdateStatus.available && !_downloadEnding && mounted) {
      OneUIToast.show(context, "The download stopped. Try again when you're connected.");
    }
  }

  Future<void> _onButtonTap() async {
    Haptics.tap();
    switch (_updates.status) {
      case UpdateStatus.available:
        await _download();
      case UpdateStatus.readyToInstall:
        if (!await _updates.installAndRestart() && mounted) {
          OneUIToast.show(context, "Couldn't install the update. Try again.");
        }
      default:
        // The status line shows the result; a found update waits for "Download and install".
        await _updates.check();
    }
  }

  Future<void> _download() async {
    _downloadEnding = true;
    try {
      final result = await _updates.download();
      if (!mounted) return;
      switch (result) {
        case UpdateDownloadResult.started:
          break; // the page now says the update is ready to install
        case UpdateDownloadResult.declined:
          OneUIToast.show(context, 'Update cancelled. You can download it any time from here.');
        case UpdateDownloadResult.offline:
          OneUIToast.show(context, 'No internet connection. Connect and try again.');
        case UpdateDownloadResult.failed:
          OneUIToast.show(context, "Couldn't download the update. Try again.");
      }
    } finally {
      _downloadEnding = false;
    }
  }

  void _showMenu() {
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _moreKey,
      fallbackTop: MediaQuery.paddingOf(context).top + 6.0,
      width: 220,
      items: [
        OneUIFloatingMenuItem(label: 'Software information', onTap: () => _SoftwareInformation.show(context)),
        OneUIFloatingMenuItem(
          label: 'Auto download',
          onTap: () {
            Haptics.tap();
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _AutoDownloadScreen()));
          },
        ),
        OneUIFloatingMenuItem(label: 'Changelog', onTap: () => ChangelogScreen.open(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: ListenableBuilder(
        listenable: UpdateController.instance,
        builder: (context, _) {
          final updates = UpdateController.instance;
          final status = updates.status;
          final busy = status == UpdateStatus.checking || status == UpdateStatus.downloading || updates.installing;
          final buttonLabel = switch (status) {
            UpdateStatus.notChecked || UpdateStatus.checking => 'Check for updates',
            UpdateStatus.available || UpdateStatus.downloading => 'Download and install',
            UpdateStatus.readyToInstall => 'Install and restart',
            UpdateStatus.failed || UpdateStatus.offline => 'Try again',
            UpdateStatus.upToDate || UpdateStatus.notFromPlay => null,
          };
          return Stack(
            children: [
              // One UI's blue and amber halo behind the version.
              OneUIAmbientGlow(
                color: OneUITheme.accentBlue,
                center: Alignment(0.22, -0.16),
                radius: 0.62,
                alphas: [0.34, 0.16, 0.04, 0.0],
              ),
              OneUIAmbientGlow(
                color: OneUITheme.accentOrange,
                center: Alignment(-0.24, 0.12),
                radius: 0.56,
                alphas: [0.24, 0.10, 0.02, 0.0],
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          // The menu opens from this wrapper (see the Calls header's menu).
                          KeyedSubtree(
                            key: _moreKey,
                            child: RoundIconButton(
                              icon: Icons.more_vert_rounded,
                              tooltip: 'More options',
                              onTap: _showMenu,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: _Headline(status: status),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 96,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: transition,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                              child: child,
                            ),
                          ),
                          child: buttonLabel == null && !busy
                              ? const SizedBox.shrink()
                              : _UpdateButton(
                                  key: const ValueKey('button'),
                                  label: buttonLabel ?? 'Check for updates',
                                  busy: busy,
                                  busyLabel: status == UpdateStatus.downloading
                                      ? 'Downloading the update'
                                      : 'Checking for updates',
                                  onTap: busy ? null : _onButtonTap,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "Dialer 1.0.0", the pre-release channel, and what the last check found.
class _Headline extends StatelessWidget {
  final UpdateStatus status;

  const _Headline({required this.status});

  @override
  Widget build(BuildContext context) {
    final (message, color) = switch (status) {
      UpdateStatus.notChecked || UpdateStatus.checking => (null, OneUITheme.textSecondary),
      UpdateStatus.upToDate => ('One Dialer is up to date.', OneUITheme.textSecondary),
      UpdateStatus.available => ('A new version is available.', OneUITheme.accentBlue),
      UpdateStatus.downloading => ('Downloading the update… You can keep using One Dialer.', OneUITheme.textSecondary),
      UpdateStatus.readyToInstall => ('The update is ready to install.', OneUITheme.accentBlue),
      UpdateStatus.offline => (
        'No internet connection. Connect to Wi-Fi or mobile data and try again.',
        OneUITheme.textSecondary,
      ),
      UpdateStatus.notFromPlay => (
        "Updates come from Google Play. This copy wasn't installed from Play.",
        OneUITheme.textSecondary,
      ),
      UpdateStatus.failed => ("Couldn't reach Google Play.", OneUITheme.textSecondary),
    };
    return FutureBuilder<AppVersion?>(
      future: AppVersion.current(),
      builder: (context, snapshot) {
        final v = snapshot.data;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                v == null ? AppInfo.name : '${AppInfo.name} ${v.number}',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: OneUITheme.textPrimary,
                ),
              ),
            ),
            if (v != null && v.isPreRelease) ...[
              const SizedBox(height: 2),
              Text(v.channelLabel, style: const TextStyle(fontSize: 16, color: OneUITheme.textSecondary)),
            ],
            // A fixed slot, so the title stays put when a message appears.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72, minWidth: double.infinity),
              child: AnimatedSwitcher(
                duration: _SoftwareUpdateScreenState.transition,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) =>
                    Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: message == null
                    ? const SizedBox(key: ValueKey('none'), width: double.infinity)
                    : Padding(
                        key: ValueKey(message),
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, height: 1.35, color: color),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The big blue capsule at the bottom. While busy its label becomes One UI's spinning dots.
class _UpdateButton extends StatelessWidget {
  final String label;
  final bool busy;

  /// What screen readers hear while [busy].
  final String busyLabel;
  final VoidCallback? onTap;

  const _UpdateButton({
    super.key,
    required this.label,
    required this.busy,
    required this.busyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: busy ? busyLabel : null,
      child: Material(
        color: OneUITheme.accentBlue,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 224,
            height: 54,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: busy
                    ? const _LoadingDots(key: ValueKey('dots'))
                    : Text(
                        label,
                        key: ValueKey(label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Four dots turning in a square, like One UI's progress indicator.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots({super.key});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = SizedBox.square(
      dimension: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
    return RotationTransition(
      turns: CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      child: SizedBox.square(
        dimension: 18,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            Widget at(Alignment alignment, int i) {
              final phase = (_controller.value * 4 - i) % 4;
              final opacity = phase < 1 ? 1.0 : 0.55;
              return Align(
                alignment: alignment,
                child: Opacity(opacity: opacity, child: dot),
              );
            }

            return Stack(
              children: [
                at(Alignment.topCenter, 0),
                at(Alignment.centerRight, 1),
                at(Alignment.bottomCenter, 2),
                at(Alignment.centerLeft, 3),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ⋮ › Software information: a floating sheet listing the version details.
class _SoftwareInformation extends StatefulWidget {
  const _SoftwareInformation();

  static Future<void> show(BuildContext context) {
    Haptics.tap();
    return OneUIFloatingModal.show<void>(context: context, builder: (_) => const _SoftwareInformation());
  }

  @override
  State<_SoftwareInformation> createState() => _SoftwareInformationState();
}

class _SoftwareInformationState extends State<_SoftwareInformation> {
  AppVersion? _version;
  String? _installer;
  String? _android;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fills the lines in as the platform answers; the sheet opens straight away.
  Future<void> _load() async {
    final version = await AppVersion.current();
    String? installer;
    String? android;
    try {
      installer = (await PackageInfo.fromPlatform()).installerStore;
    } catch (_) {}
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        android = (await DeviceInfoPlugin().androidInfo).version.release;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _version = version;
      _installer = installer;
      _android = android;
    });
  }

  String get _source => switch (_installer) {
    PlayUpdateService.playStoreInstaller => 'Google Play',
    null => 'Installed directly',
    _ => 'Another app store',
  };

  @override
  Widget build(BuildContext context) {
    final v = _version;
    final android = _android;
    final lines = [
      if (android != null) 'Android version: $android',
      'Version: ${v?.label ?? AppVersion.describe(Changelog.entries.first.version)}',
      if (v?.code != null) 'Build: ${v!.code}',
      'Installed from: $_source',
      if (kDebugMode && BuildInfo.commit.isNotEmpty) 'Commit: ${BuildInfo.commit}',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Software information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
        ),
        const SizedBox(height: 12),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              '• $line',
              style: const TextStyle(fontSize: 15.5, height: 1.35, color: Color(0xFFC4C4CA), letterSpacing: -0.2),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
            ),
          ),
        ),
      ],
    );
  }
}

/// ⋮ › Auto download: when Dialer checks Google Play by itself at launch.
class _AutoDownloadScreen extends StatefulWidget {
  const _AutoDownloadScreen();

  @override
  State<_AutoDownloadScreen> createState() => _AutoDownloadScreenState();
}

class _AutoDownloadScreenState extends State<_AutoDownloadScreen> {
  AutoUpdateCheck _mode = UpdateController.instance.autoCheckMode;

  void _save() {
    Haptics.confirm();
    unawaited(UpdateController.instance.setAutoCheck(_mode)); // saved in the background
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Auto download',
      bottomPill: OneUIFloatingCancelSavePill(onCancel: () => Navigator.pop(context), onSave: _save),
      builder: (context) => [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Text(
            'Choose when One Dialer checks Google Play for updates when you open it.\n\n'
            'Updates are only installed when you tap Download and install.',
            style: TextStyle(fontSize: 15, height: 1.4, color: OneUITheme.textPrimary),
          ),
        ),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            for (final mode in AutoUpdateCheck.values)
              OneUIGroupItem(
                leading: OneUIRadio(isSelected: mode == _mode),
                title: mode.label,
                subtitle: switch (mode) {
                  AutoUpdateCheck.never => 'Only when you tap Check for updates',
                  AutoUpdateCheck.wifiOnly => null,
                  AutoUpdateCheck.always => 'Checking uses very little data.',
                },
                subtitleColor: OneUITheme.textSecondary,
                onTap: () {
                  Haptics.select();
                  setState(() => _mode = mode);
                },
              ),
          ],
        ),
      ],
    );
  }
}
