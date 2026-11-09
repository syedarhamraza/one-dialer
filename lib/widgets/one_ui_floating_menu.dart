import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart';
import 'liquid_body.dart';
import 'press_glow.dart';
import 'round_header_controls.dart';
import '../l10n/l10n.dart';
import '../app/layout.dart';

/// Item definition for the floating menu.
class OneUIFloatingMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  /// False greys the row out and ignores taps on it (the menu stays open).
  final bool enabled;

  const OneUIFloatingMenuItem({required this.label, this.icon, required this.onTap, this.enabled = true});
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
    BuildContext? anchorContext,
    double fallbackTop = 54.0,
    double? fallbackBottom,
    double fallbackRight = 16.0,
    double width = 200.0,
    bool centered = false,
    bool light = false,
    // Scales the rows, text and icons: the call screen's menus sit beside 76 dp buttons.
    double scale = 1,
  }) async {
    // The app's menus hang off its top buttons, so they follow Settings › Display size › Top
    // buttons rather than the App size; the call screen's (scaled already) follow the call screen.
    final follow = scale == 1 ? headerScale(context) : 1.0;
    scale *= follow;
    final screen = MediaQuery.sizeOf(context);
    final height = (items.length * _rowHeight + _padding * 2) * scale;
    final menuWidth = math.min(width * follow, screen.width - _edge * 2);

    // The button (or [anchorContext]'s widget, e.g. a list row) the menu separates from, or a button-sized spot at the fallback corner.
    Rect? anchor;
    final box = (anchorKey?.currentContext ?? anchorContext)?.findRenderObject() as RenderBox?;
    // Relative to the navigator, not the screen: `DesignWidth` scales the app, so screen pixels aren't layout pixels.
    final navigator = Navigator.of(context).context.findRenderObject();
    if (box != null && box.hasSize) anchor = box.localToGlobal(Offset.zero, ancestor: navigator) & box.size;
    anchor ??= fallbackBottom != null
        ? Rect.fromLTWH(screen.width - fallbackRight - 48, screen.height - fallbackBottom - 48, 48, 48)
        : Rect.fromLTWH(screen.width - fallbackRight - 48, fallbackTop, 48, 48);

    // Kept clear of the status bar and the gesture bar.
    final insets = MediaQuery.paddingOf(context);
    final minTop = insets.top + _edge;
    final maxBottom = screen.height - insets.bottom - _edge;
    // Below the button, or above when it sits low; but on the side it fits, and when it
    // fits neither (a long menu mid-screen), the side with more room.
    final roomAbove = anchor.top - _gap - minTop;
    final roomBelow = maxBottom - anchor.bottom - _gap;
    final upwards = anchor.center.dy > screen.height / 2
        ? roomAbove >= height || roomAbove >= roomBelow
        : roomBelow < height && roomAbove > roomBelow;
    // Lined up with the button's right edge, or ([centered]) right over its middle.
    final right = (centered ? anchor.center.dx + menuWidth / 2 : anchor.right).clamp(
      _edge + menuWidth,
      screen.width - _edge,
    );
    final top = upwards ? anchor.top - _gap - height : anchor.bottom + _gap;
    final menu = Rect.fromLTWH(
      right - menuWidth,
      top.clamp(minTop, math.max(minTop, maxBottom - height)),
      menuWidth,
      height,
    );

    Haptics.tap();
    isOpen.value = true;
    try {
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          // Leaves focus where it is: taking it would close the keyboard under the menu (and
          // reopen it after), relaying out the page behind every frame of both animations.
          requestFocus: false,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          barrierLabel: context.l10n.dismissMenu,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 170),
          pageBuilder: (context, animation, _) => _PopoverMenu(
            items: items,
            button: anchor!,
            menu: menu,
            upwards: upwards,
            animation: animation,
            light: light,
            size: scale,
          ),
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
    this.light = false,
    this.size = 1,
  });

  final List<OneUIFloatingMenuItem> items;
  final double size;
  final Rect button;
  final Rect menu;
  final bool upwards;
  final Animation<double> animation;

  /// The call screen's menus: a flat, solid white card with dark rows and no blur.
  final bool light;

  /// ~94% at 150 ms, peak ~1.5% over at ~290 ms, settled by ~330 ms.
  static final _spring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 320, ratio: .8),
    const Duration(milliseconds: 400),
  );

  static const double _startScale = .2;

  static Widget _glass(ImageFilter? blur, Widget child) =>
      blur == null ? child : BackdropFilter(filter: blur, child: child);

  @override
  Widget build(BuildContext context) {
    // Settings › "Reduce visual effects": full grows the call glass with its blur; reduced is One UI's
    // flat fill over a fixed blur (a small sigma mid-grow is the costliest: Impeller can't downsample
    // it); off is a solid One UI card.
    final fx = OneUIEffectsController.instance;
    // It grows away from the button: pivot on the edge facing it, at the point
    // nearest the button.
    final pivotX = button.center.dx.clamp(menu.left, menu.right);
    final pivot = Alignment((pivotX - menu.left) / menu.width * 2 - 1, upwards ? 1 : -1);
    // Built once, on its own layer; only the glass around it animates.
    final items = RepaintBoundary(
      child: _MenuItems(items: this.items, light: light, size: size),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, items) {
        final v = animation.value;
        final closing = animation.status == AnimationStatus.reverse;
        final grow = closing ? Curves.easeIn.transform(v) : _spring.transform(v);
        final scale = _startScale + (1 - _startScale) * grow;
        // In fast at the start of opening. Closing, it's gone before the shrink's fast last stretch,
        // where the tiny card hitched on screen.
        final fade =
            (closing
                    ? Curves.easeOut.transform(((v - .3) / .7).clamp(0.0, 1.0))
                    : Curves.easeOut.transform((v / .28).clamp(0.0, 1.0)))
                .clamp(0.0, 1.0);
        if (fade == 0) return const SizedBox.shrink();
        // The card scaled about the pivot, in its own coordinates. The glass is laid out at
        // this size instead of scaled by a Transform: a blur under a scale reads its backdrop
        // magnified by 1/scale, which dropped frames on Adreno. The radius scales as the
        // Transform scaled it, so it looks the same.
        final origin = pivot.alongSize(menu.size);
        final glass = Rect.fromLTWH(
          origin.dx * (1 - scale),
          origin.dy * (1 - scale),
          menu.width * scale,
          menu.height * scale,
        );
        return Stack(
          children: [
            // Outside the press, which clips to the menu's shape. Below full visual effects
            // light mode is flat One UI, with no shadow.
            if (context.palette.isLight && fx.isFull)
              Positioned.fromRect(
                rect: glass.shift(menu.topLeft),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.all(Radius.circular(OneUIFloatingMenu._radius * size * scale)),
                    ),
                    shadows: [
                      for (final s in OneUIPalette.lightMenuShadow)
                        s.copyWith(color: s.color.withValues(alpha: s.color.a * fade)),
                    ],
                  ),
                ),
              ),
            Positioned.fromRect(
              rect: menu,
              child: PressGlow(
                radius: OneUIFloatingMenu._radius * size,
                child: Stack(
                  children: [
                    Positioned.fromRect(
                      rect: glass,
                      child: ClipRSuperellipse(
                        borderRadius: BorderRadius.all(Radius.circular(OneUIFloatingMenu._radius * size * scale)),
                        child: light
                            ? Opacity(
                                opacity: fade,
                                child: OverflowBox(
                                  alignment: Alignment.topLeft,
                                  minWidth: menu.width,
                                  maxWidth: menu.width,
                                  minHeight: menu.height,
                                  maxHeight: menu.height,
                                  child: Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.topLeft,
                                    child: ColoredBox(color: Colors.white, child: items),
                                  ),
                                ),
                              )
                            // Glass style › Liquid glass: the package's glass, laid out at the grown
                            // size like the blur below, with a thin base so rows read over list text.
                            : fx.liquidPopups
                            ? liquidBody(
                                context,
                                radius: OneUIFloatingMenu._radius * size * scale,
                                child: Opacity(
                                  opacity: fade,
                                  child: OverflowBox(
                                    alignment: Alignment.topLeft,
                                    minWidth: menu.width,
                                    maxWidth: menu.width,
                                    minHeight: menu.height,
                                    maxHeight: menu.height,
                                    child: Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.topLeft,
                                      child: ColoredBox(
                                        color: context.palette.isLight
                                            ? const Color(0x4DFFFFFF)
                                            : const Color(0x59141416),
                                        child: items,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            // The fade goes inside the blur (an Opacity around a BackdropFilter
                            // would cut it off from the backdrop); the blur is at full strength from
                            // the first frame, so its filter doesn't change every frame.
                            : _glass(
                                fx.isOff
                                    ? null
                                    // Full: one light fixed sigma (the dark base keeps rows legible); a sigma
                                    // that changed every frame of the grow was a new filter each frame.
                                    : ImageFilter.blur(
                                        sigmaX: fx.isFull ? 10 : fx.blurSigma,
                                        sigmaY: fx.isFull ? 10 : fx.blurSigma,
                                      ),
                                Opacity(
                                  opacity: fade,
                                  child: OverflowBox(
                                    alignment: Alignment.topLeft,
                                    minWidth: menu.width,
                                    maxWidth: menu.width,
                                    minHeight: menu.height,
                                    maxHeight: menu.height,
                                    child: Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.topLeft,
                                      // A dark base keeps the items legible over list text; the call-glass
                                      // wash, edge glow and lip go on top, as on the header buttons.
                                      child: ColoredBox(
                                        color: !fx.isFull
                                            ? fx.oneUIFill(light: context.palette.isLight)
                                            // Light: a thin base, so with the glass's own wash it stays
                                            // see-through like the buttons; the blur keeps rows legible.
                                            : context.palette.isLight
                                            ? const Color(0x4DFFFFFF)
                                            // Dark: nearly opaque black. The header pills' glass sits over the black
                                            // header; this keeps the menu's wash on the same black over the list.
                                            : const Color(0xE6000000),
                                        // The header pills' glass, glow and all. From a cached image: drawn live,
                                        // its blurred strokes were re-rendered every frame of a press (~10 ms on a
                                        // Galaxy S25).
                                        child: fx.isFull
                                            ? CallBodyArtwork(
                                                radius: OneUIFloatingMenu._radius * size,
                                                glow: kMainGlassGlow,
                                                opacity: mainGlass(context).opacity,
                                                edges: mainGlass(context).edges,
                                                child: items!,
                                              )
                                            : items,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
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
/// a squircle highlight (like the selected All | Missed thumb) on the row under the finger,
/// which springs row to row as it slides and stays on the nearest row off the card;
/// lifting picks the row under the finger, and lifting off the card picks nothing.
class _MenuItems extends StatefulWidget {
  const _MenuItems({required this.items, this.light = false, this.size = 1});

  final List<OneUIFloatingMenuItem> items;
  final bool light;
  final double size;

  @override
  State<_MenuItems> createState() => _MenuItemsState();
}

class _MenuItemsState extends State<_MenuItems> {
  /// The finger's y within the rows, or null when not touching.
  final _finger = ValueNotifier<double?>(null);
  bool _picked = false;

  /// The highlighted row, and whether the highlight showed last frame.
  int _row0 = 0;
  bool _shown = false;

  double get _row => OneUIFloatingMenu._rowHeight * widget.size;
  double get _pad => OneUIFloatingMenu._padding * widget.size;

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
    if (i == null || !widget.items[i].enabled) return;
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
            padding: EdgeInsets.all(_pad),
            child: Stack(
              children: [
                ValueListenableBuilder<double?>(
                  valueListenable: _finger,
                  builder: (context, y, _) {
                    // Shown for as long as the finger is down, even off the card (it parks on the
                    // nearest row and finishes its spring); lifting off the card still picks nothing.
                    final on = y != null;
                    if (y != null) _row0 = (y / _row).floor().clamp(0, widget.items.length - 1);
                    // The first touch puts it straight under the finger; after that it springs
                    // between rows like the All | Missed thumb, swinging past and settling back.
                    final jump = !_shown || MediaQuery.disableAnimationsOf(context);
                    _shown = on;
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: _row,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: _row0 * _row),
                        duration: jump ? Duration.zero : const Duration(milliseconds: 600),
                        curve: FilterTabs.thumbSpring,
                        builder: (context, top, child) => Transform.translate(offset: Offset(0, top), child: child),
                        child: AnimatedOpacity(
                          opacity: on ? 1 : 0,
                          duration: const Duration(milliseconds: 120),
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: widget.light || context.palette.isLight
                                  ? const Color(0x14000000)
                                  : const Color(0x3DFFFFFF),
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.all(Radius.circular(_row / 2)),
                              ),
                            ),
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
                        enabled: item.enabled,
                        onTap: item.enabled
                            ? () {
                                Navigator.pop(context);
                                item.onTap();
                              }
                            : null,
                        child: _MenuRow(item: item, light: widget.light, size: widget.size),
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
  const _MenuRow({required this.item, this.light = false, this.size = 1});

  final OneUIFloatingMenuItem item;
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = light || context.palette.isLight ? const Color(0xFF111418) : OneUITheme.textPrimary;
    final color = item.enabled ? base : base.withValues(alpha: .38);
    return SizedBox(
      height: OneUIFloatingMenu._rowHeight * size,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * size),
        child: Row(
          children: [
            if (item.icon != null) ...[Icon(item.icon, size: 22 * size, color: color), SizedBox(width: 14 * size)],
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16 * size, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
