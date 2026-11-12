import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/haptics/haptics.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_selection_header_pills.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/select_mark.dart';
import '../../widgets/cos_dialog.dart' show CosPill;
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
import '../recents/delete_calls.dart';
import 'contact_details_screen.dart';
import 'editor/contact_form.dart' show labelDisplay;
import '../../l10n/l10n.dart';

/// The app a contact copy lives in, from its raw contact's account type.
String accountApp(AppLocalizations l10n, String? type) => switch (type?.toLowerCase() ?? '') {
  final t when t.contains('w4b') => 'WhatsApp Business',
  final t when t.contains('whatsapp') => 'WhatsApp',
  final t when t.contains('tachyon') => 'Meet',
  final t when t.contains('google') => 'Google',
  final t when t.contains('samsung') || t.contains('osp.app') => l10n.accountSamsung,
  final t when t.contains('telegram') => 'Telegram',
  final t when t.contains('sdn') => l10n.accountSimServiceNumbers,
  final t when t.contains('sim') => l10n.accountSimCard,
  _ => l10n.accountThisDevice,
};

/// "Call logs" (the contact page's View all): every logged call with the contact's numbers.
class ContactHistoryScreen extends StatefulWidget {
  const ContactHistoryScreen({super.key, required this.contact});

  final DialerContact contact;

  @override
  State<ContactHistoryScreen> createState() => _ContactHistoryScreenState();
}

class _ContactHistoryScreenState extends State<ContactHistoryScreen> {
  List<SimCard> _sims = const [];

  /// Selected call ids; null while not selecting (long-press a call to start).
  final _selected = ValueNotifier<Set<int>?>(null);

  /// Whether [_selected] is non-null: the page itself rebuilds only on entering and leaving
  /// selection; a tap redraws just the header, the bar and that row's mark.
  final _selecting = ValueNotifier(false);

  @override
  void dispose() {
    _selected.dispose();
    _selecting.dispose();
    super.dispose();
  }

  void _toggle(int id) {
    final set = {...?_selected.value};
    if (!set.remove(id)) set.add(id);
    _selected.value = set.isEmpty ? null : set;
  }

  /// The selection still in [calls]: deleted calls drop out of it.
  Set<int> _live(List<CallLogEntry> calls) => _selected.value?.intersection({for (final c in calls) c.id}) ?? {};

  Widget _selectionHeader(List<CallLogEntry> calls) => ValueListenableBuilder(
    valueListenable: _selected,
    builder: (context, _, _) => _selectionRow(_live(calls), calls),
  );

  Widget _selectionRow(Set<int> selected, List<CallLogEntry> calls) => SizedBox(
    height: 48,
    child: Row(
      children: [
        RoundIconButton(icon: Icons.close_rounded, tooltip: context.l10n.cancel, onTap: () => _selected.value = null),
        const SizedBox(width: 12),
        OneUISelectionCountPill(
          selectedCount: selected.length,
          totalCount: calls.length,
          onToggleSelectAll: () =>
              _selected.value = selected.length == calls.length ? null : {for (final c in calls) c.id},
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    _selected.addListener(() => _selecting.value = _selected.value != null);
    TelecomBridge.instance.getSims().then((s) {
      if (mounted) setState(() => _sims = s);
    });
  }

  /// Which number a call used, "Mobile · 03111234567", for a contact with several (as on the
  /// contact page, unformatted here).
  String? _numberLine(String number) {
    final c = widget.contact;
    if (c.numbers.length < 2) return null;
    final i = c.numbers.indexWhere((n) => numberKey(n) == numberKey(number));
    if (i < 0) return number;
    return [labelDisplay(context.l10n, c.labels[i]), c.numbers[i]].where((s) => s.isNotEmpty).join(' · ');
  }

  /// "1"/"2" badge, only on dual-SIM phones (as on the contact page).
  String? _simBadge(String? simId) {
    if (_sims.length < 2 || simId == null) return null;
    final i = _sims.indexWhere((s) => s.id == simId);
    return i < 0 ? null : '${i + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final keys = {for (final n in widget.contact.numbers) numberKey(n)};
    final repo = CallLogRepository.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([repo.calls, _selecting]),
      builder: (context, _) {
        final calls = [
          for (final c in repo.calls.value)
            if (keys.contains(numberKey(c.number))) c,
        ];
        final now = DateTime.now();
        final selecting = _selecting.value;
        return PopScope(
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _selected.value = null;
          },
          child: OneUISubpage(
            title: context.l10n.callLogs,
            header: selecting ? _selectionHeader(calls) : null,
            bottomPill: !selecting
                ? null
                : OneUIFloatingActionBar(
                    items: [
                      OneUIFloatingActionBarItem(
                        icon: Icons.delete_outline_rounded,
                        label: context.l10n.delete,
                        color: OneUITheme.accentRed,
                        onTap: () =>
                            confirmDeleteCalls(context, _live(calls), onConfirmed: () => _selected.value = null),
                      ),
                    ],
                  ),
            slivers: (context) => [
              if (calls.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(32, 120, 32, 0),
                    child: Column(
                      children: [
                        Icon(Icons.watch_later_outlined, size: 40, color: context.palette.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          context.l10n.noCallsWithContact,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                DetailsCardSliver(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                  itemCount: calls.length,
                  itemBuilder: (context, i) {
                    final c = calls[i];
                    return ValueListenableBuilder(
                      valueListenable: _selected,
                      builder: (context, selected, row) => InkWell(
                        onTap: selected == null ? null : () => _toggle(c.id),
                        onLongPress: selected != null
                            ? null
                            : () {
                                Haptics.longPress();
                                _selected.value = {c.id};
                              },
                        child: Row(
                          children: [
                            Expanded(child: row!),
                            // Same row structure in and out of selection: the mark springs in.
                            SelectMark(selected: selected?.contains(c.id)),
                          ],
                        ),
                      ),
                      child: ContactCallLogRow(
                        call: c,
                        simBadge: _simBadge(c.simId),
                        now: now,
                        numberLine: _numberLine(c.number),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// "Storage locations": the account copies linked into this contact, with Unlink.
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

  /// "Google" with the account's email, "SIM card", "This device"...
  static String _accountLabel(AppLocalizations l10n, Map<Object?, Object?> r) {
    final app = accountApp(l10n, r['accountType'] as String?);
    final name = r['accountName'] as String?;
    return app == 'Google' && name != null && name.isNotEmpty ? 'Google · $name' : app;
  }

  @override
  Widget build(BuildContext context) {
    final raw = _raw;
    final many = (raw?.length ?? 0) > 1;
    return CosSubpage(
      title: context.l10n.storageLocations,
      children: [
        if (raw != null)
          DetailsCard(
            padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
            dividerIndent: 58, // under the name, past the avatar
            children: [
              for (final r in raw)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      LetterAvatar(name: (r['name'] as String?) ?? widget.contact.name, size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (r['name'] as String?) ?? widget.contact.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _accountLabel(context.l10n, r),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      // ColorOS 17's row action: accent text, no button body.
                      if (many)
                        TextButton(
                          onPressed: () => _unlink([r['id']! as int]),
                          style: TextButton.styleFrom(
                            foregroundColor: OneUITheme.accentGreen,
                            textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                          ),
                          child: Text(context.l10n.unlink),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        if (many) CosPill(label: context.l10n.unlinkAll, onTap: () => _unlink([for (final r in raw!) r['id']! as int])),
      ],
    );
  }
}
