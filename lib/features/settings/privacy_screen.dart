import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/security/app_lock.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../vault/vault.dart';

/// Settings › Privacy & security: App lock and the private vault.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _lockAfterKey = GlobalKey();
  bool _available = true;

  @override
  void initState() {
    super.initState();
    _checkAvailable();
  }

  Future<void> _checkAvailable() async {
    try {
      final available = await TelecomBridge.instance.appLockAvailable();
      if (mounted) setState(() => _available = available);
    } on PlatformException {
      // No bridge: leave the switch as it is.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lock = AppLock.instance;
    return CosSubpage(
      title: l10n.privacySecurity,
      children: [
        OneUIGroupCard(
          margin: const EdgeInsets.only(bottom: 8),
          items: [
            switchRow(
              l10n.appLock,
              lock.enabled,
              (on) => lock.setEnabled(on, l10n.unlockOneDialer),
              subtitle: _available ? l10n.appLockSubtitle : l10n.appLockNeedsScreenLock,
              // A lock already on can still be turned off after a screen lock is removed.
              enabled: _available || lock.enabled.value,
            ),
            choiceRow(
              context,
              title: l10n.lockAfter,
              anchor: _lockAfterKey,
              value: lock.lockAfter,
              labels: {'0': l10n.lockImmediately, '60': l10n.lockAfterOneMinute, '300': l10n.lockAfterFiveMinutes},
              onPick: lock.setLockAfter,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Text(l10n.appLockCalls, style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: l10n.privateVault,
              subtitle: l10n.privateVaultSubtitle,
              onTap: () => PrivateVault.open(context),
            ),
          ],
        ),
      ],
    );
  }
}
