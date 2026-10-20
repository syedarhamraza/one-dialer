import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart';
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

  /// A squircle like the app's pills: the row highlight, inset by [_padding], is a
  /// full pill of the same superellipse.
  static const double _radius = _rowHeight / 2 + _padding;

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
    final items = _MenuItems(items: this.items);
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
                  radius: OneUIFloatingMenu._radius,
                  child: ClipRSuperellipse(
                    borderRadius: const BorderRadius.all(Radius.circular(OneUIFloatingMenu._radius)),
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
                          child: CustomPaint(
                            painter: const TintedCallBody(OneUIFloatingMenu._radius, glow: kMainGlassGlow),
                            child: items,
                          ),
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

/// The menu's rows with ColorOS-style press-and-drag picking: touching the card shows
/// a squircle highlight (like the selected All | Missed thumb) under the finger, which
/// follows it freely while it slides; lifting picks the row under the finger, and
/// lifting off the card picks nothing.
class _MenuItems extends StatefulWidget {
  const _MenuItems({required this.items});

  final List<OneUIFloatingMenuItem> items;

  @override
  State<_MenuItems> createState() => _MenuItemsState();
}

class _MenuItemsState extends State<_MenuItems> {
  /// The finger's y within the rows, or null when not touching.
  final _finger = ValueNotifier<double?>(null);
  bool _picked = false;

  static const double _row = OneUIFloatingMenu._rowHeight;
  static const double _pad = OneUIFloatingMenu._padding;

  double get _height => widget.items.length * _row;

  /// The row under [y], or null when the finger is off the rows.
  int? _rowAt(double y, double x, double width) => x < 0 || x > width || y < -_pad || y > _height + _pad
      ? null
      : (y / _row).floor().clamp(0, widget.items.length - 1);

  void _release(PointerUpEvent e, double width) {
    final y = _finger.value;
    _finger.value = null;
    if (y == null || _picked) return;
    final i = _rowAt(e.localPosition.dy - _pad, e.localPosition.dx, width);
    if (i == null) return;
    _picked = true;
    Haptics.tap();
    Navigator.pop(context);
    widget.items[i].onTap();
  }

  @override
  void dispose() {
    _finger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _finger.value = e.localPosition.dy - _pad,
        onPointerMove: (e) => _finger.value = e.localPosition.dy - _pad,
        onPointerUp: (e) => _release(e, box.maxWidth),
        onPointerCancel: (_) => _finger.value = null,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: Stack(
              children: [
                ValueListenableBuilder<double?>(
                  valueListenable: _finger,
                  builder: (context, y, _) {
                    final on = y != null && y > -_pad && y < _height + _pad;
                    // Follows the finger freely, kept within the rows.
                    final top = ((y ?? 0) - _row / 2).clamp(0.0, _height - _row);
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: top,
                      height: _row,
                      child: AnimatedOpacity(
                        opacity: on ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: const DecoratedBox(
                          decoration: ShapeDecoration(
                            color: Color(0x3DFFFFFF),
                            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(_row / 2))),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Column(
                  children: [
                    for (final item in widget.items)
                      Semantics(
                        button: true,
                        onTap: () {
                          Navigator.pop(context);
                          item.onTap();
                        },
                        child: _MenuRow(item: item),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final OneUIFloatingMenuItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: OneUIFloatingMenu._rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
