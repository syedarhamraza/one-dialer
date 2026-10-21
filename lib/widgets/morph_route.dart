import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';


/// Opens a page by morphing it out of the button that opened it, ColorOS style: the
/// button's coloured shape grows into the full page (handing over to the page as it
/// grows), and closing shrinks the page back into the button.
class MorphPageRoute<T> extends PageRoute<T> {
  MorphPageRoute({required this.builder, required this.source, required this.color});

  final WidgetBuilder builder;

  /// The button the page grows from (its context); measured every frame while it's still
  /// there, so closing returns to it.
  final BuildContext source;

  /// The button's colour, which the growing shape starts as.
  final Color color;

  Rect? _sourceRect;

  /// Material's emphasized curves: opening eases out of the button and slows gently into
  /// place (a spring, or the decelerate curve, did most of its moving in the first ~100 ms);
  /// closing speeds up into the button.
  static const _open = Cubic(0.2, 0, 0, 1);
  static const _close = Cubic(0.3, 0, 0.8, 0.15);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 400);

  // See-through while it morphs, so the page below shows around the shape; opaque once
  // open, so that page stops painting under it.
  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  void install() {
    super.install();
    animation!.addStatusListener((status) {
      if (overlayEntries.isEmpty) return;
      overlayEntries.last.opaque = status == AnimationStatus.completed;
    });
  }

  /// Where the button is, relative to the navigator (`DesignWidth` scales the app, so
  /// screen pixels aren't layout pixels); the last known spot if it's gone.
  Rect? _measure() {
    final box = source.mounted ? source.findRenderObject() as RenderBox? : null;
    final nav = navigator?.context.findRenderObject();
    if (box != null && box.attached && box.hasSize && nav != null) {
      _sourceRect = box.localToGlobal(Offset.zero, ancestor: nav) & box.size;
    }
    return _sourceRect;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return FadeTransition(opacity: animation, child: child);
    final background = Theme.of(context).scaffoldBackgroundColor;
    return LayoutBuilder(
      builder: (context, box) {
        final full = Offset.zero & box.biggest;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final closing = animation.status == AnimationStatus.reverse;
            // v is time (0 → 1 opening, 1 → 0 closing); t is how far the shape has grown.
            final v = animation.value;
            final t = (closing ? 1 - _close.transform(1 - v) : _open.transform(v)).clamp(0.0, 1.0);
            // The same tree on every frame, open or not: changing it would rebuild the page's state.
            final from = _measure() ?? Rect.fromCenter(center: full.center, width: 56, height: 56);
            final rect = Rect.lerp(from, full, t)!;
            // A card's rounded corners until the very end, then square with the screen.
            final radius = t < .85
                ? lerpDouble(from.shortestSide / 2, 28, t / .85)!
                : lerpDouble(28, 0, (t - .85) / .15)!;
            // Fades run on time, not on the decelerating growth (which is mostly done early).
            double phase(double from, double to) => ((v - from) / (to - from)).clamp(0.0, 1.0);
            return Stack(
              children: [
                // The page below recedes a little.
                IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: .35 * t),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fromRect(
                  rect: rect,
                  child: ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: background),
                        // Laid out at full size and only scaled, so its layout never changes mid-morph.
                        OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: full.width,
                          maxWidth: full.width,
                          minHeight: full.height,
                          maxHeight: full.height,
                          child: Transform.scale(
                            scale: rect.width / full.width,
                            alignment: Alignment.topLeft,
                            child: Opacity(opacity: phase(.08, .35), child: child),
                          ),
                        ),
                        // The button's colour, handing over to the page as it grows.
                        IgnorePointer(
                          child: Opacity(
                            opacity: 1 - phase(0, .25),
                            child: ColoredBox(color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
