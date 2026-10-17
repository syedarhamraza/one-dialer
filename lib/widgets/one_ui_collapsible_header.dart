import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import 'one_ui_morph_switcher.dart';
import 'one_ui_floating_menu.dart';
import 'one_ui_status_bar_scrim.dart';
import '../core/haptics/haptics.dart';

/// Reusable action item for One UI top header bar
class OneUIHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double? size;
  final double? width;
  final double? height;
  final GlobalKey? actionKey;

  const OneUIHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size,
    this.width,
    this.height,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        key: actionKey,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: width ?? 36,
          height: height ?? 36,
          alignment: Alignment.center,
          child: Icon(icon, size: size ?? 21, color: OneUITheme.textPrimary),
        ),
      ),
    );
  }
}

/// Samsung One UI 9 Signature Collapsible Header Delegate.
///
/// Features:
/// 1. [hasBigHeader == true] (Main Pages):
///    - Initial (unscrolled): Big centered title perfectly centered vertically between the status bar
///      and the action bar row. Buttons (< and actions) sit directly above the first card.
///    - Scrolled: Big header fades out; the buttons row travels with the scrolling cards up to the pinned
///      top bar; the small title fades in beside the back button (or at left: 20 if no back button).
///    - Deep scroll: Small title hides INSTANTLY; buttons gain 3D floating pill backgrounds matching the navbar.
/// 2. [hasBigHeader == false] (Sub Setting Pages):
///    - Compact top bar with `< Title` (no big viewing area).
///    - Deep scroll: Title hides INSTANTLY; buttons gain 3D floating pill backgrounds.
class OneUICollapsibleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final bool hasBigHeader;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final GlobalKey? actionsPillKey;
  final double expandedHeight;
  final double collapsedHeight;
  final bool isSelectionMode;
  final Widget? selectionLeading;
  final Widget? selectionTrailing;

  /// Selection-mode Cancel. When set, the right-hand actions pill and the Cancel
  /// pill are one glass capsule that morphs between the two (instead of
  /// [selectionTrailing] replacing the actions outright).
  final VoidCallback? onSelectionCancel;

  const OneUICollapsibleHeaderDelegate({
    required this.title,
    this.subtitle,
    this.hasBigHeader = true,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.actionsPillKey,
    this.expandedHeight = 270.0, // Balanced One UI viewing area with reduced bottom space
    this.collapsedHeight = 92.0, // Compact top bar height including status bar
    this.isSelectionMode = false,
    this.selectionLeading,
    this.selectionTrailing,
    this.onSelectionCancel,
  });

  @override
  double get maxExtent => hasBigHeader ? expandedHeight : collapsedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;

    return _OneUIHeaderContent(
      title: title,
      subtitle: subtitle,
      hasBigHeader: hasBigHeader,
      showBackButton: showBackButton,
      onBack: onBack,
      actions: actions,
      actionsPillKey: actionsPillKey,
      shrinkOffset: shrinkOffset,
      topPadding: topPadding,
      expandedHeight: maxExtent,
      collapsedHeight: minExtent,
      isSelectionMode: isSelectionMode,
      selectionLeading: selectionLeading,
      selectionTrailing: selectionTrailing,
      onSelectionCancel: onSelectionCancel,
    );
  }

  @override
  bool shouldRebuild(covariant OneUICollapsibleHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.hasBigHeader != hasBigHeader ||
        oldDelegate.showBackButton != showBackButton ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.actions != actions ||
        oldDelegate.actionsPillKey != actionsPillKey ||
        oldDelegate.isSelectionMode != isSelectionMode ||
        oldDelegate.selectionLeading != selectionLeading ||
        oldDelegate.selectionTrailing != selectionTrailing ||
        oldDelegate.onSelectionCancel != onSelectionCancel;
  }
}

class _OneUIHeaderContent extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool hasBigHeader;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final GlobalKey? actionsPillKey;
  final double shrinkOffset;
  final double topPadding;
  final double expandedHeight;
  final double collapsedHeight;
  final bool isSelectionMode;
  final Widget? selectionLeading;
  final Widget? selectionTrailing;
  final VoidCallback? onSelectionCancel;

  const _OneUIHeaderContent({
    required this.title,
    this.subtitle,
    required this.hasBigHeader,
    required this.showBackButton,
    this.onBack,
    this.actions,
    this.actionsPillKey,
    required this.shrinkOffset,
    required this.topPadding,
    required this.expandedHeight,
    required this.collapsedHeight,
    this.isSelectionMode = false,
    this.selectionLeading,
    this.selectionTrailing,
    this.onSelectionCancel,
  });

  @override
  State<_OneUIHeaderContent> createState() => _OneUIHeaderContentState();
}

