import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/search_bar_row.dart';
import 'contact_sections.dart';
import 'contacts_widgets.dart';

/// Picks a contact from our own list (instead of Android's picker). Returns the contact.
Future<DialerContact?> pickContact(BuildContext context, {String title = 'Select contact'}) =>
    Navigator.of(context).push<DialerContact>(MaterialPageRoute(builder: (_) => ContactPickerScreen(title: title)));

/// Picks one number: the contact's only number, or the user's choice among several.
/// Returns (contact, number).
Future<(DialerContact, String)?> pickContactNumber(BuildContext context, {String title = 'Select contact'}) async {
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
            borderRadius: BorderRadius.circular(16),
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
                        Text(contact.labels[i], style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
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
              SliverToBoxAdapter(child: SizedBox(height: top + 8 + 48 + 16)),
              if (sections.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(20), child: Text('No matching contacts')),
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
                    selecting: true,
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
            child: ExpandableSearchHeader(
              controller: _query,
              leading: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
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
        ],
      ),
    );
  }
}
