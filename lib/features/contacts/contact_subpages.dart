import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
import '../recents/recents_screen.dart' show CallTypeIcon, callTypeLabel;

/// Every logged call with any of the contact's numbers.
class ContactHistoryScreen extends StatelessWidget {
  const ContactHistoryScreen({super.key, required this.contact});

  final DialerContact contact;

  @override
  Widget build(BuildContext context) {
    final keys = {for (final n in contact.numbers) numberKey(n)};
    final repo = CallLogRepository.instance;
    return OneUISubpage(
      title: 'History',
      listenable: repo.calls,
      builder: (context) {
        final calls = [
          for (final c in repo.calls.value)
            if (keys.contains(numberKey(c.number))) c,
        ];
        if (calls.isEmpty) {
          return const [
            SizedBox(height: 260),
            Center(
              child: Text('No history', style: TextStyle(fontSize: 22, color: OneUITheme.textSecondary)),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Come back later to see when you last connected with this contact.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: OneUITheme.textSecondary),
              ),
            ),
          ];
        }
        final now = DateTime.now();
        return [
          OneUIGroupCard(
            items: [
              for (final c in calls)
                OneUIGroupItem(
                  leading: CallTypeIcon(type: c.type),
                  title: callTypeLabel(c.type),
                  subtitle: '${dayLabel(c.date, now)}, ${timeLabel(c.date)} · ${c.number}',
                  trailing: Text(
                    (c.type == CallType.incoming || c.type == CallType.outgoing) && c.duration > Duration.zero
                        ? durationLabel(c.duration)
                        : '',
                    style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                  ),
                ),
            ],
          ),
        ];
      },
    );
  }
}

/// Samsung's "Storage locations": the account copies linked into this contact, with Unlink.
class StorageLocationsScreen extends StatefulWidget {
  const StorageLocationsScreen({super.key, required this.contact});

  final DialerContact contact;

  @override
  State<StorageLocationsScreen> createState() => _StorageLocationsScreenState();
}

class _StorageLocationsScreenState extends State<StorageLocationsScreen> {
  final _bridge = TelecomBridge.instance;
  List<Map<Object?, Object?>>? _raw;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await _bridge.getRawContacts(widget.contact.id);
    if (mounted) setState(() => _raw = raw);
  }

  Future<void> _unlink(List<int> ids) async {
    await _bridge.unlinkRawContacts(widget.contact.id, ids);
    // Unlinked copies become separate contacts; once one copy is left there's nothing to show.
    if (!mounted) return;
    if ((_raw?.length ?? 0) - ids.length <= 1) {
      Navigator.of(context).pop();
    } else {
      await _load();
    }
  }

  static String _accountLabel(Map<Object?, Object?> r) {
    final type = (r['accountType'] as String?) ?? '';
    final name = r['accountName'] as String?;
    final app = switch (type) {
      final t when t.contains('w4b') => 'WhatsApp Business',
      final t when t.contains('whatsapp') => 'WhatsApp',
      final t when t.contains('google') => 'Google',
      final t when t.contains('samsung') => 'Samsung account',
      final t when t.contains('telegram') => 'Telegram',
      final t when t.contains('sim') => 'SIM',
      _ => 'Phone',
    };
    return name == null || name.isEmpty || name == app ? app : '$app ($name)';
  }

  @override
  Widget build(BuildContext context) {
    final raw = _raw;
    final many = (raw?.length ?? 0) > 1;
    return OneUISubpage(
      title: 'Storage locations',
      builder: (context) => [
        if (raw != null)
          OneUIGroupCard(
            items: [
              for (final r in raw)
                OneUIGroupItem(
                  leading: LetterAvatar(name: (r['name'] as String?) ?? widget.contact.name, size: 48),
                  title: (r['name'] as String?) ?? widget.contact.name,
                  subtitle: _accountLabel(r),
                  trailing: many
                      ? TextButton(
                          onPressed: () => _unlink([r['id']! as int]),
                          child: const Text('Unlink', style: TextStyle(fontSize: 17, color: OneUITheme.accentBlue)),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        if (many)
          Center(
            child: FilledButton(
              onPressed: () => _unlink([for (final r in raw!) r['id']! as int]),
              style: FilledButton.styleFrom(
                backgroundColor: OneUITheme.surfacePill,
                foregroundColor: OneUITheme.textPrimary,
                minimumSize: const Size(260, 60),
              ),
              child: const Text('Unlink all', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}