class _OneUIHeaderContentState extends State<_OneUIHeaderContent> {
  ScrollPosition? _position;
  double _lastPixels = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (_position != newPosition) {
      _position?.removeListener(_onScroll);
      _position = newPosition;
      _position?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final pixels = _position?.pixels ?? 0.0;
    // For big header, pill transition zone is between 175.0 and 255.0.
    // For compact header, pill transition zone is between 45.0 and 105.0.
    final double lowerThreshold = widget.hasBigHeader ? 175.0 : 45.0;
    final double upperThreshold = widget.hasBigHeader ? 255.0 : 105.0;

    final wasInTransition = _lastPixels >= lowerThreshold && _lastPixels <= upperThreshold;
    final isInTransition = pixels >= lowerThreshold && pixels <= upperThreshold;
    final crossedUpper =
        (_lastPixels < upperThreshold && pixels >= upperThreshold) ||
        (_lastPixels >= upperThreshold && pixels < upperThreshold);
    final crossedLower =
        (_lastPixels > lowerThreshold && pixels <= lowerThreshold) ||
        (_lastPixels <= lowerThreshold && pixels > lowerThreshold);

    if (isInTransition || wasInTransition || crossedUpper || crossedLower) {
      _lastPixels = pixels;
      setState(() {});
    } else {
      _lastPixels = pixels;
    }
  }

