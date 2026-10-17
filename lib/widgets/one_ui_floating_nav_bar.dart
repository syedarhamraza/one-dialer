import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import 'one_ui_morph_switcher.dart';

class OneUINavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const OneUINavItem({required this.activeIcon, required this.inactiveIcon, required this.label});
}

class OneUIFloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<OneUINavItem> items;

  /// A tab's bottom actions (e.g. selection mode's Share | Delete | More). While
  /// set, the same glass bar reshapes around them instead of a second bar
  /// replacing this one; clearing it morphs back to the tabs.
  final Widget? dockedContent;

  const OneUIFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.dockedContent,
  });

  /// Width of each tab's tap target; the gap between tabs never changes.
  static const double itemWidth = 74;

  /// How far the selected capsule reaches past its own slot on each side. Only one
  /// tab is selected at a time, so it can borrow a little of its neighbours' space
  /// (like One UI 8.5) without widening the bar's item spacing.
  static const double pillOverhang = 6;

  static const double _barHeight = 60;
  static const double _verticalInset = 4;

  /// Edge padding: the first/last capsule's overhang plus the same gap the capsule
  /// keeps above and below, so it sits evenly inset at the ends of the bar.
  static const double _horizontalInset = pillOverhang + _verticalInset;

  @override
  State<OneUIFloatingNavBar> createState() => _OneUIFloatingNavBarState();
}

class _OneUIFloatingNavBarState extends State<OneUIFloatingNavBar> {
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final docked = widget.dockedContent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: RepaintBoundary(
            child: OneUIGlassSurface(
              elevation: OneUIGlassElevation.navbar,
              height: OneUIFloatingNavBar._barHeight,
              // One glass bar that stretches between the tabs and a tab's docked
              // actions, fading through its content (see OneUIMorphSwitcher).
              child: OneUIMorphSwitcher(
                child: docked != null
                    ? KeyedSubtree(key: const ValueKey('docked'), child: docked)
                    : KeyedSubtree(key: const ValueKey('tabs'), child: _buildTabs(context, reduceMotion)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, bool reduceMotion) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final fx = OneUIEffectsController.instance;
        final is3d = fx.floating3dEffect;
        const itemWidth = OneUIFloatingNavBar.itemWidth;
        const pillOverhang = OneUIFloatingNavBar.pillOverhang;
        const pillWidth = itemWidth + pillOverhang * 2;
        const pillRadius = BorderRadius.all(
          Radius.circular((OneUIFloatingNavBar._barHeight - OneUIFloatingNavBar._verticalInset * 2) / 2),
        );
        final pillGradient = fx.activePillGradient;
        final pillRim = fx.activePillRimGradient;
        final items = widget.items;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OneUIFloatingNavBar._horizontalInset,
            vertical: OneUIFloatingNavBar._verticalInset,
          ),
          child: SizedBox(
            width: itemWidth * items.length,
            child: Stack(
              // Expand so the tab row fills the bar's height and its labels
              // centre vertically (a loose Stack pins them to the top).
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // One sliding capsule behind the row, so switching tabs glides
                // it across instead of fading one out and another in.
                AnimatedPositioned(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  left: widget.currentIndex * itemWidth - pillOverhang,
                  width: pillWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: pillGradient == null ? fx.activePillColor : null,
                      gradient: pillGradient,
                      borderRadius: pillRadius,
                    ),
                    child: pillRim == null
                        ? const SizedBox.expand()
                        : CustomPaint(
                            painter: OneUIRimPainter(gradient: pillRim, borderRadius: pillRadius),
                            child: const SizedBox.expand(),
                          ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == widget.currentIndex;
                    final inactiveColor = is3d ? OneUITheme.navbar3dInactiveIcon : OneUITheme.textSecondary;
                    final inactiveText = is3d ? OneUITheme.navbar3dInactiveText : OneUITheme.textSecondary;

                    return SizedBox(
                      width: itemWidth,
                      child: Semantics(
                        selected: isSelected,
                        button: true,
                        label: item.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => widget.onTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.inactiveIcon,
                                size: 21,
                                color: isSelected ? OneUITheme.textPrimary : inactiveColor,
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  letterSpacing: -0.2,
                                  color: isSelected ? OneUITheme.textPrimary : inactiveText,
                                ),
                                child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
