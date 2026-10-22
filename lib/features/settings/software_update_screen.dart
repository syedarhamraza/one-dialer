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
import '../../widgets/cos_artwork.dart';
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

/// Settings › Software update, in the style of ColorOS 17's: the version over the ColorOS
/// artwork, the result of the last check (or the update's cards), and one big button.
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
        OneUIFloatingMenuItem(label: "What's new", onTap: () => ChangelogScreen.open(context)),
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
          // ColorOS shows the version card and notes only while there's an update to get.
          final hasUpdate =
              status == UpdateStatus.available ||
              status == UpdateStatus.downloading ||
              status == UpdateStatus.readyToInstall;
          return Stack(
            children: [
              // ColorOS's artwork, fading to black where the cards sit.
              const Positioned.fill(child: CosArtwork()),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x00000000), Color(0xE6000000), Color(0xFF000000)],
                      stops: [0, 0.45, 0.72, 1],
                    ),
                  ),
                ),
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
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Software update',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                            ),
                          ),
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
                    const Expanded(child: Center(child: _Hero())),
                    AnimatedSwitcher(
                      duration: transition,
                      child: hasUpdate
                          ? const _UpdateCards(key: ValueKey('cards'))
                          : _StatusLine(key: const ValueKey('status'), status: status),
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

/// ColorOS's big version over the artwork: "1.0", "One Dialer", and the channel.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppVersion?>(
      future: AppVersion.current(),
      builder: (context, snapshot) {
        final v = snapshot.data;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              v == null ? '' : '${v.major}.${v.minor}',
              style: const TextStyle(fontSize: 96, height: 1, fontWeight: FontWeight.w700, letterSpacing: -3),
            ),
            const Text(AppInfo.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            if (v != null && v.isPreRelease)
              Text(v.channelLabel, style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF))),
          ],
        );
      },
    );
  }
}

/// What the last check found, centred under the artwork ("No network connection").
class _StatusLine extends StatelessWidget {
  const _StatusLine({super.key, required this.status});

  final UpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      UpdateStatus.notChecked => '',
      UpdateStatus.checking => 'Checking for updates…',
      UpdateStatus.upToDate => 'Version up to date',
      UpdateStatus.offline => 'No network connection',
      UpdateStatus.notFromPlay => "Updates come from Google Play. This copy wasn't installed from Play.",
      UpdateStatus.failed => "Couldn't reach Google Play",
      UpdateStatus.available || UpdateStatus.downloading || UpdateStatus.readyToInstall => '',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.35, color: Color(0xE6FFFFFF)),
          ),
        ),
      ),
    );
  }
}

/// ColorOS's "Software version" card and the collapsible "About this update" notes.
class _UpdateCards extends StatefulWidget {
  const _UpdateCards({super.key});

  @override
  State<_UpdateCards> createState() => _UpdateCardsState();
}

class _UpdateCardsState extends State<_UpdateCards> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    // Play doesn't say what's in the update, so the notes are the newest written ones.
    final notes = Changelog.entries.first;
    final card = BoxDecoration(color: const Color(0xF21C1C1E), borderRadius: OneUITheme.cardBorderRadius);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Software version', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (notes.version.contains('-'))
                        const Text('Closed beta', style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppInfo.name} ${notes.version}',
                    style: const TextStyle(fontSize: 14, color: OneUITheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: OneUITheme.cardBorderRadius,
                    onTap: () => setState(() => _open = !_open),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'About this update',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(
                            _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: OneUITheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_open)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final change in notes.changes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                change,
                                style: const TextStyle(fontSize: 15, height: 1.35, color: Color(0xDDFFFFFF)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            width: MediaQuery.sizeOf(context).width - 48,
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
