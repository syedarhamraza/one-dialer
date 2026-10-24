import 'package:flutter/material.dart';

import '../../../widgets/one_ui_floating_menu.dart';
import '../contact_picker_screen.dart';
import 'contact_editor_screen.dart';

/// Samsung's "Add to Contacts" sheet for a number: create a new contact or add the
/// number to an existing one. Returns the saved contact's id, or null.
Future<String?> showAddToContacts(BuildContext context, String number, {GlobalKey? anchorKey}) async {
  String? choice;
  await OneUIFloatingMenu.show(
    context: context,
    anchorKey: anchorKey,
    width: 270,
    items: [
      OneUIFloatingMenuItem(label: 'Create new contact', onTap: () => choice = 'new'),
      OneUIFloatingMenuItem(label: 'Update existing contact', onTap: () => choice = 'existing'),
    ],
  );
  if (!context.mounted || choice == null) return null;
  if (choice == 'new') return openContactEditor(context, number: number);
  final contact = await pickContact(context, title: 'Update existing contact');
  if (contact == null || !context.mounted) return null;
  return openContactEditor(context, contactId: contact.id, number: number);
}
