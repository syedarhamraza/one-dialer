import 'package:flutter/material.dart';

import '../../app/app_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../blocking/blocking_repository.dart';
import '../blocking/blocking_screen.dart';
import '../keypad/speed_dial_screen.dart';
import 'quick_replies_screen.dart';

/// Call settings, plus a health check of everything incoming calls depend on.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _telecom = TelecomBridge.instance;
  Map<Object?, Object?> _health = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(); // back from a system settings screen
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    final health = await _telecom.getCallHealth();
    if (mounted) setState(() => _health = health);
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  /// Rows only for problems; empty when everything incoming calls need is in place.
  List<OneUIGroupItem> get _problems {
    if (_health.isEmpty) return const [];
    final rules = BlockingRepository.instance.rules.value;
    return [
      if (_health['isDefaultDialer'] != true)
        _problem('Not your default phone app', 'Incoming calls use another app', () async {
          await _telecom.requestDefaultDialer();
          _refresh();
        }),
      if (_health['notificationsEnabled'] != true)
        _problem(
          'Notifications are off',
          'You won\'t see incoming or missed calls',
          () => _telecom.openSystemSettings('notifications'),
        ),
      if (_health['fullScreenAllowed'] != true)
        _problem(
          'Full-screen calls are off',
          'Incoming calls only show as a notification',
          () => _telecom.openSystemSettings('fullScreen'),
        ),
      if ((rules.blockHidden || rules.blockNonContacts) && _health['screensCalls'] != true)
        _problem('Blocking rules are paused', 'Another app screens your calls', () => _push(const BlockingScreen())),
    ];
  }

  OneUIGroupItem _problem(String title, String subtitle, VoidCallback onFix) => OneUIGroupItem(
    leading: const Icon(Icons.warning_amber_rounded, color: OneUITheme.accentRed),
    title: title,
    subtitle: subtitle,
    subtitleColor: OneUITheme.accentRed,
    onTap: onFix,
    trailing: const Text(
      'Fix',
      style: TextStyle(color: OneUITheme.accentBlue, fontWeight: FontWeight.w700),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final problems = _problems;
    final version = _health['version'];
    return OneUISubpage(
      title: 'Call settings',
      builder: (context) => [
        if (problems.isNotEmpty) OneUIGroupCard(headerTitle: 'Needs attention', items: problems),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              leading: const Icon(Icons.block_rounded, color: OneUITheme.accentRed),
              title: 'Block numbers',
              onTap: () => _push(const BlockingScreen()),
            ),
            OneUIGroupItem(
              leading: const Icon(Icons.message_outlined, color: OneUITheme.accentBlue),
              title: 'Quick decline messages',
              onTap: () => _push(const QuickRepliesScreen()),
            ),
            OneUIGroupItem(
              leading: const Icon(Icons.speed_rounded, color: OneUITheme.accentGreen),
              title: 'Speed dial numbers',
              onTap: () => _push(const SpeedDialScreen()),
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              leading: const Icon(Icons.apps_rounded, color: OneUITheme.textSecondary),
              title: 'Default apps',
              subtitle: 'Phone app, caller ID & spam app',
              onTap: () => _telecom.openSystemSettings('defaultApps'),
            ),
            OneUIGroupItem(
              leading: const Icon(Icons.notifications_none_rounded, color: OneUITheme.textSecondary),
              title: 'Notifications',
              onTap: () => _telecom.openSystemSettings('notifications'),
            ),
          ],
        ),
        OneUIGroupCard(
          headerTitle: 'About',
          items: [
            OneUIGroupItem(
              title: 'Version',
              subtitle: version == null ? null : '$version (${_health['build']})',
              trailing: const SizedBox.shrink(),
            ),
            OneUIGroupItem(
              title: 'Privacy policy',
              onTap: () => _telecom.openSystemSettings('url:${AppInfo.privacyPolicyUrl}'),
            ),
          ],
        ),
      ],
    );
  }
}
