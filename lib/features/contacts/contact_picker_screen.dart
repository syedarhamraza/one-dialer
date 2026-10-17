import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_floating_modal.dart';
import 'contact_sections.dart';

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
        for (final (i, n) in contact.numbers.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(n, style: const TextStyle(fontSize: 18)),
            subtitle: Text(contact.labels[i], style: const TextStyle(color: OneUITheme.textSecondary)),
            onTap: () => Navigator.pop(ctx, n),
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
    final contacts = searchContacts(ContactsRepository.instance.contacts.value, _query);
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: OneUITheme.cardBorderRadius),
              sliver: SliverList.builder(
                itemCount: contacts.length,
                itemBuilder: (context, i) {
                  final c = contacts[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: LetterAvatar(name: c.name, photo: c.thumbnail),
                    title: Text(c.name, style: const TextStyle(fontSize: 17)),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
