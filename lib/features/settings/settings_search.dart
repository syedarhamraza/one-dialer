import 'package:flutter/material.dart';

import '../../app/app_info.dart';
import '../../app/layout.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/search_bar_row.dart';
import '../blocking/blocking_screen.dart';
import '../keypad/speed_dial_screen.dart';
import 'about_screen.dart';
import 'backup_screen.dart';
import 'call_recording_screen.dart';
import 'call_settings_pages.dart';
import 'dialing_settings_screen.dart';
import 'display_settings_screen.dart';
import 'glass_settings_screen.dart';
import 'help_feedback_screen.dart';
import 'quick_replies_screen.dart';
import 'settings_screen.dart';
import 'software_update_screen.dart';
import 'vip_calls_screen.dart';

/// One searchable setting: a page, or a row on one, and where it lives.
class SettingsEntry {
  const SettingsEntry(this.title, this.path, this.open, {this.subtitle});

  final String title, path;
  final String? subtitle;
  final void Function(BuildContext context) open;
}

/// Everything Settings › Search finds. Adding a setting means adding its line here, under the
/// page it lives on; a row that only shows under a condition is listed only while it shows.
List<SettingsEntry> settingsIndex(AppLocalizations l10n, {bool recorder = false, bool appCallLog = false}) {
  void Function(BuildContext) page(Widget w) =>
      (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));
  void Function(BuildContext) system(String name) =>
      (c) => openSystemSetting(c, name);
  final entries = <SettingsEntry>[];
  // A page under [section], with the rows on it.
  void add(String section, String title, void Function(BuildContext) open, {String? subtitle, List<String>? rows}) {
    entries.add(SettingsEntry(title, section, open, subtitle: subtitle));
    for (final row in rows ?? const <String>[]) {
      entries.add(SettingsEntry(row, '$section › $title', open));
    }
  }

  final calls = l10n.sectionCalls;
  add(
    calls,
    l10n.incomingCallReminders,
    page(const IncomingCallRemindersScreen()),
    subtitle: l10n.incomingCallsSubtitle,
    rows: [l10n.answerFromBanner, l10n.announceCalls, l10n.liveUpdateCapsule, l10n.flashOnCall],
  );
  add(
    calls,
    l10n.answerButtons,
    page(const AnswerButtonsScreen()),
    subtitle: l10n.answerButtonsSubtitle,
    rows: [
      l10n.callScreenEffects,
      l10n.callScreenAnimations,
      l10n.hideContactNumbers,
      l10n.callerPhoto,
      l10n.callBackground,
    ],
  );
  add(
    calls,
    l10n.answerEndCalls,
    page(const AnswerEndCallsScreen()),
    subtitle: l10n.answerEndCallsSubtitle,
    rows: [l10n.vibrateAnswerEnd, l10n.autoAnswer, l10n.speakerDefault],
  );
  entries.add(SettingsEntry(l10n.replyWithSms, '$calls › ${l10n.answerEndCalls}', page(const QuickRepliesScreen())));
  add(
    calls,
    l10n.vipCalls,
    page(const VipCallsScreen()),
    subtitle: l10n.vipCallsSubtitle,
    rows: [l10n.vipRing, l10n.vipFavourites, l10n.vipContacts],
  );
  if (recorder) add(calls, l10n.callRecording, page(const CallRecordingScreen()));

  final making = l10n.sectionMakingCalls;
  add(making, l10n.simCards, page(const SimSettingsScreen()), rows: [l10n.chooseSimForCalls]);
  add(
    making,
    l10n.quickCalling,
    page(const DialingSettingsScreen()),
    subtitle: l10n.quickCallingSubtitle,
    rows: [l10n.tapRecentCall, l10n.rowCallButton, l10n.swipeToCall, l10n.doubleTapCall],
  );
  add(making, l10n.speedDial, page(const SpeedDialScreen()));

  final blocking = l10n.sectionBlocking;
  add(blocking, l10n.blockAndFilter, page(const BlockingScreen()), rows: [l10n.blockUnknown, l10n.blockNonContacts]);
  add(blocking, l10n.callerIdentification, system('defaultApps'), subtitle: l10n.callerIdSpamApp);

  final display = l10n.sectionDisplay;
  add(
    display,
    l10n.displayAndEffects,
    page(const DisplaySettingsScreen()),
    rows: [l10n.appearance, l10n.reduceVisualEffects, l10n.displaySize],
  );
  if (DialerPrefs.instance.visualEffects.value == 'full') {
    entries.add(
      SettingsEntry(l10n.glassSettings, '$display › ${l10n.displayAndEffects}', page(const GlassSettingsScreen())),
    );
  }
  add(display, l10n.settingsLanguageHeader, page(const LanguageScreen()), rows: [l10n.settingsAppLanguage]);

  final sys = l10n.sectionSystem;
  add(
    sys,
    l10n.navContacts,
    page(const ContactsSettingsScreen()),
    rows: [l10n.manageContacts, l10n.googleContactsSync],
  );
  add(sys, l10n.notifications, system('notifications'));
  add(sys, l10n.defaultApps, system('defaultApps'));
  add(sys, l10n.carrierSettings, system('carrier'), subtitle: l10n.carrierSettingsSubtitle);
  if (appCallLog) add(sys, l10n.callsFromOtherApps, system('voipCallLog'), subtitle: l10n.callsFromOtherAppsSubtitle);
  add(
    sys,
    l10n.backUpRestore,
    page(const BackupScreen()),
    subtitle: l10n.backUpRestoreSubtitle,
    rows: [l10n.backUpNow, l10n.autoBackup],
  );

  final top = l10n.callSettings;
  add(top, l10n.softwareUpdate, SoftwareUpdateScreen.open);
  add(top, l10n.helpFeedback, page(const HelpFeedbackScreen()));
  add(top, l10n.privacyPolicy, (_) => TelecomBridge.instance.openSystemSettings('url:${AppInfo.privacyPolicyUrl}'));
  add(top, l10n.aboutOneDialer, page(const AboutScreen()));
  return entries;
}

