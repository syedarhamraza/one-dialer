import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';

/// Item definition for the Samsung One UI Floating Expanded Menu.
class OneUIFloatingMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const OneUIFloatingMenuItem({required this.label, this.icon, required this.onTap});
}

/// Samsung One UI Floating Expanded Menu matching Screenshot 3 1:1.
/// Features:
/// - Strictly transparent background barrier (NO dimming / NO dark overlay).
/// - Displays directly ON TOP OF (overlapping & covering) the floating pill.
/// - Exact same design tokens as the floating pills and buttons:
///   stadium curvature (26 radius), 3D gradient/border/shadow, OneUITheme tokens.
/// - Snappy top-right scale and fade transition.
class OneUIFloatingMenu {
  /// Global state tracking whether the expanded menu is currently active.
  /// Used by headers and floating action pills to gracefully fade out their
  /// anchor during menu display, preventing any corner slivers or background peeking.
  static final ValueNotifier<bool> isOpen = ValueNotifier<bool>(false);

  static Future<void> show({
    required BuildContext context,
    required List<OneUIFloatingMenuItem> items,
    GlobalKey? anchorKey,
    double fallbackTop = 54.0,
    double? fallbackBottom,
    double fallbackRight = 16.0,
    double width = 200.0,
  }) async {
    double? top = fallbackTop;
    double? bottom = fallbackBottom;
    double right = fallbackRight;
    bool isBottomAnchor = false;

    if (anchorKey?.currentContext != null) {
      final box = anchorKey!.currentContext!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final origin = box.localToGlobal(Offset.zero);
        final screenSize = MediaQuery.of(context).size;

        if (origin.dy > screenSize.height * 0.5) {
          isBottomAnchor = true;
          // Clear 14px floating gap above the bottom selection bar
          bottom = (screenSize.height - origin.dy) + 14.0;
          top = null;
          // Align menu right edge with the selection bar container edge (~8px past the button)
          final barRightEdgeDistance = screenSize.width - (origin.dx + box.size.width + 8.0);
          right = barRightEdgeDistance.clamp(16.0, screenSize.width - width - 16.0);
        } else {
          isBottomAnchor = false;
          top = origin.dy;
          bottom = null;
          right = (screenSize.width - (origin.dx + box.size.width)).clamp(16.0, 50.0);
        }
      }
    } else if (fallbackBottom != null) {
      isBottomAnchor = true;
      top = null;
    }

    isOpen.value = true;
    try {
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss menu',
        barrierColor: Colors.transparent, // STRICTLY TRANSPARENT - NO DARK OVERLAY
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, anim1, anim2) {
          return _OneUIFloatingMenuContent(
            items: items,
            top: top,
            bottom: bottom,
            right: right,
            width: width,
            animation: anim1,
            isBottomAnchor: isBottomAnchor,
          );
        },
        transitionBuilder: (ctx, anim, secondaryAnim, child) => child,
      );
    } finally {
      isOpen.value = false;
    }
  }
}

class _OneUIFloatingMenuContent extends StatefulWidget {
  final List<OneUIFloatingMenuItem> items;
  final double? top;
  final double? bottom;
  final double right;
  final double width;
  final Animation<double> animation;
  final bool isBottomAnchor;

  const _OneUIFloatingMenuContent({
    required this.items,
    this.top,
    this.bottom,
    required this.right,
    required this.width,
    required this.animation,
    required this.isBottomAnchor,
  });

  @override
  State<_OneUIFloatingMenuContent> createState() => _OneUIFloatingMenuContentState();
}

class _OneUIFloatingMenuContentState extends State<_OneUIFloatingMenuContent> {
  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_handleStatusChanged);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      OneUIFloatingMenu.isOpen.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForward =
        widget.animation.status == AnimationStatus.forward || widget.animation.status == AnimationStatus.completed;

    // Samsung One UI signature fluid deceleration curve
    final scaleCurve = isForward ? const Cubic(0.16, 1.0, 0.3, 1.0) : Curves.easeInCubic;

    // Rapid crisp fade in on open (solid within 110ms); gentle fade out on close
    final opacityCurve = isForward
        ? const Interval(0.0, 0.45, curve: Curves.easeOut)
        : const Interval(0.15, 1.0, curve: Curves.easeIn);

    final scaleAnimation = Tween<double>(
      begin: 0.80,
      end: 1.0,
    ).animate(CurvedAnimation(parent: widget.animation, curve: scaleCurve));

    final opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: widget.animation, curve: opacityCurve));

    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: widget.top,
              bottom: widget.bottom,
              right: widget.right,
              width: widget.width,
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  alignment: widget.isBottomAnchor ? const Alignment(0.85, 0.95) : const Alignment(0.85, -0.85),
                  child: Material(
                    color: Colors.transparent,
                    child: OneUIGlassSurface(
                      borderRadius: const BorderRadius.all(Radius.circular(22)),
                      elevation: OneUIGlassElevation.modal,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in widget.items)
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                item.onTap();
                              },
                              borderRadius: BorderRadius.circular(16),
                              splashColor: Colors.white.withValues(alpha: 0.08),
                              highlightColor: Colors.white.withValues(alpha: 0.04),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    if (item.icon != null) ...[
                                      Icon(item.icon, size: 19, color: OneUITheme.textPrimary),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: OneUITheme.textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
