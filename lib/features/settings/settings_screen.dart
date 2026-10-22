import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_group_card.dart';
import '../blocking/blocking_repository.dart';
import '../blocking/blocking_screen.dart';
import '../keypad/speed_dial_screen.dart';
import '../updates/presentation/update_controller.dart';
import 'about_screen.dart';
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

  /// A system screen that not every phone has (Contacts storage, Google's sync).
  Future<void> _openSystem(String page) async {
    try {
      await _telecom.openSystemSettings(page);
    } on PlatformException {
      if (mounted) OneUIToast.show(context, "This phone doesn't have that setting");
    }
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
    value: 'Fix',
  );

  @override
  Widget build(BuildContext context) {
    final problems = _problems;
    // Grouped like ColorOS's Call settings; the rarely changed rest is under More settings.
    return OneUISubpage(
      title: 'Call settings',
      builder: (context) => [
        if (problems.isNotEmpty) OneUIGroupCard(headerTitle: 'Needs attention', items: problems),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: 'Caller identification',
              subtitle: 'Caller ID & spam app',
              onTap: () => _telecom.openSystemSettings('defaultApps'),
            ),
            OneUIGroupItem(title: 'Speed dial', onTap: () => _push(const SpeedDialScreen())),
            OneUIGroupItem(title: 'Decline with message', onTap: () => _push(const QuickRepliesScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [OneUIGroupItem(title: 'Block & filter', onTap: () => _push(const BlockingScreen()))],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(title: 'Carrier-related settings', onTap: () => _openSystem('carrier')),
            OneUIGroupItem(title: 'More settings', onTap: () => _push(const _MoreSettingsScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: 'Software update',
              value: _version?.label,
              trailing: ListenableBuilder(
                listenable: UpdateController.instance,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (UpdateController.instance.updateAvailable) ...[const OneUIDot(), const SizedBox(width: 6)],
                    const Icon(Icons.chevron_right_rounded, size: 22, color: OneUITheme.textSecondary),
                  ],
                ),
              ),
              onTap: () => SoftwareUpdateScreen.open(context),
            ),
            OneUIGroupItem(title: "What's new", onTap: () => ChangelogScreen.open(context)),
            OneUIGroupItem(
              title: 'Privacy policy',
              onTap: () => _telecom.openSystemSettings('url:${AppInfo.privacyPolicyUrl}'),
            ),
            OneUIGroupItem(title: 'About One Dialer', onTap: () => _push(const AboutScreen())),
          ],
        ),
      ],
    );
  }
}

/// Settings › More settings: how taps and SIMs behave, contacts storage, and About.
class _MoreSettingsScreen extends StatefulWidget {
  const _MoreSettingsScreen();

  @override
  State<_MoreSettingsScreen> createState() => _MoreSettingsScreenState();
}

class _MoreSettingsScreenState extends State<_MoreSettingsScreen> {
  final _telecom = TelecomBridge.instance;

  /// A system screen that not every phone has (Contacts storage, Google's sync).
  Future<void> _openSystem(String page) async {
    try {
      await _telecom.openSystemSettings(page);
    } on PlatformException {
      if (mounted) OneUIToast.show(context, "This phone doesn't have that setting");
    }
  }

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
    // The choice in grey before a chevron, as ColorOS settings show values.
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: value,
          builder: (context, v, _) => Text(
            labels[v] ?? '',
            key: anchor,
            style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 22, color: OneUITheme.textSecondary),
      ],
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
    return OneUISubpage(
      title: 'More settings',
      builder: (context) => [
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
          headerTitle: 'Contacts',
          items: [
            OneUIGroupItem(
              title: 'Default account for new contacts',
              subtitle: 'Phone, SIM or Google',
              onTap: () => _openSystem('contactsStorage'),
            ),
            OneUIGroupItem(
              title: 'Google Contacts sync',
              subtitle: 'Which accounts sync, and backing up phone contacts',
              onTap: () => _openSystem('googleContactsSync'),
            ),
            OneUIGroupItem(title: 'Default apps', onTap: () => _telecom.openSystemSettings('defaultApps')),
            OneUIGroupItem(title: 'Notifications', onTap: () => _telecom.openSystemSettings('notifications')),
          ],
        ),
      ],
    );
  }
}
