import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../in_call/call_controls.dart' show editCallNote;
import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/place_call.dart';
import '../../widgets/round_header_controls.dart';
import '../blocking/blocking_repository.dart';
import '../contacts/contact_details_screen.dart';
import '../contacts/editor/add_to_contacts.dart';
import 'app_calls.dart';
import 'call_log.dart';
import 'call_log_repository.dart';
import 'recents_screen.dart';
import 'delete_calls.dart';
import '../../l10n/l10n.dart';

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
    final addTileKey = GlobalKey();
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([repo.calls, ContactsRepository.instance.contacts]),
            builder: (context, _) {
              // Private calls have no number to match on; show just this one.
              final history = call.isPrivate
                  ? repo.calls.value.where((c) => c.id == call.id).toList()
                  : [
                      for (final c in repo.calls.value)
                        if (numberKey(c.number) == key) c,
                    ];
              final name = callerName(context.l10n, call);
              final isContact = ContactsRepository.instance.nameFor(call.number) != null;
              return CustomScrollView(
                physics: const OneUIScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, padding.top + 8 + _button + 16, 16, padding.bottom + 32),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverList.list(
                          children: [
                            Center(
                              child: AppBadged(
                                package: call.appPackage,
                                size: 32,
                                child: CallerAvatar(
                                  number: call.number,
                                  name: name,
                                  isPrivate: call.isPrivate,
                                  size: 112,
                                ),
                              ),
                            ),
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
                                style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 28),
                            if (!call.isPrivate) ...[
                              Row(
                                spacing: 12,
                                children: [
                                  // An app's call: call back through that app (from the details page a tap is deliberate).
                                  if (call.isApp)
                                    Expanded(
                                      child: DetailsActionTile(
                                        icon: call.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                                        label: call.app!,
                                        onTap: () => TelecomBridge.instance.callBack(call.id),
                                      ),
                                    ),
                                  Expanded(
                                    child: DetailsActionTile(
                                      key: callTileKey,
                                      icon: Icons.call_rounded,
                                      label: context.l10n.call,
                                      // The SIM menu (no SIM logged for this call) pops from the tile.
                                      onTap: () =>
                                          placeCall(context, call.number, simId: call.simId, anchorKey: callTileKey),
                                    ),
                                  ),
                                  Expanded(
                                    child: DetailsActionTile(
                                      icon: Icons.chat_bubble_rounded,
                                      label: context.l10n.message,
                                      onTap: () => TelecomBridge.instance.sendSms(call.number),
                                    ),
                                  ),
                                  if (!isContact)
                                    Expanded(
                                      child: DetailsActionTile(
                                        key: addTileKey,
                                        icon: Icons.person_add_alt_1_rounded,
                                        label: context.l10n.add,
                                        onTap: () => showAddToContacts(context, call.number, anchorKey: addTileKey),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                            CallNotesCard(numbers: [if (!call.isPrivate) call.number]),
                            Padding(
                              padding: EdgeInsets.only(left: 18, bottom: 8),
                              child: Text(
                                context.l10n.callLogs,
                                style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        // Lazy: a number called every day has hundreds of rows.
                        DetailsCardSliver(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: history.length,
                          itemBuilder: (context, i) => _HistoryRow(call: history[i]),
                        ),
                      ],
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
                  tooltip: context.l10n.back,
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
                          tooltip: blocked ? context.l10n.unblock : context.l10n.block,
                          onPressed: () => BlockingRepository.instance.setBlocked(call.number, !blocked),
                          style: IconButton.styleFrom(
                            foregroundColor: blocked ? OneUITheme.accentRed : context.palette.textPrimary,
                            fixedSize: const Size.square(_button),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.block_rounded, size: 24),
                        ),
                      );
                    },
                  ),
                ],
                RoundIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: context.l10n.deleteCallHistory,
                  onTap: () async {
                    final ids = call.isPrivate || call.number.isEmpty
                        ? [call.id]
                        : [
                            for (final c in repo.calls.value)
                              if (!c.isPrivate && numberKey(c.number) == key) c.id,
                          ];
                    final deleted = await confirmDeleteCalls(context, ids);
                    if (deleted && context.mounted) Navigator.of(context).pop();
                  },
                ),
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
List<String> notesFor(CallLogEntry call, List<CallLogEntry> history, List<(DateTime, String)> notes) => [
  for (final (at, text) in notes)
    if (history.where((c) => noteDuring(c, at)).firstOrNull == call) text,
];

/// Whether a note started at [at] was taken during [call].
bool noteDuring(CallLogEntry call, DateTime at) =>
    !at.isBefore(call.date.subtract(const Duration(minutes: 1))) &&
    at.isBefore(call.date.add(call.duration + const Duration(minutes: 2)));

/// "Notes": every note taken during calls with [numbers], newest first, each opening the note
/// editor (clearing a note's text deletes it). Hidden when there are none.
class CallNotesCard extends StatelessWidget {
  const CallNotesCard({super.key, required this.numbers});

  final List<String> numbers;

  Future<List<(DateTime, String, String)>> _load() async {
    final seen = <String>{};
    final notes = [
      for (final number in numbers)
        if (seen.add(numberKey(number)))
          for (final (at, text) in await DialerPrefs.instance.callNotes(number)) (at, text, number),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return notes;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Notes are written by the call screen's engine, so also reload when a call is logged.
    listenable: Listenable.merge([DialerPrefs.instance.changes, CallLogRepository.instance.calls]),
    builder: (context, _) => FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? const [];
        if (notes.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 18, bottom: 8),
              child: Text(context.l10n.notes, style: TextStyle(fontSize: 15, color: context.palette.textSecondary)),
            ),
            DetailsCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final (at, text, number) in notes)
                  InkWell(
                    onTap: () => editCallNote(context, number, at),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dayLabel(context.l10n, at, now)}, ${timeLabel(context.l10n, at)}',
                            style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.call});

  final CallLogEntry call;

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
                  '${dayLabel(context.l10n, call.date, DateTime.now())}, ${timeLabel(context.l10n, call.date)}',
                  style: const TextStyle(fontSize: 17),
                ),
                if (call.isApp)
                  Text(
                    appCallLabel(context.l10n, call),
                    style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            answered ? durationLabel(context.l10n, call.duration) : callTypeLabel(context.l10n, call.type),
            style: TextStyle(
              fontSize: 13,
              color: call.type == CallType.missed ? OneUITheme.accentRed : context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