  /// Circular back button whose glass backing grows in as the header collapses.
  Widget _buildBackButton(BuildContext context, double pillProgress) {
    if (!widget.showBackButton) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: 'Back',
        child: GestureDetector(
          onTap: widget.onBack ?? () => Navigator.maybePop(context),
          behavior: HitTestBehavior.opaque,
          child: OneUIGlassSurface.circle(
            size: 44,
            progress: pillProgress,
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: OneUITheme.textPrimary),
          ),
        ),
      ),
    );
  }

  /// Right-hand capsule. Outside selection mode it holds the action buttons (its
  /// glass grows in as the header collapses); in selection mode the same capsule
  /// reshapes into "Cancel", so the pill morphs rather than swapping.
  Widget? _buildRightPill(BuildContext context, double pillProgress, double selectionT) {
    final inSelection = widget.isSelectionMode;
    final hasActions = widget.actions != null && widget.actions!.isNotEmpty;
    final morphCancel = widget.onSelectionCancel != null;

    // Legacy path: a caller-supplied trailing widget simply replaces the actions.
    if (inSelection && !morphCancel) return widget.selectionTrailing;

    final Widget content;
    if (inSelection) {
      content = Semantics(
        key: const ValueKey('cancel'),
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Haptics.tap();
            widget.onSelectionCancel!();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              widthFactor: 1,
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: OneUITheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (hasActions) {
      final isSingleAction = widget.actions!.length == 1;
      content = isSingleAction
          ? SizedBox(
              key: const ValueKey('actions'),
              width: 44,
              child: Center(child: widget.actions!.first),
            )
          : Padding(
              key: const ValueKey('actions'),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (int i = 0; i < widget.actions!.length; i++) ...[
                    widget.actions![i],
                    if (i < widget.actions!.length - 1) const SizedBox(width: 4.0),
                  ],
                ],
              ),
            );
    } else if (selectionT > 0) {
      // Leaving selection into a state with no actions: let Cancel morph away.
      content = const SizedBox(key: ValueKey('empty'), height: 44);
    } else {
      return null;
    }

    final pill = OneUIGlassSurface(
      key: widget.actionsPillKey,
      height: 44,
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      progress: math.max(pillProgress, selectionT),
      // The capsule stretches leftwards from its right edge while its content
      // fades through (see OneUIMorphSwitcher).
      child: OneUIMorphSwitcher(alignment: Alignment.centerRight, child: content),
    );

    return RepaintBoundary(
      child: ValueListenableBuilder<bool>(
        valueListenable: OneUIFloatingMenu.isOpen,
        builder: (context, isMenuOpen, child) {
          return AnimatedOpacity(
            opacity: isMenuOpen ? 0.0 : 1.0,
            duration: Duration(milliseconds: isMenuOpen ? 100 : 160),
            curve: isMenuOpen ? Curves.easeIn : Curves.easeOut,
            child: child!,
          );
        },
        child: pill,
      ),
    );
  }

  static Duration _morphDuration(BuildContext context) => OneUIMorphSwitcher.durationOf(context);

  /// Small Title in top bar
  Widget _buildSmallTitle(double smallTitleOpacity) {
    if (smallTitleOpacity <= 0.01) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: smallTitleOpacity,
      child: Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: OneUITheme.textPrimary,
        ),
      ),
    );
  }

  /// Big centered viewing header with generous space and fixed height to prevent overflow.
  /// As the page scrolls ([glide] 0 → 1) the title shrinks towards the top bar's size and
  /// drifts up while it fades, so it reads as gliding into the small title.
  Widget _buildBigHeader(double bigHeaderOpacity, double glide) {
    if (!widget.hasBigHeader || bigHeaderOpacity <= 0.01) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: bigHeaderOpacity,
      child: Transform.translate(
        offset: Offset(0, -44 * glide),
        child: Transform.scale(
          scale: 1 - 0.35 * glide,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 34.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 5),
                    // The subtitle has no place in the top bar, so it fades first.
                    Opacity(
                      opacity: (1 - 2 * glide).clamp(0.0, 1.0),
                      child: Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: OneUITheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = widget.topPadding;
    final double currentOffset = (_position?.hasPixels == true ? _position!.pixels : widget.shrinkOffset).clamp(
      0.0,
      double.infinity,
    );

    final double bigHeaderOpacity;
    final double smallTitleOpacity;
    final double pillProgress;

    // Keep top space identical to before (~75dp below status bar), while bottom space is reduced
    const double bigHeaderHeight = 75.0;
    final double bigHeaderTop = topPadding + 75.0;

    if (widget.hasBigHeader) {
      // 1. Big header fades out gracefully as user scrolls
      bigHeaderOpacity = (1.0 - (currentOffset / 100.0)).clamp(0.0, 1.0);

      // 2. Small title:
      // Fades in between 50px and 115px as the action bar row travels up to the top.
      // Stays fully visible while in top bar (115px to 190px).
      // On deep scroll (> 190px), hides INSTANTLY!
      if (currentOffset <= 50.0) {
        smallTitleOpacity = 0.0;
      } else if (currentOffset < 115.0) {
        smallTitleOpacity = ((currentOffset - 50.0) / 65.0).clamp(0.0, 1.0);
      } else if (currentOffset <= 190.0) {
        smallTitleOpacity = 1.0;
      } else {
        // Hides instantly on deep scroll!
        smallTitleOpacity = 0.0;
      }

      // 3. Floating 3D Pill Progress: appears smoothly with scroll as user scrolls deeper!
      if (currentOffset <= 190.0) {
        pillProgress = 0.0;
      } else {
        pillProgress = ((currentOffset - 190.0) / 60.0).clamp(0.0, 1.0);
      }
    } else {
      // Sub setting pages: no big header, compact top bar from the start
      bigHeaderOpacity = 0.0;

      // Small title: visible at top (0 to 50px) -> hides INSTANTLY on deep scroll (> 50px)!
      if (currentOffset <= 50.0) {
        smallTitleOpacity = 1.0;
        pillProgress = 0.0;
      } else {
        smallTitleOpacity = 0.0;
        pillProgress = ((currentOffset - 50.0) / 50.0).clamp(0.0, 1.0);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 0. Status Bar Scrim (Edge-to-Edge Progressive Blur & Gradient Scrim, strictly 80% of status bar)
        const Positioned(top: 0, left: 0, right: 0, child: OneUIStatusBarScrim()),

        // 1. Big Centered Header (Strictly centered vertically in viewing area)
        if (widget.hasBigHeader && bigHeaderOpacity > 0.01)
          Positioned(
            top: bigHeaderTop,
            left: 0,
            right: 0,
            height: bigHeaderHeight,
            child: _buildBigHeader(bigHeaderOpacity, (currentOffset / 115.0).clamp(0.0, 1.0)),
          ),

        // 2. Action Bar Row (Buttons & Small Title OR Selection Controls)
        // Anchored to bottom: 4.0 of the sliver, directly above the first card!
        Positioned(
          bottom: 4.0,
          left: 20.0,
          right: 20.0,
          height: 44.0,
          // Selection mode eases in/out so the right capsule's glass can morph too.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: widget.isSelectionMode ? 1.0 : 0.0),
            duration: _morphDuration(context),
            curve: Curves.easeOutCubic,
            builder: (context, selectionT, _) {
              final rightPill = _buildRightPill(context, pillProgress, selectionT);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: OneUIMorphSwitcher(
                      alignment: Alignment.centerLeft,
                      animateSize: false,
                      child: widget.isSelectionMode
                          // A Row lets the leading pill keep its natural width
                          // instead of stretching across the header.
                          ? Row(
                              key: const ValueKey('selection'),
                              children: [widget.selectionLeading ?? const SizedBox.shrink()],
                            )
                          : Row(
                              key: const ValueKey('normal'),
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (widget.showBackButton) ...[
                                  _buildBackButton(context, pillProgress),
                                  const SizedBox(width: 10.0),
                                ],
                                // Starts at the screen edge, or beside the back button.
                                Expanded(child: _buildSmallTitle(smallTitleOpacity)),
                              ],
                            ),
                    ),
                  ),
                  if (rightPill != null) ...[const SizedBox(width: 8.0), rightPill],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
