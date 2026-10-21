import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_floating_modal.dart';
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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sections = sectionContacts(searchContacts(ContactsRepository.instance.contacts.value, _query));
    return Scaffold(
      body: CustomScrollView(
        physics: const OneUIScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: OneUICollapsibleHeaderDelegate(
              title: widget.title,
              hasBigHeader: false,
              showBackButton: true,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search_rounded, color: OneUITheme.textSecondary),
                  filled: true,
                  fillColor: OneUITheme.surfaceCard,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: OneUITheme.pillBorderRadius, borderSide: BorderSide.none),
                ),
              ),
            ),
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
    );
  }
}
