import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'call_glass.dart';
import 'one_ui_bottom_vignette.dart';
import 'one_ui_floating_action_bar.dart';
import 'one_ui_status_bar_scrim.dart';
import 'round_header_controls.dart';
import '../theme/one_ui_scroll.dart';
import '../l10n/l10n.dart';
import '../app/layout.dart';

/// A ColorOS 17 subpage, laid out like the contact page: black, the round glass Back
/// button with the title beside it pinned at the top, the content (cards) scrolling under
/// the header blur, the bottom vignette and an optional floating pill.
///
/// [builder] runs again whenever [listenable] notifies, so rows can show live values.
class OneUISubpage extends StatelessWidget {
  final String title;
  final List<Widget> Function(BuildContext context)? builder;

  /// Instead of [builder], for long pages: slivers, so rows build lazily as they scroll in.
  final List<Widget> Function(BuildContext context)? slivers;
  final Listenable? listenable;

  /// Floating bottom control, e.g. `OneUIFloatingCancelSavePill`.
  final Widget? bottomPill;
  final VoidCallback? onBack;

  /// Optional 48 dp header, for subpages with an expanding search control.
  final Widget? header;

  const OneUISubpage({
    super.key,
    required this.title,
    this.builder,
    this.slivers,
    this.listenable,
    this.bottomPill,
    this.onBack,
    this.header,
  });

  static const double _button = 48;

  /// A selection's actions as a [bottomPill], in the nav bar's call glass (its docked look).
  static Widget actionBar(List<OneUIFloatingActionBarItem> items) => CallGlass(
    radius: kFloatingNavBarHeight / 2,
    child: SizedBox(
      height: kFloatingNavBarHeight,
      child: OneUIFloatingActionBar(docked: true, items: items),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final insets = EdgeInsets.fromLTRB(
      16,
      padding.top + 8 + _button * headerScale(context) + 20,
      16,
      // 140 at the default size; grows with the bar so the last row still clears it.
      bottomPill == null ? padding.bottom + 32 : 82 + kFloatingNavBarHeight * navBarScale(context),
    );
    Widget content(BuildContext context) => slivers == null
        ? SingleChildScrollView(
            physics: const OneUIScrollPhysics(),
            padding: insets,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: builder!(context)),
          )
        : CustomScrollView(
            physics: const OneUIScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: insets,
                sliver: SliverMainAxisGroup(slivers: slivers!(context)),
              ),
            ],
          );

    return Scaffold(
      backgroundColor: context.palette.page,
      body: Stack(
        // The scroll view must fill the page: shrink-wrapped, a bounce slides the content
        // out of its own box and the bottom gets cut off.
        fit: StackFit.expand,
        children: [
          if (listenable == null)
            content(context)
          else
            AnimatedBuilder(animation: listenable!, builder: (context, _) => content(context)),
          const Positioned(left: 0, right: 0, top: 0, child: OneUIStatusBarScrim()),
          Positioned(
            left: 16,
            right: 16,
            top: padding.top + 8,
            child: HeaderScaled(
              child:
                  header ??
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: context.l10n.back,
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          if (bottomPill != null) ...[
            const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  // Settings › Display size › Navigation bar, grown from the baseline like the main bar.
                  child: Center(
                    child: Transform.scale(
                      scale: navBarScale(context),
                      alignment: Alignment.bottomCenter,
                      child: bottomPill,
                    ),
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

/// Small "Soon" capsule for rows whose feature isn't built yet.
class OneUISoonChip extends StatelessWidget {
  const OneUISoonChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: context.palette.pill,
        borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
      ),
      child: Text(
        context.l10n.soon,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.palette.textSecondary),
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
