import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';

/// Settings › Keypad & recents: what a tap on a recent call does, and how dual SIM phones
/// pick a SIM.
class DialingSettingsScreen extends StatefulWidget {
  const DialingSettingsScreen({super.key});

  @override
  State<DialingSettingsScreen> createState() => _DialingSettingsScreenState();
}

class _DialingSettingsScreenState extends State<DialingSettingsScreen> {
  final _tapKey = GlobalKey();
  final _simKey = GlobalKey();

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
      title: l10n.keypadAndRecents,
      children: [
        // What a row in Calls or Contacts does; the call options are off by default.
        OneUIGroupCard(
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
            switchRow(l10n.rowCallButton, prefs.rowCallButton, prefs.setRowCallButton, subtitle: l10n.rowCallButtonSubtitle),
            switchRow(l10n.swipeToCall, prefs.swipeToCall, prefs.setSwipeToCall, subtitle: l10n.swipeToCallSubtitle),
            switchRow(l10n.doubleTapCall, prefs.doubleTapCall, prefs.setDoubleTapCall, subtitle: l10n.doubleTapCallSubtitle),
          ],
        ),
        OneUIGroupCard(
          headerTitle: l10n.simCards,
          items: [
            choiceRow(
              context,
              title: l10n.chooseSimForCalls,
              subtitle: l10n.chooseSimSubtitle,
              anchor: _simKey,
              value: prefs.simChoice,
              labels: {'buttons': l10n.twoCallButtons, 'menu': l10n.askEveryTime},
              onPick: prefs.setSimChoice,
            ),
          ],
        ),
      ],
    );
  }
}
