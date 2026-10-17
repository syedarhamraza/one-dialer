import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';

/// Ported from OneSpend's `one_ui_floating_nav_bar.dart` (flat style). OneSpend's
/// docked-actions morph is not ported yet; add it with multi-select in Recents.
class OneUINavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const OneUINavItem({required this.activeIcon, required this.inactiveIcon, required this.label});
}

class OneUIFloatingNavBar extends StatelessWidget {
  const OneUIFloatingNavBar({super.key, required this.currentIndex, required this.onTap, required this.items});

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<OneUINavItem> items;

  /// Width of each tab's tap target; the gap between tabs never changes.
  static const double itemWidth = 74;

  /// How far the selected capsule reaches past its own slot on each side.
  static const double pillOverhang = 6;

  static const double barHeight = 60;
  static const double _verticalInset = 4;
  static const double _horizontalInset = pillOverhang + _verticalInset;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    const pillRadius = BorderRadius.all(Radius.circular((barHeight - _verticalInset * 2) / 2));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1, // as tall as the bar; as a Scaffold.bottomNavigationBar it'd fill the screen
          child: RepaintBoundary(
            child: OneUIGlassSurface(
              navbar: true,
              height: barHeight,
              padding: const EdgeInsets.symmetric(horizontal: _horizontalInset, vertical: _verticalInset),
              child: SizedBox(
                width: itemWidth * items.length,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // One sliding capsule behind the row, so switching tabs glides it across.
                    AnimatedPositioned(
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      top: 0,
                      bottom: 0,
                      left: currentIndex * itemWidth - pillOverhang,
                      width: itemWidth + pillOverhang * 2,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: OneUITheme.surfacePillActive, borderRadius: pillRadius),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < items.length; i++) _item(items[i], i == currentIndex, () => onTap(i)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(OneUINavItem item, bool isSelected, VoidCallback onTap) {
    final color = isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary;
    return SizedBox(
      width: itemWidth,
      child: Semantics(
        selected: isSelected,
        button: true,
        label: item.label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? item.activeIcon : item.inactiveIcon, size: 21, color: color),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                  color: color,
                ),
                child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
