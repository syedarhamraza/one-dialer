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
      if (mounted) OneUIToast.show(context, context.l10n.settingNotAvailable);
    }
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
    // Grouped like ColorOS's Call settings; the rarely changed rest is under More settings.
    return OneUISubpage(
      title: context.l10n.callSettings,
      builder: (context) => [
        if (problems.isNotEmpty) OneUIGroupCard(headerTitle: context.l10n.needsAttention, items: problems),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: context.l10n.incomingCallReminders,
              onTap: () => _push(const IncomingCallRemindersScreen()),
            ),
            OneUIGroupItem(title: context.l10n.answerButtons, onTap: () => _push(const AnswerButtonsScreen())),
            OneUIGroupItem(title: context.l10n.answerEndCalls, onTap: () => _push(const AnswerEndCallsScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: context.l10n.callerIdentification,
              subtitle: context.l10n.callerIdSpamApp,
              onTap: () => _telecom.openSystemSettings('defaultApps'),
            ),
            OneUIGroupItem(title: context.l10n.speedDial, onTap: () => _push(const SpeedDialScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [OneUIGroupItem(title: context.l10n.blockAndFilter, onTap: () => _push(const BlockingScreen()))],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(title: context.l10n.carrierSettings, onTap: () => _openSystem('carrier')),
            OneUIGroupItem(title: context.l10n.moreSettings, onTap: () => _push(const _MoreSettingsScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: context.l10n.softwareUpdate,
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
            OneUIGroupItem(title: context.l10n.helpFeedback, onTap: () => _push(const HelpFeedbackScreen())),
            OneUIGroupItem(
              title: context.l10n.privacyPolicy,
              onTap: () => _telecom.openSystemSettings('url:${AppInfo.privacyPolicyUrl}'),
            ),
            OneUIGroupItem(title: context.l10n.aboutOneDialer, onTap: () => _push(const AboutScreen())),
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
      if (mounted) OneUIToast.show(context, context.l10n.settingNotAvailable);
    }
  }

  final _tapKey = GlobalKey();
  final _simKey = GlobalKey();
  final _themeKey = GlobalKey();
  final _effectsKey = GlobalKey();
  final _languageKey = GlobalKey();
  final _glassDarkKey = GlobalKey();
  final _glassLightKey = GlobalKey();

  static Map<String, String> _themeLabels(AppLocalizations l10n) => {
    'system': l10n.settingsLanguageSystem,
    'light': l10n.themeLight,
    'dark': l10n.themeDark,
  };
  static Map<String, String> _tapLabels(AppLocalizations l10n) => {
    'details': l10n.openDetails,
    'dial': l10n.writeInKeypad,
  };

  /// "Choose SIM and call" is offered only with two SIMs; with one, a saved `sim` reads as details.
  bool _dualSim = false;

  /// Android 17 lets VoIP apps share their calls with Recents; earlier phones have no switch for it.
  bool _appCallLog = false;

  @override
  void initState() {
    super.initState();
    DialerPrefs.instance.visualEffects.addListener(_rebuild);
    _telecom.getSims().then((s) {
      if (mounted) setState(() => _dualSim = s.length > 1);
    });
    _telecom.getCallHealth().then((h) {
      if (mounted) setState(() => _appCallLog = (h['sdk'] as int? ?? 0) >= 37);
    });
  }

  @override
  void dispose() {
    DialerPrefs.instance.visualEffects.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  static Map<String, String> _simLabels(AppLocalizations l10n) => {
    'buttons': l10n.twoCallButtons,
    'menu': l10n.askEveryTime,
  };

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: context.l10n.moreSettings,
      builder: (context) => [
        OneUIGroupCard(
          headerTitle: context.l10n.settingsLanguageHeader,
          items: [
            choiceRow(
              context,
              title: context.l10n.settingsAppLanguage,
              subtitle: context.l10n.settingsAppLanguageSubtitle,
              anchor: _languageKey,
              value: DialerPrefs.instance.language,
              // Each language named in itself, so a new app_xx.arb shows up here on its own.
              labels: {
                'system': context.l10n.settingsLanguageSystem,
                for (final locale in AppLocalizations.supportedLocales)
                  locale.languageCode: lookupAppLocalizations(locale).languageName,
              },
              onPick: DialerPrefs.instance.setLanguage,
            ),
            OneUIGroupItem(
              title: context.l10n.settingsAndroidLanguage,
              subtitle: context.l10n.settingsAndroidLanguageSubtitle,
              onTap: () => _openSystem('language'),
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: context.l10n.tapRecentCall,
              anchor: _tapKey,
              value: DialerPrefs.instance.recentTap,
              labels: {..._tapLabels(context.l10n), if (_dualSim) 'sim': context.l10n.chooseSimAndCall},
              onPick: DialerPrefs.instance.setRecentTap,
            ),
            choiceRow(
              context,
              title: context.l10n.chooseSimForCalls,
              subtitle: context.l10n.chooseSimSubtitle,
              anchor: _simKey,
              value: DialerPrefs.instance.simChoice,
              labels: _simLabels(context.l10n),
              onPick: DialerPrefs.instance.setSimChoice,
            ),
            choiceRow(
              context,
              title: context.l10n.appearance,
              anchor: _themeKey,
              value: DialerPrefs.instance.themeMode,
              labels: _themeLabels(context.l10n),
              onPick: DialerPrefs.instance.setThemeMode,
            ),
            choiceRow(
              context,
              title: context.l10n.reduceVisualEffects,
              subtitle: context.l10n.reduceVisualEffectsSubtitle,
              anchor: _effectsKey,
              value: DialerPrefs.instance.visualEffects,
              labels: effectsLabels(context.l10n),
              onPick: DialerPrefs.instance.setVisualEffects,
            ),
            // The glass styles only change the full-effects glass; below it the rows go away.
            if (DialerPrefs.instance.visualEffects.value == 'full') ...[
              choiceRow(
                context,
                title: context.l10n.darkModeEdgeGlow,
                anchor: _glassDarkKey,
                value: DialerPrefs.instance.glassDark,
                labels: edgeGlowLabels(context.l10n),
                onPick: DialerPrefs.instance.setGlassDark,
              ),
              choiceRow(
                context,
                title: context.l10n.lightModeEdgeGlow,
                anchor: _glassLightKey,
                value: DialerPrefs.instance.glassLight,
                labels: edgeGlowLabels(context.l10n),
                onPick: DialerPrefs.instance.setGlassLight,
              ),
            ],
            if (_appCallLog)
              OneUIGroupItem(
                title: context.l10n.callsFromOtherApps,
                subtitle: context.l10n.callsFromOtherAppsSubtitle,
                onTap: () => _openSystem('voipCallLog'),
              ),
          ],
        ),
        OneUIGroupCard(
          headerTitle: context.l10n.navContacts,
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
              onTap: () => _openSystem('googleContactsSync'),
            ),
            OneUIGroupItem(title: context.l10n.defaultApps, onTap: () => _telecom.openSystemSettings('defaultApps')),
            OneUIGroupItem(
              title: context.l10n.notifications,
              onTap: () => _telecom.openSystemSettings('notifications'),
            ),
          ],
        ),
      ],
    );
  }
}
