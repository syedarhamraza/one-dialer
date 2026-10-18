import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/one_ui_theme.dart';
import 'frosted_body.dart';
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
            // The whole bar presses as one, outside the tabs' own taps.
            child: GlassPress(
              radius: OneUIFloatingNavBar._barHeight / 2,
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
      ),
    );
  }

  /// The package's tab bar for its motion (the indicator slides and stretches as you drag between
  /// tabs, and glows on touch), with its glass optics turned off: our frosted surface stays the body.
  Widget _buildTabs(BuildContext context, bool reduceMotion) {
    final fx = OneUIEffectsController.instance;
    const noGlass = LiquidGlassSettings(
      glassColor: Color(0x00000000),
      thickness: 0,
      blur: 0,
      chromaticAberration: 0,
      lightIntensity: 0,
      glowIntensity: 0,
      saturation: 1,
      refractiveIndex: 1,
      shadowElevation: 0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OneUIFloatingNavBar._horizontalInset),
      child: SizedBox(
        width: OneUIFloatingNavBar.itemWidth * widget.items.length,
        child: GlassTabBar.bottom(
          tabs: [
            for (final item in widget.items)
              GlassTab(icon: Icon(item.inactiveIcon), activeIcon: Icon(item.activeIcon), label: item.label),
          ],
          selectedIndex: widget.currentIndex,
          onTabSelected: widget.onTap,
          horizontalPadding: 0,
          verticalPadding: 0,
          spacing: 0,
          barHeight: OneUIFloatingNavBar._barHeight,
          tabWidth: OneUIFloatingNavBar.itemWidth,
          iconSize: 21,
          labelFontSize: 11.5,
          selectedIconColor: OneUITheme.textPrimary,
          unselectedIconColor: OneUITheme.textSecondary,
          selectedLabelColor: OneUITheme.textPrimary,
          unselectedLabelColor: OneUITheme.textSecondary,
          quality: GlassQuality.minimal,
          backgroundQuality: GlassQuality.minimal,
          settings: noGlass,
          indicatorColor: fx.activePillColor,
          indicatorSettings: noGlass.copyWith(glassColor: fx.activePillColor),
          indicatorPinchStrength: 0,
          magnification: 1,
          // The whole bar already presses with GlassPress.
          pressScale: 1,
        ),
      ),
    );
  }
}
