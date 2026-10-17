import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_group_card.dart';

/// First run: asks to become the default phone app. [onSkip] continues without it
/// (calls then go through the system dialer's call screen).
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, required this.onDone, required this.onSkip});

  /// Called after the role prompt; the caller re-checks whether it was granted.
  final VoidCallback onDone;
  final VoidCallback onSkip;

  Future<void> _becomeDefault() async {
    await TelecomBridge.instance.requestDefaultDialer();
    // The role grants phone, contacts and call log; notifications still need asking.
    await Permission.notification.request();
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: OneUIScrollPhysics.bigHeader,
        slivers: [
          const SliverPersistentHeader(
            pinned: true,
            delegate: OneUICollapsibleHeaderDelegate(title: 'Phone', subtitle: 'Set up your dialer'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: [
                OneUIGroupCard(
                  headerTitle: 'Make this your phone app',
                  items: [
                    OneUIGroupItem(
                      leading: const Icon(Icons.phone_android_rounded, color: OneUITheme.accentGreen),
                      title: 'Default phone app',
                      subtitle: 'Needed to show incoming calls, your call log and to block numbers',
                      onTap: _becomeDefault,
                      trailing: const _PillAction(label: 'Set'),
                    ),
                  ],
                ),
                // Prominent disclosure (Google Play): what each permission is used for.
                const OneUIGroupCard(
                  headerTitle: 'What Dialer will use',
                  items: [
                    OneUIGroupItem(
                      leading: Icon(Icons.call_outlined, color: OneUITheme.textSecondary),
                      title: 'Phone',
                      subtitle: 'Make, answer and manage calls on your SIMs',
                      trailing: SizedBox.shrink(),
                    ),
                    OneUIGroupItem(
                      leading: Icon(Icons.watch_later_outlined, color: OneUITheme.textSecondary),
                      title: 'Call history',
                      subtitle: 'Show Recents, missed calls and blocked calls',
                      trailing: SizedBox.shrink(),
                    ),
                    OneUIGroupItem(
                      leading: Icon(Icons.person_outline_rounded, color: OneUITheme.textSecondary),
                      title: 'Contacts',
                      subtitle: 'Show names and photos, search and speed dial',
                      trailing: SizedBox.shrink(),
                    ),
                    OneUIGroupItem(
                      leading: Icon(Icons.notifications_none_rounded, color: OneUITheme.textSecondary),
                      title: 'Notifications',
                      subtitle: 'Show incoming, ongoing and missed calls',
                      trailing: SizedBox.shrink(),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Your calls, call history and contacts never leave your phone. Crash reports (no personal data) help fix bugs.',
                    style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: onSkip,
                    child: const Text('Not now', style: TextStyle(color: OneUITheme.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One UI's tinted pill action (from OneSpend's `OneUIEmptyCard`); taps go to the row.
class _PillAction extends StatelessWidget {
  const _PillAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OneUITheme.accentBlue.withValues(alpha: 0.16),
        borderRadius: OneUITheme.pillBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OneUITheme.accentBlue),
        ),
      ),
    );
  }
}
