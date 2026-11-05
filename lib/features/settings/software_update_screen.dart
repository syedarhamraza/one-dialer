import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../updates/data/update_service.dart';
import '../updates/presentation/update_controller.dart';
import '../../theme/one_ui_theme.dart';
import '../../theme/one_ui_scroll.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/version_mark.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../../app/sideload_warning.dart';
import 'about_screen.dart';
import 'changelog_screen.dart';
import '../../core/haptics/haptics.dart';
import '../../l10n/l10n.dart';

/// Settings › Software update: the version over the artwork, the last check's result (or
/// the update's cards), and one lit green button that shimmers while it works.
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
      OneUIToast.show(context, context.l10n.downloadStopped);
    }
  }

  Future<void> _onButtonTap() async {
    Haptics.tap();
    switch (_updates.status) {
      case UpdateStatus.available:
        await _download();
      case UpdateStatus.notFromPlay:
        openOfficialVersion();
      case UpdateStatus.readyToInstall:
        if (!await _updates.installAndRestart() && mounted) {
          OneUIToast.show(context, context.l10n.couldNotInstallUpdate);
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
          OneUIToast.show(context, context.l10n.updateCancelled);
        case UpdateDownloadResult.offline:
          OneUIToast.show(context, context.l10n.noInternet);
        case UpdateDownloadResult.failed:
          OneUIToast.show(context, context.l10n.couldNotDownloadUpdate);
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
        OneUIFloatingMenuItem(
          label: context.l10n.softwareInformation,
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
        ),
        OneUIFloatingMenuItem(
          label: context.l10n.autoDownload,
          onTap: () {
            Haptics.tap();
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _AutoDownloadScreen()));
          },
        ),
        OneUIFloatingMenuItem(label: context.l10n.changelog, onTap: () => ChangelogScreen.open(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.page,
      body: ListenableBuilder(
        listenable: UpdateController.instance,
        builder: (context, _) {
          final updates = UpdateController.instance;
          final status = updates.status;
          final busy = status == UpdateStatus.checking || status == UpdateStatus.downloading || updates.installing;
          final buttonLabel = switch (status) {
            UpdateStatus.notChecked || UpdateStatus.checking => context.l10n.checkForUpdates,
            UpdateStatus.available || UpdateStatus.downloading => context.l10n.downloadAndInstall,
            UpdateStatus.readyToInstall => context.l10n.installAndRestart,
            UpdateStatus.failed || UpdateStatus.offline => context.l10n.tryAgain,
            UpdateStatus.notFromPlay => context.l10n.getOfficialVersion,
            UpdateStatus.upToDate => null,
          };
          // ColorOS shows the version card and notes only while there's an update to get.
          final hasUpdate =
              status == UpdateStatus.available ||
              status == UpdateStatus.downloading ||
              status == UpdateStatus.readyToInstall;
          return Stack(
            children: [
              // The artwork behind the version, fading into the black page where the cards sit.
              const Positioned.fill(child: CosArtwork(fadeToBlack: .3, waveShift: .16)),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: context.l10n.back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              context.l10n.softwareUpdate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                            ),
                          ),
                          // The menu opens from this wrapper (see the Calls header's menu).
                          KeyedSubtree(
                            key: _moreKey,
                            child: RoundIconButton(
                              icon: Icons.more_vert_rounded,
                              tooltip: context.l10n.moreOptions,
                              onTap: _showMenu,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Centred on the page; the ribbon and sphere sit lower, below it.
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
                              : GlowButton(
                                  key: const ValueKey('button'),
                                  label: buttonLabel ?? context.l10n.checkForUpdates,
                                  busy: busy,
                                  busyLabel: status == UpdateStatus.downloading
                                      ? context.l10n.downloading
                                      : context.l10n.checking,
                                  width: MediaQuery.sizeOf(context).width - 48,
                                  onTap: _onButtonTap,
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

/// The version mark over the artwork: "1.0" in glass, "One Dialer" and the channel.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppVersion?>(
      future: AppVersion.current(),
      builder: (context, snapshot) {
        final v = snapshot.data;
        return VersionMark(
          version: v == null ? '' : '${v.major}.${v.minor}',
          channel: v != null && v.isPreRelease ? v.channelLabel : null,
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
      UpdateStatus.checking => '',
      UpdateStatus.upToDate => context.l10n.versionUpToDate,
      UpdateStatus.offline => context.l10n.noNetwork,
      UpdateStatus.notFromPlay => context.l10n.notFromPlay,
      UpdateStatus.failed => context.l10n.couldNotReachPlay,
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
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: context.palette.isLight ? context.palette.textSecondary : const Color(0xE6FFFFFF),
            ),
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
  void initState() {
    super.initState();
    UpdateController.instance.addListener(_changed); // the notes arrive after the check
  }

  @override
  void dispose() {
    UpdateController.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // The update's own notes from the website: never the installed version's.
    final notes = UpdateController.instance.updateNotes;
    final card = BoxDecoration(color: context.palette.card, borderRadius: OneUITheme.cardBorderRadius);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
      child: SingleChildScrollView(
        physics: const HoldStillScrollPhysics(), // a panel inside the page, not the page
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
                      Text(
                        context.l10n.softwareVersion,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      if (notes?.version.contains('-') ?? false)
                        Text(
                          context.l10n.closedBeta,
                          style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes == null ? context.l10n.newVersionAvailable : '${AppInfo.name} ${notes.version}',
                    style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
                  ),
                ],
              ),
            ),
            if (notes != null) ...[
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
                            Expanded(
                              child: Text(
                                context.l10n.aboutThisUpdate,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Icon(
                              _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: context.palette.textSecondary,
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
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.35,
                                    color: context.palette.textPrimary.withValues(alpha: .87),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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

  void _pick(AutoUpdateCheck mode) {
    Haptics.select();
    setState(() => _mode = mode);
    unawaited(UpdateController.instance.setAutoCheck(mode)); // saved in the background
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: context.l10n.autoDownload,
      builder: (context) => [
        Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Text(
            context.l10n.autoDownloadExplainer,
            style: TextStyle(fontSize: 15, height: 1.4, color: context.palette.textSecondary),
          ),
        ),
        OneUIGroupCard(
          items: [
            for (final mode in AutoUpdateCheck.values)
              OneUIGroupItem(
                title: switch (mode) {
                  AutoUpdateCheck.never => context.l10n.autoUpdateNever,
                  AutoUpdateCheck.wifiOnly => context.l10n.autoUpdateWifiOnly,
                  AutoUpdateCheck.always => context.l10n.autoUpdateAlways,
                },
                subtitle: switch (mode) {
                  AutoUpdateCheck.never => context.l10n.autoUpdateNeverSubtitle,
                  AutoUpdateCheck.wifiOnly => null,
                  AutoUpdateCheck.always => context.l10n.autoUpdateAlwaysSubtitle,
                },
                // ColorOS marks the choice with a check on the right.
                trailing: mode == _mode
                    ? const Icon(Icons.check_rounded, color: OneUITheme.dialGreen)
                    : const SizedBox(width: 24),
                onTap: () => _pick(mode),
              ),
          ],
        ),
      ],
    );
  }
}
