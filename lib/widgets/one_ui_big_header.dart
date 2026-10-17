import 'package:flutter/material.dart';

import '../theme/one_ui_scroll.dart';
import '../theme/one_ui_theme.dart';

/// One UI's big centred page title that glides into a small top-bar title on scroll.
/// Use as a pinned `SliverPersistentHeader` with [OneUIScrollPhysics.bigHeader].
///
/// shortcut: OneSpend's `OneUICollapsibleHeaderDelegate` without back button, actions or
/// selection mode; port those parts when a screen needs them.
class OneUIBigHeader extends SliverPersistentHeaderDelegate {
  const OneUIBigHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  // Must match OneUIScrollPhysics.bigHeaderCollapse (270 - 92).
  @override
  double get maxExtent => 270;

  @override
  double get minExtent => 92;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final glide = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final topPadding = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: OneUITheme.surfacePitch,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (glide < 0.99)
            Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Opacity(
                opacity: (1 - glide * 1.6).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -44 * glide),
                  child: Transform.scale(
                    scale: 1 - 0.35 * glide,
                    child: _BigTitle(title: title, subtitle: subtitle, glide: glide),
                  ),
                ),
              ),
            ),
          if (glide > 0.6)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Opacity(
                opacity: ((glide - 0.6) / 0.4).clamp(0.0, 1.0),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(OneUIBigHeader old) => old.title != title || old.subtitle != subtitle;
}

class _BigTitle extends StatelessWidget {
  const _BigTitle({required this.title, required this.subtitle, required this.glide});

  final String title;
  final String? subtitle;
  final double glide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: OneUITheme.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              // The subtitle has no place in the top bar, so it fades first.
              Opacity(
                opacity: (1 - 2 * glide).clamp(0.0, 1.0),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, color: OneUITheme.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
