import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_floating_menu.dart';
import 'one_ui_group_card.dart';
import 'one_ui_switch.dart';

/// A settings row with a switch on the right; tapping the row flips it too. When not [enabled]
/// (another setting makes it redundant, which [subtitle] should say) it can't be flipped and the
/// switch is dimmed, keeping its saved value for when it applies again.
OneUIGroupItem switchRow(
  String title,
  ValueNotifier<bool> value,
  ValueChanged<bool> onChanged, {
  String? subtitle,
  bool enabled = true,
}) => OneUIGroupItem(
  title: title,
  subtitle: subtitle,
  onTap: enabled ? () => onChanged(!value.value) : null,
  trailing: ValueListenableBuilder(
    valueListenable: value,
    builder: (context, v, _) => enabled
        ? OneUISwitch(value: v, onChanged: onChanged)
        : Opacity(
            opacity: .4,
            child: IgnorePointer(
              child: OneUISwitch(value: v, onChanged: (_) {}),
            ),
          ),
  ),
);

/// A settings row whose current choice shows on the right in grey before a chevron, as
/// ColorOS settings show values; tapping it opens the choices from there. A value missing
/// from [labels] shows [fallback], else the first label. When not [enabled] (another setting
/// makes it unused, which [subtitle] should say) it can't be opened and its value is dimmed,
/// keeping the saved choice for when it applies again.
OneUIGroupItem choiceRow(
  BuildContext context, {
  required String title,
  String? subtitle,
  required GlobalKey anchor,
  required ValueNotifier<String?> value,
  required Map<String, String> labels,
  required ValueChanged<String> onPick,
  String? fallback,
  bool enabled = true,
}) => OneUIGroupItem(
  title: title,
  subtitle: subtitle,
  trailing: Opacity(
    opacity: enabled ? 1 : .4,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: value,
          builder: (context, v, _) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              labels[v] ?? fallback ?? labels.values.firstOrNull ?? '',
              key: anchor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, size: 22, color: context.palette.textSecondary),
      ],
    ),
  ),
  onTap: !enabled
      ? null
      : () => OneUIFloatingMenu.show(
          context: context,
          anchorKey: anchor,
          width: 250,
          items: [
            for (final MapEntry(:key, value: label) in labels.entries)
              OneUIFloatingMenuItem(
                label: label,
                icon: key == value.value ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                onTap: () => onPick(key),
              ),
          ],
        ),
);
