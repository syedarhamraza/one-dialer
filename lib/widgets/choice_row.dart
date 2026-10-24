import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_floating_menu.dart';
import 'one_ui_group_card.dart';

/// A settings row whose current choice shows on the right in grey before a chevron, as
/// ColorOS settings show values; tapping it opens the choices from there. A value missing
/// from [labels] shows [fallback], else the first label.
OneUIGroupItem choiceRow(
  BuildContext context, {
  required String title,
  String? subtitle,
  required GlobalKey anchor,
  required ValueNotifier<String?> value,
  required Map<String, String> labels,
  required ValueChanged<String> onPick,
  String? fallback,
}) => OneUIGroupItem(
  title: title,
  subtitle: subtitle,
  trailing: Row(
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
            style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
          ),
        ),
      ),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right_rounded, size: 22, color: OneUITheme.textSecondary),
    ],
  ),
  onTap: () => OneUIFloatingMenu.show(
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
