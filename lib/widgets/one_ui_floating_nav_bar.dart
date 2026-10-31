import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/one_ui_theme.dart';
import 'call_glass.dart';
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

  /// A round action beside the bar (the dialpad or create-contact button); the bar
  /// and it centre together as one group.
  final Widget? trailing;

  /// A round action on the bar's other side (return to call), popping out the same way.
  final Widget? leading;

  const OneUIFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.dockedContent,
    this.trailing,
    this.leading,
  });

  /// Matches `kFloatingNavBarHeight` (lib/app/layout.dart).
  static const double _barHeight = 58;

  @override
  State<OneUIFloatingNavBar> createState() => _OneUIFloatingNavBarState();
}

class _OneUIFloatingNavBarState extends State<OneUIFloatingNavBar> {
  /// Room for the trailing action (as wide as the bar is tall) plus its gap.
  static const double _slot = OneUIFloatingNavBar._barHeight + 10;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final docked = widget.dockedContent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          // Equal slots either side keep the bar centred on screen. Laid out right to
          // left so the action's slot paints first, under the bar it slides out from.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(
                width: _slot,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 550),
                    reverseDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                    switchInCurve: const _SpringCurve(),
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => _pop(child, animation, from: -1),
                    child: widget.trailing ?? const SizedBox.shrink(),
                  ),
                ),
              ),
              RepaintBoundary(child: _pill(docked, reduceMotion)),
              SizedBox(
                width: _slot,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 550),
                    reverseDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                    switchInCurve: const _SpringCurve(),
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => _pop(child, animation, from: 1),
                    child: widget.leading ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(Widget? docked, bool reduceMotion) {
    // Styled and pressed exactly like the connected call screen's controls.
    return CallGlass(
      radius: OneUIFloatingNavBar._barHeight / 2,
      child: SizedBox(
        height: OneUIFloatingNavBar._barHeight,
        // One bar that stretches between the tabs and a tab's docked actions,
        // fading through its content (see OneUIMorphSwitcher).
        child: OneUIMorphSwitcher(
          child: docked != null
              ? KeyedSubtree(key: const ValueKey('docked'), child: docked)
              : KeyedSubtree(key: const ValueKey('tabs'), child: _buildTabs(context, reduceMotion)),
        ),
      ),
    );
  }

  /// ColorOS-style pop: the action grows out from behind the bar's edge on a spring
  /// that overshoots once and settles; leaving shrinks it back under the bar.
  /// [from] is the side the bar is on: -1 for the trailing action, 1 for the leading one.
  static Widget _pop(Widget child, Animation<double> animation, {required double from}) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = animation.value;
        return Transform.translate(
          offset: Offset(from * _slot * 0.6 * (1 - v), 0),
          child: Transform.scale(scale: (0.3 + 0.7 * v).clamp(0.0, 1.2), child: child),
        );
      },
    );
  }

  // Flat take on the reference: no selected capsule, the tab shows as a filled white
  // icon and label, the others as grey outlines.
  Widget _buildTabs(BuildContext context, bool reduceMotion) {
    final items = widget.items;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == widget.currentIndex;
          final color = isSelected ? context.palette.textPrimary : context.palette.textSecondary;
          final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
          // Each tab is as wide as its label (with a minimum), so the bar fits its tabs.
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Semantics(
              selected: isSelected,
              button: true,
              label: item.label,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => widget.onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cross-fades the outline and filled icons instead of swapping them.
                      AnimatedSwitcher(
                        duration: duration,
                        child: Icon(
                          isSelected ? item.activeIcon : item.inactiveIcon,
                          key: ValueKey(isSelected),
                          size: 26,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: duration,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: color),
                        child: Text(item.label, maxLines: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A gentle under-damped spring (one soft overshoot) as a curve over the switch's duration.
class _SpringCurve extends Curve {
  const _SpringCurve();

  static final _spring = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 160, ratio: 0.65),
    0,
    1,
    0,
  );

  @override
  double transformInternal(double t) => _spring.x(t * 0.55);
}
