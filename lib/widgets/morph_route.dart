import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../features/in_call/call_controls.dart';

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

  /// Soft settle, no bounce: the floating menu's family of springs.
  static final _spring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 260, ratio: .85),
    const Duration(milliseconds: 450),
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

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
            final v = animation.value;
            // Closing shrinks slowly at first, then speeds up into the button.
            final t = (closing ? 1 - Curves.easeInCubic.transform(1 - v) : _spring.transform(v)).clamp(0.0, 1.0);
            // The same tree on every frame, open or not: changing it would rebuild the page's state.
            final from = _measure() ?? Rect.fromCenter(center: full.center, width: 56, height: 56);
            final rect = Rect.lerp(from, full, t)!;
            final radius = lerpDouble(from.shortestSide / 2, 0, t)!;
            double phase(double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);
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
                            child: Opacity(opacity: phase(.2, .6), child: child),
                          ),
                        ),
                        // The button's colour, handing over to the page as it grows.
                        IgnorePointer(
                          child: Opacity(
                            opacity: 1 - phase(.15, .5),
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
