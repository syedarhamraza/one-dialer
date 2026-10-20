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

/// The app's floating menu (originally OneSpend's One UI menu, now our own). It
/// moves like the dialpad button popping out from behind the nav bar: a round glass
/// bead slides out from under the button that opened it, clear of the button row,
/// then opens into a frosted call-glass card from the corner nearest the button,
/// with one soft overshoot of the whole card. It sits beside the button (below it,
/// or above for buttons low on the screen), never covering it, and folds back under
/// it on close. Transparent barrier; tap outside or Back to close.
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
          transitionDuration: const Duration(milliseconds: 560),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, _) =>
              _MorphMenu(items: items, button: anchor!, menu: menu, upwards: upwards, animation: animation),
          transitionsBuilder: (context, animation, secondary, child) => child,
        ),
      );
    } finally {
      isOpen.value = false;
    }
  }
}

class _MorphMenu extends StatelessWidget {
  const _MorphMenu({
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

  /// The dialpad button's pop spring: one soft overshoot, then settled.
  static final _spring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 180, ratio: .72),
    const Duration(milliseconds: 560),
  );

  static double _in(double t) => (t * 2 - 1).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final sigma = OneUIEffectsController.instance.blurSigma;
    final screen = MediaQuery.sizeOf(context);
    // The button itself is cut out of what the menu draws, so the card starts hidden
    // behind it and slides out from under it (like the dialpad button from behind the
    // nav bar) instead of appearing on top of it as a copy.
    final behindButton = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & screen),
      Path()..addOval(button.inflate(.5)),
    );
    final progress = CurvedAnimation(parent: animation, curve: _spring, reverseCurve: Curves.easeInOutCubic);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, items) {
        final p = progress.value;
        final t = p.clamp(0.0, 1.0);
        // One continuous move on one spring. The card keeps its corner by the button and
        // leaves the row fast, staying button-narrow while it's level with the other
        // buttons; widening only eases in from zero once it's clear, so its middle
        // sweeps along a smooth curve (out, then across) rather than an L.
        final travel = 1 - math.pow(1 - t, 3).toDouble();
        final widen = math.pow(((t - .35) / .65).clamp(0.0, 1.0), 2).toDouble();
        final w = button.width + (menu.width - button.width) * widen;
        final h = button.height + (menu.height - button.height) * t;
        final right = button.right + (menu.right - button.right) * travel;
        final bottom = button.bottom + (menu.bottom - button.bottom) * travel;
        final rect = upwards
            ? Rect.fromLTRB(right - w, bottom - h, right, bottom)
            : Rect.fromLTWH(right - w, button.top + (menu.top - button.top) * travel, w, h);
        final radius = math.min(button.shortestSide / 2 + (22 - button.shortestSide / 2) * t, rect.shortestSide / 2);
        // Milky like the button as it leaves, darkening into the menu's glass.
        final base = Color.lerp(const Color(0x00141416), const Color(0xB3141416), t)!;
        return ClipPath(
          clipper: _PathClipper(behindButton),
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                // Past full size the whole card swells and settles, like the dialpad
                // button, instead of its sides stretching.
                child: Transform.scale(
                  scale: math.max(1.0, p),
                  alignment: upwards ? Alignment.bottomRight : Alignment.topRight,
                  // Pressed like the header buttons: pressing an item squeezes the card,
                  // stretches it toward the finger and glows.
                  child: PressGlow(
                    radius: 22,
                    child: ClipRSuperellipse(
                      borderRadius: BorderRadius.all(Radius.circular(radius)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                        // A dark base keeps the items legible over list text; the call-glass
                        // wash, edge glow and lip go on top, as on the header buttons.
                        child: ColoredBox(
                          color: base,
                          child: CustomPaint(
                            painter: TintedCallBody(radius),
                            // The items fade in once the card has room, and out first on close.
                            child: Opacity(opacity: _in(t), child: items),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      // Laid out at the final size and revealed as the card grows.
      child: OverflowBox(
        alignment: upwards ? Alignment.bottomRight : Alignment.topRight,
        minWidth: menu.width,
        maxWidth: menu.width,
        minHeight: menu.height,
        maxHeight: menu.height,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: OneUIFloatingMenu._padding, horizontal: 6),
            child: Column(children: [for (final item in items) _MenuRow(item: item)]),
          ),
        ),
      ),
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

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);
  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}
