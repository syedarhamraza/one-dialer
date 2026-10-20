import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'press_glow.dart';

/// Item definition for the floating menu.
class OneUIFloatingMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const OneUIFloatingMenuItem({required this.label, this.icon, required this.onTap});
}

/// The app's floating menu (originally OneSpend's One UI menu, now our own): a
/// frosted call-glass card that pops from the button that opened it the way
/// ColorOS's call-screen More menu does (see [_PopoverMenu]). It sits beside the
/// button (below it, or above for buttons low on the screen), never covering it.
/// Transparent barrier; tap outside or Back to close.
class OneUIFloatingMenu {
  /// Whether a menu is open. Headers use it to fade their anchor while it shows.
  static final ValueNotifier<bool> isOpen = ValueNotifier<bool>(false);

  static const double _rowHeight = 48;
  static const double _padding = 6;
  static const double _edge = 16;
  static const double _gap = 10;

  static Future<void> show({
    required BuildContext context,
    required List<OneUIFloatingMenuItem> items,
    GlobalKey? anchorKey,
    double fallbackTop = 54.0,
    double? fallbackBottom,
    double fallbackRight = 16.0,
    double width = 200.0,
  }) async {
    final screen = MediaQuery.sizeOf(context);
    final height = items.length * _rowHeight + _padding * 2;
    final menuWidth = math.min(width, screen.width - _edge * 2);

    // The button the menu separates from, or a button-sized spot at the fallback corner.
    Rect? anchor;
    final box = anchorKey?.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) anchor = box.localToGlobal(Offset.zero) & box.size;
    anchor ??= fallbackBottom != null
        ? Rect.fromLTWH(screen.width - fallbackRight - 48, screen.height - fallbackBottom - 48, 48, 48)
        : Rect.fromLTWH(screen.width - fallbackRight - 48, fallbackTop, 48, 48);

    // Below the button, unless it sits low or there's no room; then above.
    final roomBelow = screen.height - anchor.bottom - _gap - _edge >= height;
    final upwards = anchor.center.dy > screen.height / 2 || !roomBelow;
    final right = anchor.right.clamp(_edge + menuWidth, screen.width - _edge);
    final top = upwards ? anchor.top - _gap - height : anchor.bottom + _gap;
    final menu = Rect.fromLTWH(right - menuWidth, top.clamp(_edge, screen.height - _edge - height), menuWidth, height);

    Haptics.tap();
    isOpen.value = true;
    try {
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          barrierLabel: 'Dismiss menu',
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 170),
          pageBuilder: (context, animation, _) =>
              _PopoverMenu(items: items, button: anchor!, menu: menu, upwards: upwards, animation: animation),
          transitionsBuilder: (context, animation, secondary, child) => child,
        ),
      );
    } finally {
      isOpen.value = false;
    }
  }
}

/// Opens like ColorOS's call-screen More menu (measured from a screen recording):
/// the whole card, contents and all, pops from a small blank card at the point nearest the button, fading in over the first
/// ~110 ms and scaling up on a spring with a ~1.5% overshoot that settles in ~330 ms.
/// It closes by shrinking back to that point, accelerating, and fading out.
class _PopoverMenu extends StatelessWidget {
  const _PopoverMenu({
    required this.items,
    required this.button,
    required this.menu,
    required this.upwards,
    required this.animation,
  });

  final List<OneUIFloatingMenuItem> items;
  final Rect button;
  final Rect menu;
  final bool upwards;
  final Animation<double> animation;

  /// ~94% at 150 ms, peak ~1.5% over at ~290 ms, settled by ~330 ms.
  static final _spring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 320, ratio: .8),
    const Duration(milliseconds: 400),
  );

  static const double _startScale = .2;

  @override
  Widget build(BuildContext context) {
    final sigma = OneUIEffectsController.instance.blurSigma;
    // It grows away from the button: pivot on the edge facing it, at the point
    // nearest the button.
    final pivotX = button.center.dx.clamp(menu.left, menu.right);
    final pivot = Alignment((pivotX - menu.left) / menu.width * 2 - 1, upwards ? 1 : -1);
    // Built once; only the glass around it animates.
    final items = Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OneUIFloatingMenu._padding, horizontal: 6),
        child: Column(children: [for (final item in this.items) _MenuRow(item: item)]),
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, items) {
        final v = animation.value;
        final closing = animation.status == AnimationStatus.reverse;
        final grow = closing ? Curves.easeIn.transform(v) : _spring.transform(v);
        final scale = _startScale + (1 - _startScale) * grow;
        // In fast at the start of opening; out over most of the close.
        final fade = (closing ? Curves.easeOut.transform(v) : Curves.easeOut.transform((v / .28).clamp(0.0, 1.0)))
            .clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fromRect(
              rect: menu,
              child: Transform.scale(
                scale: scale,
                alignment: pivot,
                child: PressGlow(
                  radius: 22,
                  child: ClipRSuperellipse(
                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                    // The fade goes inside the blur (an Opacity around a BackdropFilter
                    // would cut it off from the backdrop); the blur itself ramps with it.
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: sigma * fade, sigmaY: sigma * fade),
                      child: Opacity(
                        opacity: fade,
                        // A dark base keeps the items legible over list text; the call-glass
                        // wash, edge glow and lip go on top, as on the header buttons.
                        child: ColoredBox(
                          color: const Color(0xB3141416),
                          child: CustomPaint(painter: const TintedCallBody(22), child: items),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: items,
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final OneUIFloatingMenuItem item;

  static const _shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(16)));

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        item.onTap();
      },
      customBorder: _shape,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.05),
      child: SizedBox(
        height: OneUIFloatingMenu._rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 20, color: OneUITheme.textPrimary),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
