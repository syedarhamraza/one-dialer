import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/place_call.dart';
import '../../widgets/round_header_controls.dart';
import '../blocking/blocking_repository.dart';
import '../contacts/contact_details_screen.dart';
import '../contacts/editor/add_to_contacts.dart';
import 'call_log.dart';
import 'call_log_repository.dart';
import 'recents_screen.dart';

/// (i) on a call: a saved contact's own page, else this number's page.
void openCallDetails(BuildContext context, CallLogEntry call) {
  final contact = call.isPrivate ? null : ContactsRepository.instance.contactFor(call.number);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => contact != null ? ContactDetailsScreen(contactId: contact.id) : CallDetailsScreen(call: call),
    ),
  );
}

/// An unsaved number's page in the contact page's look: round glass Back / Block / Delete
/// buttons over a big avatar and the number, Call / Message / Add tiles, and every logged
/// call with that number (with the notes taken during them).
class CallDetailsScreen extends StatelessWidget {
  const CallDetailsScreen({super.key, required this.call});

  final CallLogEntry call;

  static const double _button = 48;

  @override
  Widget build(BuildContext context) {
    final repo = CallLogRepository.instance;
    final key = numberKey(call.number);
    // Built here, above the list's listener, so its rebuilds keep the same key.
    final callTileKey = GlobalKey();
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          ListenableBuilder(
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
                padding: EdgeInsets.fromLTRB(16, padding.top + 8 + _button + 16, 16, padding.bottom + 32),
                children: [
                  Center(child: LetterAvatar(name: call.isPrivate ? '' : name, size: 112)),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: -0.4),
                  ),
                  if (name != call.number && !call.isPrivate) ...[
                    const SizedBox(height: 4),
                    Text(
                      call.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (!call.isPrivate) ...[
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: DetailsActionTile(
                            key: callTileKey,
                            icon: Icons.call_rounded,
                            label: 'Call',
                            // The SIM menu (no SIM logged for this call) pops from the tile.
                            onTap: () => placeCall(context, call.number, simId: call.simId, anchorKey: callTileKey),
                          ),
                        ),
                        Expanded(
                          child: DetailsActionTile(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Message',
                            onTap: () => TelecomBridge.instance.sendSms(call.number),
                          ),
                        ),
                        if (!isContact)
                          Expanded(
                            child: DetailsActionTile(
                              icon: Icons.person_add_alt_1_rounded,
                              label: 'Add',
                              onTap: () => showAddToContacts(context, call.number),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(left: 18, bottom: 8),
                    child: Text('Call logs', style: TextStyle(fontSize: 15, color: OneUITheme.textSecondary)),
                  ),
                  ValueListenableBuilder(
                    valueListenable: DialerPrefs.instance.changes,
                    builder: (context, _, _) => FutureBuilder(
                      future: DialerPrefs.instance.callNotes(call.number),
                      builder: (context, notes) => DetailsCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          for (final c in history)
                            _HistoryRow(call: c, notes: notesFor(c, history, notes.data ?? const [])),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Positioned(left: 0, right: 0, top: 0, child: OneUIStatusBarScrim()),
          Positioned(
            left: 16,
            right: 16,
            top: padding.top + 8,
            child: Row(
              spacing: 8,
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                if (!call.isPrivate) ...[
                  // RoundIconButton in red while the number is blocked.
                  ValueListenableBuilder(
                    valueListenable: BlockingRepository.instance.numbers,
                    builder: (context, _, _) {
                      final blocked = BlockingRepository.instance.isBlocked(call.number);
                      return CallGlass(
                        child: IconButton(
                          tooltip: blocked ? 'Unblock' : 'Block',
                          onPressed: () => BlockingRepository.instance.setBlocked(call.number, !blocked),
                          style: IconButton.styleFrom(
                            foregroundColor: blocked ? OneUITheme.accentRed : OneUITheme.textPrimary,
                            fixedSize: const Size.square(_button),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.block_rounded, size: 24),
                        ),
                      );
                    },
                  ),
                  RoundIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete call history',
                    onTap: () async {
                      final ids = [
                        for (final c in repo.calls.value)
                          if (numberKey(c.number) == key) c.id,
                      ];
                      await repo.delete(ids);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notes taken during [call]: each note goes to the newest logged call whose time span (with a
/// little slack for ringing and the call log's rounding) contains the moment it was started.
List<String> notesFor(CallLogEntry call, List<CallLogEntry> history, List<(DateTime, String)> notes) {
  bool during(CallLogEntry c, DateTime at) =>
      !at.isBefore(c.date.subtract(const Duration(minutes: 1))) &&
      at.isBefore(c.date.add(c.duration + const Duration(minutes: 2)));
  return [
    for (final (at, text) in notes)
      if (history.where((c) => during(c, at)).firstOrNull == call) text,
  ];
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.call, this.notes = const []});

  final CallLogEntry call;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    // Missed and rejected calls log ring time as duration; only talk time is shown.
    final answered =
        (call.type == CallType.incoming || call.type == CallType.outgoing) && call.duration > Duration.zero;
    // Laid out like the contact page's call logs: grey arrow, the time, then talk time or type.
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          SizedBox(width: 40, child: CallTypeIcon(type: call.type, muted: true)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dayLabel(call.date, DateTime.now())}, ${timeLabel(call.date)}',
                  style: const TextStyle(fontSize: 17),
                ),
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 16, color: OneUITheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(note, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            answered ? durationLabel(call.duration) : callTypeLabel(call.type),
            style: TextStyle(
              fontSize: 13,
              color: call.type == CallType.missed ? OneUITheme.accentRed : OneUITheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
