import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/choice_row.dart';
import '../contacts/manage_contacts_screen.dart';
import '../../widgets/one_ui_toast.dart';
import '../../widgets/one_ui_group_card.dart';
import '../blocking/blocking_repository.dart';
import '../blocking/blocking_screen.dart';
import '../keypad/speed_dial_screen.dart';
import '../updates/presentation/update_controller.dart';
import 'about_screen.dart';
import 'call_settings_pages.dart';
import 'help_feedback_screen.dart';
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
  bool _bluetoothNames = true;
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
    final bluetoothNames = await Permission.bluetoothConnect.isGranted;
    if (mounted) {
      setState(() {
        _health = health;
        _bluetoothNames = bluetoothNames;
      });
    }
  }

  Future<void> _allowBluetoothNames() async {
    // Android stops asking after two refusals; then only the app's settings page can grant it.
    if (await Permission.bluetoothConnect.request().isPermanentlyDenied) await openAppSettings();
    _refresh();
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
      if (!_bluetoothNames)
        _problem('Bluetooth names hidden', "Calls can't tell your watch from your earbuds", _allowBluetoothNames),
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
            OneUIGroupItem(title: 'Incoming call reminders', onTap: () => _push(const IncomingCallRemindersScreen())),
            OneUIGroupItem(title: 'Answer buttons', onTap: () => _push(const AnswerButtonsScreen())),
            OneUIGroupItem(title: 'Answer/End calls', onTap: () => _push(const AnswerEndCallsScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: 'Caller identification',
              subtitle: 'Caller ID & spam app',
              onTap: () => _telecom.openSystemSettings('defaultApps'),
            ),
            OneUIGroupItem(title: 'Speed dial', onTap: () => _push(const SpeedDialScreen())),
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
                    Icon(Icons.chevron_right_rounded, size: 22, color: context.palette.textSecondary),
                  ],
                ),
              ),
              onTap: () => SoftwareUpdateScreen.open(context),
            ),
            OneUIGroupItem(title: 'Help & feedback', onTap: () => _push(const HelpFeedbackScreen())),
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
  final _themeKey = GlobalKey();
  final _effectsKey = GlobalKey();
  final _callEffectsKey = GlobalKey();

  static const _themeLabels = {'system': 'Same as phone', 'light': 'Light', 'dark': 'Dark'};
  static const _effectsLabels = {'full': 'Full effects', 'reduced': 'Reduced effects', 'off': 'Effects off'};
  static const _tapLabels = {'details': 'Open details', 'dial': 'Write in keypad'};

  /// "Choose SIM and call" is offered only with two SIMs; with one, a saved `sim` reads as details.
  bool _dualSim = false;

  /// Android 17 lets VoIP apps share their calls with Recents; earlier phones have no switch for it.
  bool _appCallLog = false;

  @override
  void initState() {
    super.initState();
    _telecom.getSims().then((s) {
      if (mounted) setState(() => _dualSim = s.length > 1);
    });
    _telecom.getCallHealth().then((h) {
      if (mounted) setState(() => _appCallLog = (h['sdk'] as int? ?? 0) >= 37);
    });
  }

  static const _simLabels = {'buttons': 'Two Call buttons', 'menu': 'Ask every time'};

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'More settings',
      builder: (context) => [
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: 'Tap a recent call',
              anchor: _tapKey,
              value: DialerPrefs.instance.recentTap,
              labels: _dualSim ? {..._tapLabels, 'sim': 'Choose SIM and call'} : _tapLabels,
              onPick: DialerPrefs.instance.setRecentTap,
            ),
            choiceRow(
              context,
              title: 'Choose SIM for calls',
              subtitle: 'Dual SIM with no default SIM',
              anchor: _simKey,
              value: DialerPrefs.instance.simChoice,
              labels: _simLabels,
              onPick: DialerPrefs.instance.setSimChoice,
            ),
            choiceRow(
              context,
              title: 'Appearance',
              anchor: _themeKey,
              value: DialerPrefs.instance.themeMode,
              labels: _themeLabels,
              onPick: DialerPrefs.instance.setThemeMode,
            ),
            choiceRow(
              context,
              title: 'Reduce visual effects',
              subtitle: 'Less blur runs smoother on slower phones',
              anchor: _effectsKey,
              value: DialerPrefs.instance.visualEffects,
              labels: _effectsLabels,
              onPick: DialerPrefs.instance.setVisualEffects,
            ),
            choiceRow(
              context,
              title: 'Call screen effects',
              subtitle: 'Glass and glow on the call screen',
              anchor: _callEffectsKey,
              value: DialerPrefs.instance.callEffects,
              labels: _effectsLabels,
              onPick: DialerPrefs.instance.setCallEffects,
            ),
            if (_appCallLog)
              OneUIGroupItem(
                title: 'Calls from other apps',
                subtitle: "Show WhatsApp and other apps' calls in Recents",
                onTap: () => _openSystem('voipCallLog'),
              ),
          ],
        ),
        OneUIGroupCard(
          headerTitle: 'Contacts',
          items: [
            OneUIGroupItem(
              title: 'Manage contacts',
              subtitle: 'Display, save location, import and export, SIM, duplicates',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ManageContactsScreen())),
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
