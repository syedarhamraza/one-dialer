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
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: l10n.tapRecentCall,
              anchor: _tapKey,
              value: prefs.recentTap,
              labels: {
                'details': l10n.openDetails,
                'dial': l10n.writeInKeypad,
                if (_dualSim) 'sim': l10n.chooseSimAndCall,
              },
              onPick: prefs.setRecentTap,
            ),
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