/// The glass search pill at the top of Settings; opens [SettingsSearchScreen].
class SettingsSearchPill extends StatelessWidget {
  const SettingsSearchPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Semantics(
      button: true,
      child: CallGlass(
        radius: 24,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 26, color: context.palette.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.searchSettings,
                    style: TextStyle(fontSize: 17, color: context.palette.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Settings › Search: the field across the top (as Calls search), matches as title over path.
class SettingsSearchScreen extends StatefulWidget {
  const SettingsSearchScreen({super.key, this.recorder = false, this.appCallLog = false});

  final bool recorder, appCallLog;

  @override
  State<SettingsSearchScreen> createState() => _SettingsSearchScreenState();
}

class _SettingsSearchScreenState extends State<SettingsSearchScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final l10n = context.l10n;
    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: _query,
            builder: (context, value, _) {
              final q = value.text.trim().toLowerCase();
              final hits = q.isEmpty
                  ? const <SettingsEntry>[]
                  : settingsIndex(l10n, recorder: widget.recorder, appCallLog: widget.appCallLog)
                        .where(
                          (e) => e.title.toLowerCase().contains(q) || (e.subtitle?.toLowerCase().contains(q) ?? false),
                        )
                        .toList();
              return CustomScrollView(
                physics: const OneUIScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      padding.top + 8 + 48 * headerScale(context) + 16,
                      0,
                      padding.bottom + 32,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: q.isEmpty
                          ? const SizedBox.shrink()
                          : hits.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: Text(
                                l10n.noResultsFound,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: context.palette.textSecondary),
                              ),
                            )
                          : OneUIGroupCard(
                              items: [
                                for (final e in hits)
                                  OneUIGroupItem(title: e.title, subtitle: e.path, onTap: () => e.open(context)),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Positioned(left: 0, right: 0, top: 0, child: OneUIStatusBarScrim()),
          Positioned(
            left: 16,
            right: 16,
            top: padding.top + 8,
            child: HeaderScaled(
              child: SearchBarRow(
                controller: _query,
                hint: l10n.searchSettings,
                onCancel: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
