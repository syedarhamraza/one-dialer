import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// Ported from OneSpend's `one_ui_group_card.dart` (flat card, no appearance settings).
class OneUIGroupItem {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const OneUIGroupItem({
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
  });
}

class OneUIGroupCard extends StatelessWidget {
  final List<OneUIGroupItem> items;
  final String? headerTitle;
  final EdgeInsetsGeometry? margin;

  const OneUIGroupCard({super.key, required this.items, this.headerTitle, this.margin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerTitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6, top: 14),
            child: Text(
              headerTitle!,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: OneUITheme.sectionHeader,
              ),
            ),
          ),
        Container(
          margin: margin ?? const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: OneUITheme.surfaceCard,
            borderRadius: OneUITheme.cardBorderRadius,
          ),
          child: Column(
            children: [
              for (int index = 0; index < items.length; index++)
                _GroupItemTile(item: items[index], isFirst: index == 0, isLast: index == items.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupItemTile extends StatelessWidget {
  final OneUIGroupItem item;
  final bool isFirst;
  final bool isLast;

  const _GroupItemTile({required this.item, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(OneUITheme.radiusCard) : Radius.zero,
              bottom: isLast ? const Radius.circular(OneUITheme.radiusCard) : Radius.zero,
            ),
            splashColor: Colors.white.withValues(alpha: 0.06),
            highlightColor: Colors.white.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (item.leading != null) ...[item.leading!, const SizedBox(width: 16)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            letterSpacing: -0.2,
                            color: OneUITheme.textPrimary,
                          ),
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.25,
                              color: item.subtitleColor ?? OneUITheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  item.trailing ??
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: OneUITheme.textTertiary),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.8,
            indent: item.leading != null ? 58 : 16,
            endIndent: 16,
            color: Colors.white.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}
