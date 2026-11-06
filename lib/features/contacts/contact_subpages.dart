import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/press_glow.dart';
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
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

  @override
  void initState() {
    super.initState();
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
      listenable: repo.calls,
      builder: (context, _) {
        final calls = [
          for (final c in repo.calls.value)
            if (keys.contains(numberKey(c.number))) c,
        ];
        final now = DateTime.now();
        return OneUISubpage(
          title: context.l10n.callLogs,
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
                itemBuilder: (context, i) => ContactCallLogRow(
                  call: calls[i],
                  simBadge: _simBadge(calls[i].simId),
                  now: now,
                  numberLine: _numberLine(calls[i].number),
                ),
              ),
          ],
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
                      if (many) _PillButton(label: context.l10n.unlink, onTap: () => _unlink([r['id']! as int])),
                    ],
                  ),
                ),
            ],
          ),
        if (many)
          _PillButton(
            label: context.l10n.unlinkAll,
            wide: true,
            onTap: () => _unlink([for (final r in raw!) r['id']! as int]),
          ),
      ],
    );
  }
}

/// A grey stadium button with the glass press, small in a row or full width under the card.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap, this.wide = false});

  final String label;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) => PressGlow(
    child: Material(
      color: context.palette.pill,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: wide ? double.infinity : null,
          height: wide ? 52 : 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: wide ? 16.5 : 14.5,
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}
