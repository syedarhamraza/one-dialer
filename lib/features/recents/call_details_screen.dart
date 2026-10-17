import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/place_call.dart';
import '../blocking/blocking_repository.dart';
import 'call_log.dart';
import 'call_log_repository.dart';
import 'recents_screen.dart';

/// One caller: Call / Message / Add to contacts, and every logged call with that number.
class CallDetailsScreen extends StatelessWidget {
  const CallDetailsScreen({super.key, required this.call});

  final CallLogEntry call;

  @override
  Widget build(BuildContext context) {
    final repo = CallLogRepository.instance;
    final key = numberKey(call.number);
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!call.isPrivate)
            ValueListenableBuilder(
              valueListenable: BlockingRepository.instance.numbers,
              builder: (context, _, _) {
                final blocked = BlockingRepository.instance.isBlocked(call.number);
                return IconButton(
                  tooltip: blocked ? 'Unblock' : 'Block',
                  icon: Icon(
                    blocked ? Icons.block_rounded : Icons.block_outlined,
                    color: blocked ? OneUITheme.accentRed : null,
                  ),
                  onPressed: () => BlockingRepository.instance.setBlocked(call.number, !blocked),
                );
              },
            ),
          if (!call.isPrivate)
            IconButton(
              tooltip: 'Delete call history',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ids = [
                  for (final c in repo.calls.value)
                    if (numberKey(c.number) == key) c.id,
                ];
                await repo.delete(ids);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([repo.calls, ContactsRepository.instance.contacts]),
        builder: (context, _) {
          // Private calls have no number to match on; show just this one.
          final history = call.isPrivate
              ? [call]
              : [
                  for (final c in repo.calls.value)
                    if (numberKey(c.number) == key) c,
                ];
          final name = callerName(call);
          final isContact = ContactsRepository.instance.nameFor(call.number) != null;
          return ListView(
            physics: const OneUIScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              Center(child: LetterAvatar(name: call.isPrivate ? '' : name, size: 96)),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
              if (name != call.number && !call.isPrivate) ...[
                const SizedBox(height: 4),
                Text(
                  call.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
                ),
              ],
              const SizedBox(height: 24),
              if (!call.isPrivate)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Action(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      color: OneUITheme.accentGreen,
                      onTap: () => placeCall(context, call.number, simId: call.simId),
                    ),
                    _Action(
                      icon: Icons.message_rounded,
                      label: 'Message',
                      color: OneUITheme.accentBlue,
                      onTap: () => TelecomBridge.instance.sendSms(call.number),
                    ),
                    if (!isContact)
                      _Action(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Add',
                        color: OneUITheme.textPrimary,
                        onTap: () => ContactsRepository.instance.addNumber(call.number),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: OneUITheme.cardBorderRadius),
                child: Column(
                  children: [
                    for (var i = 0; i < history.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white.withValues(alpha: 0.08)),
                      _HistoryRow(call: history[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 56,
            child: IconButton(
              tooltip: label,
              style: IconButton.styleFrom(backgroundColor: OneUITheme.surfacePill, foregroundColor: color),
              onPressed: onTap,
              icon: Icon(icon),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.call});

  final CallLogEntry call;

  @override
  Widget build(BuildContext context) {
    // Missed and rejected calls log ring time as duration; only talk time is shown.
    final answered =
        (call.type == CallType.incoming || call.type == CallType.outgoing) && call.duration > Duration.zero;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CallTypeIcon(type: call.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(callTypeLabel(call.type), style: const TextStyle(fontSize: 15.5)),
                const SizedBox(height: 2),
                Text(
                  '${dayLabel(call.date, DateTime.now())}, ${timeLabel(call.date)}',
                  style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                ),
              ],
            ),
          ),
          if (answered)
            Text(durationLabel(call.duration), style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
        ],
      ),
    );
  }
}
