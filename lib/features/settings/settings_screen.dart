import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_subpage.dart';
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
import 'app_icon_screen.dart';
import 'call_recording_screen.dart';
import 'call_settings_pages.dart';
import 'dialing_settings_screen.dart';
import 'display_settings_screen.dart';
import 'help_feedback_screen.dart';
import 'software_update_screen.dart';
import '../../l10n/l10n.dart';

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

  /// One Dialer Recorder (the sideloaded companion); null when it isn't installed.
  RecorderInfo? _recorder;
  AppVersion? _version;
  String _icon = 'default';

  /// Android 17 lets VoIP apps share their calls with Recents; earlier phones have no switch for it.
  bool get _appCallLog => (_health['sdk'] as int? ?? 0) >= 37;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _loadIcon();
    // Their values show on the Display and Language rows.
    DialerPrefs.instance.themeMode.addListener(_rebuild);
    DialerPrefs.instance.language.addListener(_rebuild);
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
    DialerPrefs.instance.themeMode.removeListener(_rebuild);
    DialerPrefs.instance.language.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _loadIcon() => _telecom.getLauncherIcon().then((s) {
    if (mounted) setState(() => _icon = s);
  });

  Future<void> _refresh() async {
    final health = await _telecom.getCallHealth();
    final bluetoothNames = await Permission.bluetoothConnect.isGranted;
    final recorder = await _telecom.getRecorder();
    if (mounted) {
      setState(() {
        _health = health;
        _recorder = recorder;
        _bluetoothNames = bluetoothNames;
      });
    }
  }

  Future<void> _allowBluetoothNames() async {
    // Android stops asking after two refusals; then only the app's settings page can grant it.
    if (await Permission.bluetoothConnect.request().isPermanentlyDenied) await openAppSettings();
    _refresh();
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  /// Rows only for problems; empty when everything incoming calls need is in place.
  List<OneUIGroupItem> get _problems {
    if (_health.isEmpty) return const [];
    final rules = BlockingRepository.instance.rules.value;
    return [
      if (_health['isDefaultDialer'] != true)
        _problem(context.l10n.notDefaultApp, context.l10n.notDefaultAppSubtitle, () async {
          await _telecom.requestDefaultDialer();
          _refresh();
        }),
      if (_health['notificationsEnabled'] != true)
        _problem(
          context.l10n.notificationsOff,
          context.l10n.notificationsOffSubtitle,
          () => _telecom.openSystemSettings('notifications'),
        ),
      if (_health['fullScreenAllowed'] != true)
        _problem(
          context.l10n.fullScreenOff,
          context.l10n.fullScreenOffSubtitle,
          () => _telecom.openSystemSettings('fullScreen'),
        ),
      if ((rules.blockHidden || rules.blockNonContacts) && _health['screensCalls'] != true)
        _problem(context.l10n.blockingPaused, context.l10n.blockingPausedShort, () => _push(const BlockingScreen())),
      // Auto-record is on but the companion can't record (its setup was undone).
      if (_recorder case final r? when r.autoRecord && r.consented && !r.ready)
        _problem(context.l10n.recordingNotSetUp, context.l10n.recordingNotSetUpSubtitle, () => _push(const CallRecordingScreen())),
      if (!_bluetoothNames)
        _problem(context.l10n.bluetoothNamesHidden, context.l10n.bluetoothNamesHiddenSubtitle, _allowBluetoothNames),
    ];
  }

  OneUIGroupItem _problem(String title, String subtitle, VoidCallback onFix) => OneUIGroupItem(
    leading: const Icon(Icons.warning_amber_rounded, color: OneUITheme.accentRed),
    title: title,
    subtitle: subtitle,
    subtitleColor: OneUITheme.accentRed,
    onTap: onFix,
    value: context.l10n.fix,
  );

  @override
  Widget build(BuildContext context) {
    final problems = _problems;
    final l10n = context.l10n;
    // Grouped like ColorOS's Settings: one titled card per topic.
    return OneUISubpage(
      title: l10n.callSettings,
      builder: (context) => [
        if (problems.isNotEmpty) OneUIGroupCard(headerTitle: l10n.needsAttention, items: problems),
        OneUIGroupCard(
          headerTitle: l10n.settingsCalls,
          items: [
            OneUIGroupItem(title: l10n.incomingCallReminders, onTap: () => _push(const IncomingCallRemindersScreen())),
            OneUIGroupItem(title: l10n.answerButtons, onTap: () => _push(const AnswerButtonsScreen())),
            OneUIGroupItem(title: l10n.answerEndCalls, onTap: () => _push(const AnswerEndCallsScreen())),
            // Only with One Dialer Recorder installed (the sideloaded companion); the Play app can't record alone.
            if (_recorder != null)
              OneUIGroupItem(
                title: l10n.callRecording,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const CallRecordingScreen()))
                    .then((_) => _refresh()),
              ),
          ],
        ),
        OneUIGroupCard(
          headerTitle: l10n.settingsDialing,
          items: [
            OneUIGroupItem(title: l10n.keypadAndRecents, onTap: () => _push(const DialingSettingsScreen())),
            OneUIGroupItem(title: l10n.speedDial, onTap: () => _push(const SpeedDialScreen())),
          ],
        ),
        OneUIGroupCard(
          headerTitle: l10n.settingsSpamBlocking,
          items: [
            OneUIGroupItem(title: l10n.blockAndFilter, onTap: () => _push(const BlockingScreen())),
            OneUIGroupItem(
              title: l10n.callerIdentification,
              subtitle: l10n.callerIdSpamApp,
              onTap: () => _telecom.openSystemSettings('defaultApps'),
            ),
          ],
        ),
        OneUIGroupCard(
          headerTitle: l10n.settingsPersonalisation,
          items: [
            OneUIGroupItem(
              title: l10n.displayAndEffects,
              value: DisplaySettingsScreen.themeLabels(l10n)[DialerPrefs.instance.themeMode.value],
              onTap: () => _push(const DisplaySettingsScreen()),
            ),
            OneUIGroupItem(
              title: l10n.appIcon,
              value: AppIconScreen.labels(l10n)[_icon],
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const AppIconScreen()))
                      .then((_) => _loadIcon()),
            ),
          ],
        ),
        OneUIGroupCard(
          headerTitle: l10n.settingsGeneral,
          items: [
            OneUIGroupItem(
              title: l10n.settingsLanguageHeader,
              value: _languageLabels(l10n)[DialerPrefs.instance.language.value],
              onTap: () => _push(const _LanguageScreen()),
            ),
            OneUIGroupItem(title: l10n.navContacts, onTap: () => _push(const _ContactsSettingsScreen())),
            OneUIGroupItem(title: l10n.notifications, onTap: () => _telecom.openSystemSettings('notifications')),
            OneUIGroupItem(title: l10n.defaultApps, onTap: () => _telecom.openSystemSettings('defaultApps')),
            OneUIGroupItem(title: l10n.carrierSettings, onTap: () => openSystemSetting(context, 'carrier')),
            if (_appCallLog)
              OneUIGroupItem(
                title: l10n.callsFromOtherApps,
                subtitle: l10n.callsFromOtherAppsSubtitle,
                onTap: () => openSystemSetting(context, 'voipCallLog'),
              ),
          ],
        ),
        OneUIGroupCard(
          headerTitle: l10n.settingsAbout,
          items: [
            OneUIGroupItem(
              title: l10n.softwareUpdate,
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
            OneUIGroupItem(title: l10n.helpFeedback, onTap: () => _push(const HelpFeedbackScreen())),
            OneUIGroupItem(
              title: l10n.privacyPolicy,
              onTap: () => _telecom.openSystemSettings('url:${AppInfo.privacyPolicyUrl}'),
            ),
            OneUIGroupItem(title: l10n.aboutOneDialer, onTap: () => _push(const AboutScreen())),
          ],
        ),
      ],
    );
  }
}

