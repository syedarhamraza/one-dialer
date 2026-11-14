import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/place_call.dart';
import '../../widgets/press_glow.dart';
import '../../l10n/l10n.dart';
import 'editor/contact_form.dart' show labelDisplay;

/// Calls [contact]: its default (or only) number straight away, otherwise after Samsung's
/// chooser, whose "Set as default" remembers the pick as Android's default number.
Future<void> callContact(BuildContext context, DialerContact contact) async {
  final number = contact.callNumber ?? await chooseNumber(context, contact);
  if (number != null && context.mounted) await placeCall(context, number);
}

/// The chooser on its own (also used to message a contact). Null if dismissed.
Future<String?> chooseNumber(BuildContext context, DialerContact contact) async {
  var selected = 0;
  final result = await OneUIFloatingModal.show<(int, bool)>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contact.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final (i, n) in contact.numbers.indexed)
            InkWell(
              customBorder: SquircleBorder(borderRadius: BorderRadius.circular(16)),
              onTap: () => setModal(() => selected = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    OneUIRadio(isSelected: selected == i),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelDisplay(context.l10n, contact.labels[i]),
                            style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
                          ),
                          Text(n, style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FooterButton(label: context.l10n.justOnce, onTap: () => Navigator.pop(ctx, (selected, false))),
              ),
              Container(width: 1, height: 18, color: context.palette.divider),
              Expanded(
                child: _FooterButton(
                  label: context.l10n.setAsDefault,
                  onTap: () => Navigator.pop(ctx, (selected, true)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  if (result == null) return null;
  final (index, makeDefault) = result;
  final number = contact.numbers[index];
  if (makeDefault) await ContactsRepository.instance.setDefaultNumber(contact.id, number);
  return number;
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressGlow(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
        child: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.palette.textPrimary),
        ),
      ),
    );
  }
}
