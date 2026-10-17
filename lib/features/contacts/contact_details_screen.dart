import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../blocking/blocking_repository.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/place_call.dart';

/// One contact: call / message each number, favourite, edit, and the SIM to call them on.
class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  List<SimCard> _sims = const [];
  String? _simId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sims = await TelecomBridge.instance.getSims();
    final simId = await DialerPrefs.instance.contactSim(widget.contactId);
    if (!mounted) return;
    setState(() {
      _sims = sims;
      _simId = simId;
    });
  }

  String get _simLabel => _sims.where((s) => s.id == _simId).map((s) => s.label).firstOrNull ?? 'Ask every time';

  Future<void> _chooseSim() async {
    final picked = await showModalBottomSheet<(String?,)>(
      context: context,
      backgroundColor: OneUITheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(OneUITheme.radiusCard)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Call this contact using', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final (id, label) in [(null, 'Ask every time'), for (final s in _sims) (s.id, s.label)])
              ListTile(
                title: Text(label),
                trailing: id == _simId ? const Icon(Icons.check_rounded, color: OneUITheme.accentBlue) : null,
                onTap: () => Navigator.of(context).pop((id,)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await DialerPrefs.instance.setContactSim(widget.contactId, picked.$1);
    if (mounted) setState(() => _simId = picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ContactsRepository.instance;
    return ValueListenableBuilder<List<DialerContact>>(
      valueListenable: repo.contacts,
      builder: (context, all, _) {
        final contact = all.where((c) => c.id == widget.contactId).firstOrNull;
        if (contact == null) {
          // Deleted (e.g. from the editor) or lost its numbers.
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Contact not found', style: TextStyle(color: OneUITheme.textSecondary)),
            ),
          );
        }
        Future<void> call(String number) => placeCall(context, number, simId: _simId);
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: contact.isFavorite ? 'Remove from favourites' : 'Add to favourites',
                icon: Icon(
                  contact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: contact.isFavorite ? const Color(0xFFFFD166) : null,
                ),
                onPressed: () => repo.setFavorite(contact.id, !contact.isFavorite),
              ),
              ValueListenableBuilder(
                valueListenable: BlockingRepository.instance.numbers,
                builder: (context, _, _) {
                  final blocking = BlockingRepository.instance;
                  final blocked = contact.numbers.every(blocking.isBlocked);
                  return IconButton(
                    tooltip: blocked ? 'Unblock contact' : 'Block contact',
                    icon: Icon(
                      blocked ? Icons.block_rounded : Icons.block_outlined,
                      color: blocked ? OneUITheme.accentRed : null,
                    ),
                    onPressed: () async {
                      for (final n in contact.numbers) {
                        await blocking.setBlocked(n, !blocked);
                      }
                    },
                  );
                },
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => repo.edit(contact.id),
              ),
            ],
          ),
          body: ListView(
            physics: const OneUIScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              Center(
                child: LetterAvatar(name: contact.name, photo: contact.thumbnail, size: 96),
              ),
              const SizedBox(height: 16),
              Text(
                contact.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Action(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: OneUITheme.accentGreen,
                    onTap: () => call(contact.numbers.first),
                  ),
                  _Action(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    color: OneUITheme.accentBlue,
                    onTap: () => TelecomBridge.instance.sendSms(contact.numbers.first),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OneUIGroupCard(
                items: [
                  for (var i = 0; i < contact.numbers.length; i++)
                    OneUIGroupItem(
                      title: contact.numbers[i],
                      subtitle: contact.labels[i],
                      onTap: () => call(contact.numbers[i]),
                      trailing: IconButton(
                        tooltip: 'Message',
                        icon: const Icon(Icons.message_outlined, color: OneUITheme.accentBlue),
                        onPressed: () => TelecomBridge.instance.sendSms(contact.numbers[i]),
                      ),
                    ),
                ],
              ),
              if (_sims.length > 1)
                OneUIGroupCard(
                  items: [
                    OneUIGroupItem(
                      leading: const Icon(Icons.sim_card_outlined, color: OneUITheme.textSecondary),
                      title: 'SIM card for calls',
                      subtitle: _simLabel,
                      onTap: _chooseSim,
                    ),
                  ],
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
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
