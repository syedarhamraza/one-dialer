import 'package:flutter/material.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_group_card.dart';
import '../blocking/blocking_repository.dart';
import '../blocking/blocking_screen.dart';
import '../keypad/speed_dial_screen.dart';
import '../updates/presentation/update_controller.dart';
import 'changelog_screen.dart';
import 'quick_replies_screen.dart';
import 'software_update_screen.dart';

/// Call settings, plus a health check of everything incoming calls depend on.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _telecom = TelecomBridge.instance;
  Map<Object?, Object?> _health = const {};
  AppVersion? _version;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    AppVersion.current().then((v) {
      if (mounted) setState(() => _version = v);
    });
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

  final _tapKey = GlobalKey();
  final _simKey = GlobalKey();

  static const _tapLabels = {'details': 'Open details', 'dial': 'Write in keypad'};
  static const _simLabels = {'buttons': 'Two Call buttons', 'menu': 'Ask every time'};

  /// A row whose current choice shows on the right; tapping it opens the choices from there.
  OneUIGroupItem _choice({
    required String title,
    String? subtitle,
    required GlobalKey anchor,
    required ValueNotifier<String> value,
    required Map<String, String> labels,
    required ValueChanged<String> onPick,
  }) => OneUIGroupItem(
    title: title,
    subtitle: subtitle,
    trailing: ValueListenableBuilder(
      valueListenable: value,
      builder: (context, v, _) => Text(
        labels[v] ?? '',
        key: anchor,
        style: const TextStyle(color: OneUITheme.accentBlue, fontWeight: FontWeight.w600),
      ),
    ),
    onTap: () => OneUIFloatingMenu.show(
      context: context,
      anchorKey: anchor,
      width: 220,
      items: [
        for (final MapEntry(:key, value: label) in labels.entries)
          OneUIFloatingMenuItem(
            label: label,
            icon: key == value.value ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            onTap: () => onPick(key),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final problems = _problems;
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
            _choice(
              title: 'Tap a recent call',
              anchor: _tapKey,
              value: DialerPrefs.instance.recentTap,
              labels: _tapLabels,
              onPick: DialerPrefs.instance.setRecentTap,
            ),
            _choice(
              title: 'Choose SIM for calls',
              subtitle: 'Dual SIM with no default SIM',
              anchor: _simKey,
              value: DialerPrefs.instance.simChoice,
              labels: _simLabels,
              onPick: DialerPrefs.instance.setSimChoice,
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
              title: 'Software update',
              subtitle: _version?.label,
              trailing: ListenableBuilder(
                listenable: UpdateController.instance,
                builder: (context, _) => UpdateController.instance.updateAvailable
                    ? const SizedBox.square(
                        dimension: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: OneUITheme.accentOrange, shape: BoxShape.circle),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              onTap: () => SoftwareUpdateScreen.open(context),
            ),
            OneUIGroupItem(title: "What's new", onTap: () => ChangelogScreen.open(context)),
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