/// A system screen that not every phone has (carrier settings, Contacts storage, Google's sync).
Future<void> openSystemSetting(BuildContext context, String page) async {
  try {
    await TelecomBridge.instance.openSystemSettings(page);
  } on PlatformException {
    if (context.mounted) OneUIToast.show(context, context.l10n.settingNotAvailable);
  }
}

/// Each language named in itself, so a new app_xx.arb shows up here on its own.
Map<String, String> _languageLabels(AppLocalizations l10n) => {
  'system': l10n.settingsLanguageSystem,
  for (final locale in AppLocalizations.supportedLocales)
    locale.languageCode: lookupAppLocalizations(locale).languageName,
};

/// Settings › Language: the app's own language, or Android's per-app page for it.
class _LanguageScreen extends StatefulWidget {
  const _LanguageScreen();

  @override
  State<_LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<_LanguageScreen> {
  final _languageKey = GlobalKey();

  @override
  Widget build(BuildContext context) => CosSubpage(
    title: context.l10n.settingsLanguageHeader,
    children: [
      OneUIGroupCard(
        items: [
          choiceRow(
            context,
            title: context.l10n.settingsAppLanguage,
            subtitle: context.l10n.settingsAppLanguageSubtitle,
            anchor: _languageKey,
            value: DialerPrefs.instance.language,
            labels: _languageLabels(context.l10n),
            onPick: DialerPrefs.instance.setLanguage,
          ),
          OneUIGroupItem(
            title: context.l10n.settingsAndroidLanguage,
            subtitle: context.l10n.settingsAndroidLanguageSubtitle,
            onTap: () => openSystemSetting(context, 'language'),
          ),
        ],
      ),
    ],
  );
}

/// Settings › Contacts: which contacts show, and where they're stored and synced.
class _ContactsSettingsScreen extends StatelessWidget {
  const _ContactsSettingsScreen();

  @override
  Widget build(BuildContext context) => CosSubpage(
    title: context.l10n.navContacts,
    children: [
      OneUIGroupCard(
        items: [
          OneUIGroupItem(
            title: context.l10n.manageContacts,
            subtitle: context.l10n.manageContactsSubtitle,
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ManageContactsScreen())),
          ),
          OneUIGroupItem(
            title: context.l10n.googleContactsSync,
            subtitle: context.l10n.googleContactsSyncSubtitle,
            onTap: () => openSystemSetting(context, 'googleContactsSync'),
          ),
        ],
      ),
    ],
  );
}
