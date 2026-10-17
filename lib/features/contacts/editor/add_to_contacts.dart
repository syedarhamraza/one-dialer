import 'package:flutter/material.dart';

import '../../../widgets/one_ui_floating_modal.dart';
import '../contact_picker_screen.dart';
import 'contact_editor_screen.dart';

/// Samsung's "Add to Contacts" sheet for a number: create a new contact or add the
/// number to an existing one. Returns the saved contact's id, or null.
Future<String?> showAddToContacts(BuildContext context, String number) async {
  final choice = await OneUIFloatingModal.show<String>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('Add to Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
        for (final (label, value) in [('Create new contact', 'new'), ('Update existing contact', 'existing')])
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pop(ctx, value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(label, style: const TextStyle(fontSize: 18)),
            ),
          ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return null;
  if (choice == 'new') return openContactEditor(context, number: number);
  final contact = await pickContact(context, title: 'Update existing contact');
  if (contact == null || !context.mounted) return null;
  return openContactEditor(context, contactId: contact.id, number: number);
}
