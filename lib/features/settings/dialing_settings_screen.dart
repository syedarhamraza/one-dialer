import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../keypad/keypad_screen.dart' show keypadTwoCallButtons;
import '../keypad/speed_dial_screen.dart';
import 'settings_screen.dart' show openSystemSetting;

/// Settings › Making calls › Quick calling: what a tap on a row in Calls or Contacts does, and the
/// quick-call options (call button, swipe).
class DialingSettingsScreen extends StatefulWidget {
  const DialingSettingsScreen({super.key});

  @override
  State<DialingSettingsScreen> createState() => _DialingSettingsScreenState();
}

class _DialingSettingsScreenState extends State<DialingSettingsScreen> {
  final _tapKey = GlobalKey();
  final _swipeKey = GlobalKey();
  final _buttonKey = GlobalKey();

  /// "Choose SIM and call" is offered only with two SIMs; with one, a saved `sim` reads as details.
  bool _dualSim = false;

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getSims().then((s) {
      if (mounted) setState(() => _dualSim = s.length > 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final l10n = context.l10n;
    return CosSubpage(
      title: l10n.quickCalling,
      children: [
        // What a row in Calls or Contacts does; the call options are off by default. An option a
        // tap that calls would only repeat is greyed, saying why ([DialerPrefs.tapCalls]).
        // Beta: each style picker shows while its option is on (docs/beta-only.md).
        ListenableBuilder(
          listenable: Listenable.merge([prefs.recentTap, prefs.rowCallButton, prefs.swipeToCall]),
          builder: (context, _) => Column(
            children: [
              OneUIGroupCard(
                headerTitle: l10n.callsRows,
                items: [
                  choiceRow(
                    context,
                    title: l10n.tapRecentCall,
                    subtitle: l10n.tapRecentCallSubtitle,
                    anchor: _tapKey,
                    value: prefs.recentTap,
                    labels: {
                      'details': l10n.openDetails,
                      'dial': l10n.writeInKeypad,
                      'call': l10n.call,
                      if (_dualSim) 'sim': l10n.chooseSimAndCall,
                    },
                    onPick: prefs.setRecentTap,
                  ),
                  switchRow(
                    l10n.rowCallButton,
                    prefs.rowCallButton,
                    prefs.setRowCallButton,
                    subtitle: prefs.tapCalls ? l10n.tapAlreadyCalls : l10n.rowCallButtonSubtitle,
                    enabled: !prefs.tapCalls,
                  ),
                  if (prefs.rowCallButton.value && !prefs.tapCalls)
                    choiceRow(
                      context,
                      title: l10n.callButtonStyle,
                      anchor: _buttonKey,
                      value: prefs.callButtonStyle,
                      labels: {
                        'tint': l10n.callButtonTint,
                        'glyph': l10n.callButtonGlyph,
                        'glass': l10n.callButtonGlass,
                        'lit': l10n.callButtonLit,
                        'pill': l10n.callButtonPill,
                      },
                      onPick: prefs.setCallButtonStyle,
                    ),
                ],
              ),
              OneUIGroupCard(
                headerTitle: l10n.callsAndContactsRows,
                items: [
                  switchRow(
                    l10n.swipeToCall,
                    prefs.swipeToCall,
                    prefs.setSwipeToCall,
                    subtitle: l10n.swipeToCallSubtitle,
                  ),
                  if (prefs.swipeToCall.value)
                    choiceRow(
                      context,
                      title: l10n.swipeStyle,
                      anchor: _swipeKey,
                      value: prefs.swipeStyle,
                      labels: {'pill': l10n.swipeStylePill, 'flat': l10n.swipeStyleFlat},
                      onPick: prefs.setSwipeStyle,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Settings › Making calls › SIM cards: which SIM calls use on a dual SIM phone, over Android's
/// own default, and whether the keypad offers one Call button per SIM when calls ask.
class SimSettingsScreen extends StatefulWidget {
  const SimSettingsScreen({super.key});

  /// The choices for [DialerPrefs.simChoice]; Settings shows the picked one as the row's value.
  static Map<String, String> choiceLabels(AppLocalizations l10n, List<SimCard> sims) => {
    'phone': l10n.simSameAsPhone,
    'menu': l10n.askEveryTime,
    'recent': l10n.useRecentSim,
    for (final sim in sims) 'sim:${sim.id}': l10n.alwaysSim(sim.label),
  };

  @override
  State<SimSettingsScreen> createState() => _SimSettingsScreenState();
}

class _SimSettingsScreenState extends State<SimSettingsScreen> with WidgetsBindingObserver {
  final _simKey = GlobalKey();
  List<SimCard> _sims = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from Android's SIM settings: its default may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final sims = await TelecomBridge.instance.getSims();
    if (mounted) setState(() => _sims = sims);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final l10n = context.l10n;
    final phoneDefault = _sims.where((s) => s.isDefault).firstOrNull;
    return CosSubpage(
      title: l10n.simCards,
      children: [
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: l10n.chooseSimForCalls,
              anchor: _simKey,
              value: prefs.simChoice,
              labels: SimSettingsScreen.choiceLabels(l10n, _sims),
              onPick: prefs.setSimChoice,
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: l10n.phoneDefaultSim,
              value: phoneDefault?.label ?? l10n.askEveryTime,
              onTap: () => openSystemSetting(context, 'sim'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text(l10n.simRulesHint, style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
        ),
      ],
    );
  }
}

/// Settings › Making calls › Keypad: the keypad's own choices, apart from SIM cards.
class KeypadSettingsScreen extends StatefulWidget {
  const KeypadSettingsScreen({super.key});

  @override
  State<KeypadSettingsScreen> createState() => _KeypadSettingsScreenState();
}

class _KeypadSettingsScreenState extends State<KeypadSettingsScreen> {
  List<SimCard> _sims = const [];

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getSims().then((s) {
      if (mounted) setState(() => _sims = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final l10n = context.l10n;
    final dual = _sims.length > 1;
    return CosSubpage(
      title: l10n.keypadSettings,
      children: [
        // Shows what the keypad does now, including before it's been chosen ([keypadTwoCallButtons]).
        ListenableBuilder(
          listenable: Listenable.merge([prefs.keypadSimButtons, prefs.simChoice]),
          builder: (context, _) => OneUIGroupCard(
            items: [
              switchRow(
                l10n.keypadSimButtons,
                ValueNotifier(keypadTwoCallButtons(_sims)),
                prefs.setKeypadSimButtons,
                subtitle: dual ? l10n.keypadSimButtonsSubtitle : l10n.keypadSimButtonsOneSim,
                enabled: dual,
              ),
              OneUIGroupItem(
                title: l10n.speedDial,
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpeedDialScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
