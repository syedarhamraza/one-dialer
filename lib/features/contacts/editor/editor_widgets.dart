import 'package:flutter/material.dart';

import '../../../theme/one_ui_theme.dart';
import '../../../widgets/one_ui_floating_menu.dart';
import '../../../widgets/one_ui_floating_modal.dart';
import 'contact_form.dart';

/// ColorOS's rounded flat card holding editor rows.
class EditorCard extends StatelessWidget {
  const EditorCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
      decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// Icon on the left + content + optional trailing control, ColorOS's editor rows.
class EditorRow extends StatelessWidget {
  const EditorRow({super.key, this.icon, this.iconColor, required this.child, this.trailing});

  final IconData? icon;
  final Color? iconColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: icon == null ? null : Icon(icon, size: 24, color: iconColor ?? OneUITheme.textSecondary),
          ),
          Expanded(child: child),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

/// Underlined text field (white underline when focused), stateless over [value].
class EditorField extends StatelessWidget {
  const EditorField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.focusNode,
    this.capitalization = TextCapitalization.sentences,
  });

  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      autofocus: autofocus,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: 1,
      textCapitalization: capitalization,
      style: const TextStyle(fontSize: 18, color: OneUITheme.textPrimary),
      cursorColor: OneUITheme.accentBlue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 18, color: OneUITheme.textTertiary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: OneUITheme.textPrimary, width: 2)),
      ),
    );
  }
}

/// Blue "Mobile ˅" label above a field; opens the label menu (with "Custom").
class LabelButton extends StatefulWidget {
  const LabelButton({super.key, required this.label, required this.options, required this.onChanged});

  final String label;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<LabelButton> createState() => _LabelButtonState();
}

class _LabelButtonState extends State<LabelButton> {
  final _anchor = GlobalKey();

  Future<void> _custom() async {
    final text = await OneUIFloatingModal.showTextInputDialog(
      context: context,
      title: 'Custom label',
      initialValue: widget.options.contains(widget.label) ? '' : widget.label,
      confirmLabel: 'OK',
    );
    if (text != null && text.trim().isNotEmpty) widget.onChanged(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        key: _anchor,
        borderRadius: BorderRadius.circular(8),
        onTap: () => OneUIFloatingMenu.show(
          context: context,
          anchorKey: _anchor,
          items: [
            for (final o in widget.options)
              OneUIFloatingMenuItem(label: labelDisplay(o), onTap: () => widget.onChanged(o)),
            OneUIFloatingMenuItem(label: 'Custom', onTap: _custom),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelDisplay(widget.label),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.accentBlue),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: OneUITheme.accentBlue),
            ],
          ),
        ),
      ),
    );
  }
}

/// Samsung's red "—" remove control.
class RemoveButton extends StatelessWidget {
  const RemoveButton({super.key, required this.onPressed, this.tooltip = 'Remove'});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(width: 22, height: 2.5, color: OneUITheme.accentRed),
    );
  }
}

/// Green "+" row ("Add phone number").
class AddRow extends StatelessWidget {
  const AddRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: EditorRow(
        icon: Icons.add_rounded,
        iconColor: OneUITheme.accentGreen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label, style: const TextStyle(fontSize: 18, color: OneUITheme.textTertiary)),
        ),
      ),
    );
  }
}

/// A collapsed section ("Email", "Work info") that opens when tapped.
class PlaceholderRow extends StatelessWidget {
  const PlaceholderRow({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: OneUITheme.cardBorderRadius,
      child: EditorRow(
        icon: icon,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(label, style: const TextStyle(fontSize: 18, color: OneUITheme.textSecondary)),
        ),
      ),
    );
  }
}

/// Label choices per field, in Samsung's order.
abstract final class EditorLabels {
  static const phone = ['mobile', 'home', 'work', 'main', 'workFax', 'homeFax', 'pager', 'other'];
  static const email = ['home', 'work', 'other'];
  static const address = ['home', 'work', 'other'];
  static const date = ['birthday', 'anniversary', 'other'];
  static const website = ['homepage', 'blog', 'profile', 'home', 'work', 'other'];
  static const relation = [
    'assistant',
    'brother',
    'child',
    'domesticPartner',
    'father',
    'friend',
    'manager',
    'mother',
    'parent',
    'partner',
    'referredBy',
    'relative',
    'sister',
    'spouse',
  ];
}
