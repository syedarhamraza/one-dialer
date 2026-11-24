import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/search_bar_row.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/select_mark.dart';
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
import 'contact_sections.dart';
import 'contacts_widgets.dart';
import '../../l10n/l10n.dart';
import '../../app/layout.dart';
import 'editor/contact_form.dart' show labelDisplay;

/// Picks a contact from our own list (instead of Android's picker). Returns the contact.
Future<DialerContact?> pickContact(BuildContext context, {String? title}) => Navigator.of(context).push<DialerContact>(
  MaterialPageRoute(builder: (_) => ContactPickerScreen(title: title ?? context.l10n.selectContact)),
);

/// Picks one number: the contact's only number, or the user's choice among several.
/// Returns (contact, number).
Future<(DialerContact, String)?> pickContactNumber(BuildContext context, {String? title}) async {
  final contact = await pickContact(context, title: title);
  if (contact == null || !context.mounted) return null;
  if (contact.numbers.length == 1) return (contact, contact.numbers.single);
  final number = await OneUIFloatingModal.show<String>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(contact.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        // Rows like the contact page's number rows: the number, its label below.
        for (final (i, n) in contact.numbers.indexed)
          InkWell(
            customBorder: SquircleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () => Navigator.pop(ctx, n),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 40, child: Icon(Icons.call_outlined, size: 24)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n, style: const TextStyle(fontSize: 19)),
                        const SizedBox(height: 2),
                        Text(
                          labelDisplay(context.l10n, contact.labels[i]),
                          style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  return number == null ? null : (contact, number);
}

class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key, required this.title});

  final String title;

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final _query = TextEditingController();
  @override
  void initState() {
    super.initState();
    _query.addListener(_refresh);
    ContactsRepository.instance.contacts.addListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
    ContactsRepository.instance.contacts.removeListener(_refresh);
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = sectionContacts(searchContacts(ContactsRepository.instance.contacts.value, _query.text));
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const OneUIScrollPhysics(),
            slivers: [
              // Room for the pinned Back row (as `OneUISubpage`).
              SliverToBoxAdapter(child: SizedBox(height: top + 8 + 48 * headerScale(context) + 16)),
              if (sections.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(padding: const EdgeInsets.all(20), child: Text(context.l10n.noMatchingContacts)),
                ),
              // The Contacts tab's A–Z sections and flat rows.
              for (final (letter, list) in sections) ...[
                SliverToBoxAdapter(child: ContactsSectionHeader(title: letter)),
                SliverFixedExtentList.builder(
                  itemExtent: ContactRow.height,
                  itemCount: list.length,
                  itemBuilder: (context, i) => ContactRow(
                    contact: list[i],
                    isLast: i == list.length - 1,
                    // Turns off the row's swipe to call: picking must never place a call.
                    selectMark: const SizedBox.shrink(),
                    onTap: () => Navigator.of(context).pop(list[i]),
                    onLongPress: () => Navigator.of(context).pop(list[i]),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
          const Positioned(left: 0, right: 0, top: 0, child: OneUIStatusBarScrim()),
          Positioned(
            left: 16,
            right: 16,
            top: top + 8,
            child: HeaderScaled(
              child: ExpandableSearchHeader(
                controller: _query,
                leading: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: context.l10n.back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picks several numbers at once (Blocklist and Allowlist › Choose from Contacts), from the
/// recent calls or the contacts. Returns the ticked numbers; null when cancelled.
Future<List<String>?> pickNumbers(BuildContext context) =>
    Navigator.of(context).push<List<String>>(MaterialPageRoute(builder: (_) => const NumberPickerScreen()));

/// ColorOS's multi-number picker: Cancel / "N selected" / Done, Calls and Contacts tabs, a
/// search, and a row per number with its box. A number ticked on one tab is ticked on both.
class NumberPickerScreen extends StatefulWidget {
  const NumberPickerScreen({super.key});

  @override
  State<NumberPickerScreen> createState() => _NumberPickerScreenState();
}

class _NumberPickerScreenState extends State<NumberPickerScreen> {
  final _query = TextEditingController();

  /// Ticked numbers by [numberKey], each as first ticked.
  final _selected = ValueNotifier<Map<String, String>>(const {});
  int _tab = 1;

  @override
  void initState() {
    super.initState();
    _query.addListener(_refresh);
    ContactsRepository.instance.contacts.addListener(_refresh);
    CallLogRepository.instance.calls.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    ContactsRepository.instance.contacts.removeListener(_refresh);
    CallLogRepository.instance.calls.removeListener(_refresh);
    _query.dispose();
    _selected.dispose();
    super.dispose();
  }

  void _toggle(String number) {
    final key = numberKey(number);
    final next = {..._selected.value};
    if (next.remove(key) == null) next[key] = number;
    _selected.value = next;
  }

  /// Every (contact, number) pair, one per distinct number of each contact.
  static List<(DialerContact, String)> _numbersOf(Iterable<DialerContact> contacts) => [
    for (final c in contacts)
      for (final n in {for (final n in c.numbers) numberKey(n): n}.values)
        if (numberKey(n).isNotEmpty) (c, n),
  ];

  bool _matches(String name, String number) {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
    return name.toLowerCase().contains(q) ||
        (digits.isNotEmpty && number.replaceAll(RegExp(r'[^0-9]'), '').contains(digits));
  }

  /// Recent callers, newest first, one row per number (hidden numbers have none).
  List<(DialerContact, String)> _calls() {
    final repo = ContactsRepository.instance;
    final seen = <String>{};
    final out = <(DialerContact, String)>[];
    for (final c in CallLogRepository.instance.calls.value) {
      final key = numberKey(c.number);
      if (key.isEmpty || !seen.add(key)) continue;
      final contact =
          repo.contactFor(c.number) ?? DialerContact(id: '', name: c.number, numbers: [c.number], labels: const ['']);
      if (_matches(contact.name, c.number)) out.add((contact, c.number));
    }
    return out;
  }

  /// The Contacts tab's A–Z sections, each with its matching numbers.
  List<(String, List<(DialerContact, String)>)> _sections() => [
    for (final (letter, contacts) in sectionContacts(ContactsRepository.instance.contacts.value))
      (
        letter,
        [
          for (final e in _numbersOf(contacts))
            if (_matches(e.$1.name, e.$2)) e,
        ],
      ),
  ].where((s) => s.$2.isNotEmpty).toList();

  Widget _row((DialerContact, String) entry, {required bool isLast}) {
    final (contact, number) = entry;
    final key = numberKey(number);
    return ContactRow(
      contact: contact,
      subtitle: number,
      isLast: isLast,
      selectMark: ValueListenableBuilder(
        valueListenable: _selected,
        builder: (context, selected, _) => SelectMark(selected: selected.containsKey(key)),
      ),
      highlight: ValueListenableBuilder(
        valueListenable: _selected,
        builder: (context, selected, _) => SelectHighlight(selected: selected.containsKey(key)),
      ),
      onTap: () => _toggle(number),
      onLongPress: () => _toggle(number),
    );
  }

  Widget _pill(String text, VoidCallback? onTap) => Opacity(
    opacity: onTap == null ? .4 : 1,
    child: IgnorePointer(
      ignoring: onTap == null,
      child: CallGlass(
        radius: 24,
        child: SizedBox(
          width: SelectionPillLabel.widthFor(context, text),
          height: 48,
          child: SelectionPillLabel(text: text, onTap: onTap ?? () {}),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = _numbersOf(ContactsRepository.instance.contacts.value).length;
    final List<Widget> list;
    if (_tab == 0) {
      final calls = _calls();
      list = [
        if (calls.isNotEmpty)
          SliverFixedExtentList.builder(
            itemExtent: ContactRow.height,
            itemCount: calls.length,
            itemBuilder: (context, i) => _row(calls[i], isLast: i == calls.length - 1),
          ),
      ];
    } else {
      list = [
        for (final (letter, rows) in _sections()) ...[
          SliverToBoxAdapter(child: ContactsSectionHeader(title: letter)),
          SliverFixedExtentList.builder(
            itemExtent: ContactRow.height,
            itemCount: rows.length,
            itemBuilder: (context, i) => _row(rows[i], isLast: i == rows.length - 1),
          ),
        ],
      ];
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: HeaderScaled(
                child: ValueListenableBuilder(
                  valueListenable: _selected,
                  builder: (context, selected, _) => Row(
                    children: [
                      _pill(l10n.cancel, () => Navigator.of(context).pop()),
                      Expanded(
                        child: Text(
                          selected.isEmpty ? l10n.selectItems : l10n.selectedCount(selected.length),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                        ),
                      ),
                      _pill(
                        l10n.done,
                        selected.isEmpty ? null : () => Navigator.of(context).pop(selected.values.toList()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilterTabs(
              labels: [l10n.navCalls, l10n.navContacts],
              index: _tab,
              blur: false,
              onChanged: (i) => setState(() => _tab = i),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: SearchField(
                controller: _query,
                hint: l10n.searchContactNumbers(total),
                autofocus: false,
                blur: false,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const OneUIScrollPhysics(),
                slivers: [
                  if (list.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(padding: const EdgeInsets.all(20), child: Text(l10n.noMatchingContacts)),
                    )
                  else
                    ...list,
                  SliverToBoxAdapter(child: SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
