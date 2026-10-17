import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

class OneUISection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const OneUISection({super.key, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6, top: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Color(0xFFD4D4D8),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class OneUICard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const OneUICard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: OneUITheme.cardBorderRadius,
              splashColor: Colors.white.withValues(alpha: 0.06),
              highlightColor: Colors.white.withValues(alpha: 0.03),
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 16)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: OneUITheme.textPrimary,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.1,
                                color: subtitleColor ?? OneUITheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A card that says a section has nothing to show yet: icon, title, a short hint and an
/// optional tinted pill action. Use it for every in-page empty state so they all match.
class OneUIEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OneUIEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: OneUITheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            Material(
              color: OneUITheme.accentBlue.withValues(alpha: 0.16),
              borderRadius: OneUITheme.pillBorderRadius,
              child: InkWell(
                borderRadius: OneUITheme.pillBorderRadius,
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OneUITheme.accentBlue),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
