import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/config/changelog.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/version_mark.dart';
import '../updates/data/update_service.dart';
import '../updates/presentation/update_controller.dart';
import 'software_update_screen.dart';

/// Settings › About One Dialer (also Software update › Software information): the artwork card
/// with the version and a button to Software update, then the details (where it came from too).
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  AppVersion? _version;
  String? _device;
  String? _android;
  String? _installer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final version = await AppVersion.current();
    String? device, android, installer;
    try {
      installer = (await PackageInfo.fromPlatform()).installerStore;
      final info = await DeviceInfoPlugin().androidInfo;
      device = '${info.manufacturer} ${info.model}';
      android = info.version.release;
    } catch (_) {
      // Not on Android (tests): those rows stay empty.
    }
    if (mounted) {
      setState(() {
        _version = version;
        _device = device;
        _android = android;
        _installer = installer;
      });
    }
  }

  String get _source => switch (_installer) {
    PlayUpdateService.playStoreInstaller => 'Google Play',
    'com.sec.android.app.samsungapps' => 'Galaxy Store',
    // A file opened on the phone, or adb.
    null || 'com.android.shell' => 'Installed directly',
    final i when i.contains('packageinstaller') => 'Installed directly',
    _ => 'Another app store',
  };

  @override
  Widget build(BuildContext context) {
    final v = _version;
    OneUIGroupItem row(String title, String? value) =>
        OneUIGroupItem(title: title, value: value, trailing: const SizedBox.shrink());
    return OneUISubpage(
      title: 'About ${AppInfo.name}',
      builder: (context) => [
        // The artwork card (softly blurred) with the version mark centred in it and, under
        // the channel, the way to Software update.
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 340,
            child: Stack(
              children: [
                const Positioned.fill(child: CosArtwork(waveShift: .3, blur: 3, dim: .35)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VersionMark(
                        version: v == null ? '' : '${v.major}.${v.minor}',
                        channel: v != null && v.isPreRelease ? v.channelLabel : null,
                        size: 96,
                      ),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: UpdateController.instance,
                        builder: (context, _) {
                          final updates = UpdateController.instance;
                          final update = updates.updateAvailable;
                          // "Version up to date" only once a check has confirmed it, as ColorOS
                          // does; lit green only when there's something to get.
                          return GlowButton(
                            label: update
                                ? 'Update available'
                                : updates.status == UpdateStatus.upToDate
                                ? 'Version up to date'
                                : 'Check for updates',
                            busy: updates.status == UpdateStatus.checking,
                            busyLabel: 'Checking…',
                            lit: update,
                            height: 44,
                            fontSize: 15,
                            onTap: () => SoftwareUpdateScreen.open(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        OneUIGroupCard(
          items: [
            row('Version', v?.label ?? AppVersion.describe(Changelog.entries.first.version)),
            if (v?.code != null) row('Build', '${v!.code}'),
            row('Installed from', _installer == null && v == null ? null : _source),
            row('Device', _device),
            row('Android version', _android),
            if (kDebugMode && BuildInfo.commit.isNotEmpty) row('Commit', BuildInfo.commit),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: 'Open source licences',
              onTap: () =>
                  showLicensePage(context: context, applicationName: AppInfo.name, applicationVersion: v?.label),
            ),
          ],
        ),
      ],
    );
  }
}
