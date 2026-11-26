import 'package:flutter/material.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import 'call_recording_screen.dart' show RecordContactsScreen;

/// Settings › VIP calls: VIPs ring even on Silent or Vibrate (`VipRing.kt`, from the screening
/// service). Needs the call-screening role and Do Not Disturb access.
class VipCallsScreen extends StatefulWidget {
  const VipCallsScreen({super.key});

  @override
  State<VipCallsScreen> createState() => _VipCallsScreenState();
}

class _VipCallsScreenState extends State<VipCallsScreen> with WidgetsBindingObserver {
  final _bridge = TelecomBridge.instance;
  final _on = ValueNotifier(false);
  final _favourites = ValueNotifier(true);

  /// Whether VIP calls can ring right now: false shows the fix row.
  bool _ready = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bridge.getCallSettings().then((s) {
      if (!mounted) return;
      if (s['vipRing'] case final bool v) _on.value = v;
      if (s['vipFavourites'] case final bool v) _favourites.value = v;
      _check();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _on.dispose();
    _favourites.dispose();
    super.dispose();
  }

  // Back from Android's Do Not Disturb access page.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final health = await _bridge.getCallHealth();
    if (mounted) setState(() => _ready = health['screensCalls'] == true && health['dndAccess'] == true);
  }

  Future<void> _fix() async {
    if (!await _bridge.hasScreeningRole() && !await _bridge.requestScreeningRole()) return;
    final health = await _bridge.getCallHealth();
    if (health['dndAccess'] != true) await _bridge.openSystemSettings('dndAccess');
    await _check();
  }

  Future<void> _setOn(bool on) async {
    // Only the call-screening app hears about calls before they ring.
    if (on && !await _bridge.hasScreeningRole() && !await _bridge.requestScreeningRole()) return;
    if (!mounted) return;
    setState(() => _on.value = on);
    await _bridge.setCallSetting('vipRing', on);
    if (on) await _fix();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CosSubpage(
      title: l10n.vipCalls,
      children: [
        OneUIGroupCard(
          items: [
            switchRow(l10n.vipRing, _on, _setOn, subtitle: l10n.vipRingSubtitle),
            if (_on.value && !_ready)
              OneUIGroupItem(
                leading: const Icon(Icons.warning_amber_rounded, color: OneUITheme.accentRed),
                title: l10n.vipNeedsAccess,
                subtitle: l10n.vipNeedsAccessSubtitle,
                subtitleColor: OneUITheme.accentRed,
                value: l10n.fix,
                onTap: _fix,
              ),
          ],
        ),
        OneUIGroupCard(
          items: [
            switchRow(l10n.vipFavourites, _favourites, (v) {
              _favourites.value = v;
              _bridge.setCallSetting('vipFavourites', v);
            }, subtitle: l10n.vipFavouritesSubtitle),
            OneUIGroupItem(
              title: l10n.vipContacts,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => RecordContactsScreen(prefKey: 'vipContacts', title: l10n.vipContacts)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text(l10n.vipDndHint, style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
        ),
      ],
    );
  }
}
