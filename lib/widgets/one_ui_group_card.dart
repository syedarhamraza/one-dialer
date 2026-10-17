import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

class OneUIGroupItem {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? customSubtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const OneUIGroupItem({
    this.leading,
    required this.title,
    this.subtitle,
    this.customSubtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });
}

class OneUIGroupCard extends StatelessWidget {
  final List<OneUIGroupItem> items;
  final String? headerTitle;
  final EdgeInsetsGeometry? margin;

  const OneUIGroupCard({super.key, required this.items, this.headerTitle, this.margin});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
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
                    color: Color(0xFFD4D4D8),
                  ),
                ),
              ),
            Container(
              margin: margin ?? const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: OneUIEffectsController.instance.resolveCardBackground(),
                borderRadius: OneUITheme.cardBorderRadius,
                border: OneUITheme.cardBorder,
                boxShadow: OneUITheme.cardShadow,
              ),
              child: Column(
                children: [
                  for (int index = 0; index < items.length; index++)
                    OneUIGroupItemTile(item: items[index], isFirst: index == 0, isLast: index == items.length - 1),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual item tile within a OneUIGroupCard.
/// Extracted to a standalone widget to enable fine-grained element reuse and O(1) layout caching.
class OneUIGroupItemTile extends StatelessWidget {
  final OneUIGroupItem item;
  final bool isFirst;
  final bool isLast;

  const OneUIGroupItemTile({super.key, required this.item, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            // Flutter's own long-press buzz would play on top of the row's Haptics.longPress,
            // so it's off; the tap click sound is played by hand instead.
            enableFeedback: item.onLongPress == null,
            onTap: item.onTap == null || item.onLongPress == null
                ? item.onTap
                : () {
                    Feedback.forTap(context);
                    item.onTap!();
                  },
            onLongPress: item.onLongPress,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(26) : Radius.zero,
              bottom: isLast ? const Radius.circular(26) : Radius.zero,
            ),
            splashColor: Colors.white.withValues(alpha: 0.06),
            highlightColor: Colors.white.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                            letterSpacing: -0.2,
                            color: OneUITheme.textPrimary,
                          ),
                        ),
                        if (item.customSubtitle != null) ...[
                          const SizedBox(height: 1),
                          item.customSubtitle!,
                        ] else if (item.subtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.normal,
                              height: 1.25,
                              color: item.subtitleColor ?? OneUITheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  if (item.trailing != null)
                    item.trailing!
                  else
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
