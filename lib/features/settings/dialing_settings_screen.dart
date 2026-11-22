import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';

/// Settings › Making calls › Quick calling: what a tap on a row in Calls or Contacts does, and the
/// quick-call options (call button, swipe, double-tap).
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
        // What a row in Calls or Contacts does; the call options are off by default.
        // Beta: each style picker shows while its option is on (docs/beta-only.md).
        ListenableBuilder(
          listenable: Listenable.merge([prefs.rowCallButton, prefs.swipeToCall]),
          builder: (context, _) => OneUIGroupCard(
            headerTitle: l10n.callsAndContactsRows,
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
                subtitle: l10n.rowCallButtonSubtitle,
              ),
              if (prefs.rowCallButton.value)
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
              switchRow(l10n.swipeToCall, prefs.swipeToCall, prefs.setSwipeToCall, subtitle: l10n.swipeToCallSubtitle),
              if (prefs.swipeToCall.value)
                choiceRow(
                  context,
                  title: l10n.swipeStyle,
                  anchor: _swipeKey,
                  value: prefs.swipeStyle,
                  labels: {'pill': l10n.swipeStylePill, 'flat': l10n.swipeStyleFlat},
                  onPick: prefs.setSwipeStyle,
                ),
              switchRow(
                l10n.doubleTapCall,
                prefs.doubleTapCall,
                prefs.setDoubleTapCall,
                subtitle: l10n.doubleTapCallSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Settings › Making calls › SIM cards: how a dual SIM phone with no default SIM picks one.
class SimSettingsScreen extends StatefulWidget {
  const SimSettingsScreen({super.key});

  /// Settings' summary of [DialerPrefs.simChoice].
  static Map<String, String> choiceLabels(AppLocalizations l10n) => {
    'buttons': l10n.twoCallButtons,
    'menu': l10n.askEveryTime,
    'recent': l10n.useRecentSim,
  };

  @override
  State<SimSettingsScreen> createState() => _SimSettingsScreenState();
}

class _SimSettingsScreenState extends State<SimSettingsScreen> {
  final _simKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final l10n = context.l10n;
    return CosSubpage(
      title: l10n.simCards,
      children: [
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: l10n.chooseSimForCalls,
              subtitle: l10n.chooseSimSubtitle,
              anchor: _simKey,
              value: prefs.simChoice,
              labels: SimSettingsScreen.choiceLabels(l10n),
              onPick: prefs.setSimChoice,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text(l10n.useRecentSimHint, style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
        ),
      ],
    );
  }
}
