import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../updates/presentation/update_controller.dart';
import 'software_update_screen.dart';

/// Settings › About One Dialer, like ColorOS 17's About device: the artwork card with the
/// version and a "Version up to date" pill, then the details.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  AppVersion? _version;
  String? _device;
  String? _android;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final version = await AppVersion.current();
    String? device, android;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      device = '${info.manufacturer} ${info.model}';
      android = info.version.release;
    } catch (_) {
      // Not on Android (tests): the rows stay empty.
    }
    if (mounted) {
      setState(() {
        _version = version;
        _device = device;
        _android = android;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _version;
    return OneUISubpage(
      title: 'About ${AppInfo.name}',
      builder: (context) => [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 260,
            child: Stack(
              children: [
                const Positioned.fill(child: CosArtwork()),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(AppInfo.name, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                      if (v != null)
                        Text(v.label, style: const TextStyle(fontSize: 16, color: Color(0xDDFFFFFF))),
                      const SizedBox(height: 18),
                      ListenableBuilder(
                        listenable: UpdateController.instance,
                        builder: (context, _) => _Pill(
                          label: UpdateController.instance.updateAvailable ? 'Update available' : 'Version up to date',
                          onTap: () => SoftwareUpdateScreen.open(context),
                        ),
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
            OneUIGroupItem(title: 'Version', value: v?.label, trailing: const SizedBox.shrink()),
            if (v?.code != null) OneUIGroupItem(title: 'Build', value: '${v!.code}', trailing: const SizedBox.shrink()),
            OneUIGroupItem(title: 'Device', value: _device, trailing: const SizedBox.shrink()),
            OneUIGroupItem(title: 'Android version', value: _android, trailing: const SizedBox.shrink()),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: 'Open source licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.name,
                applicationVersion: v?.label,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ColorOS's frosted "Version up to date" capsule on the artwork (a tint, no blur).
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
