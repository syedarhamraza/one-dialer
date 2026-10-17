import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_bottom_vignette.dart';
import 'one_ui_collapsible_header.dart';
import '../theme/one_ui_scroll.dart';

/// Standard One UI subpage (design doc §5.1): pinned small header with a back button,
/// padded scrolling content, the bottom vignette and an optional floating pill.
///
/// [builder] runs again whenever [listenable] notifies, so rows can show live values.
class OneUISubpage extends StatelessWidget {
  final String title;
  final List<Widget> Function(BuildContext context) builder;
  final Listenable? listenable;

  /// Floating bottom control, e.g. `OneUIFloatingCancelSavePill`.
  final Widget? bottomPill;
  final VoidCallback? onBack;

  const OneUISubpage({
    super.key,
    required this.title,
    required this.builder,
    this.listenable,
    this.bottomPill,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Widget content(BuildContext context) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: builder(context));

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const OneUIScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: title,
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: onBack ?? () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  child: listenable == null
                      ? content(context)
                      : AnimatedBuilder(animation: listenable!, builder: (context, _) => content(context)),
                ),
              ),
            ],
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
          if (bottomPill != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(child: bottomPill),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small "Soon" capsule for rows whose feature isn't built yet.
class OneUISoonChip extends StatelessWidget {
  const OneUISoonChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: OneUITheme.surfacePill,
        borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
      ),
      child: const Text(
        'Soon',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
      ),
    );
  }
}

/// Small orange dot marking something new on a row, e.g. an available update.
class OneUIDot extends StatelessWidget {
  const OneUIDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(color: OneUITheme.accentOrange, shape: BoxShape.circle),
    );
  }
}

/// 36dp solid circle list badge with a white icon (design doc §4, "Leading icon badges").
/// [compact] is the smaller 32dp badge Settings uses on low-density or narrow screens.
class OneUIIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool compact;

  const OneUIIconBadge(this.icon, this.color, {super.key, this.compact = false});

  /// Whether badges should be [compact] here: a low-density screen, or a narrow one.
  static bool compactFor(BuildContext context) =>
      MediaQuery.devicePixelRatioOf(context) < 2.5 || MediaQuery.sizeOf(context).width < 380;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 36.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: compact ? 18 : 20),
    );
  }
}
