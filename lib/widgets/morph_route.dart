import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Opens a page by morphing it out of the button that opened it, ColorOS style: the
/// button's coloured circle swells into a round bubble, then fills the screen (handing over
/// to the page as it grows), and closing shrinks the page back into the button.
class MorphPageRoute<T> extends PageRoute<T> {
  MorphPageRoute({required this.builder, required this.source, required this.color});

  final WidgetBuilder builder;

  /// The button the page grows from (its context); measured every frame while it's still
  /// there, so closing returns to it.
  final BuildContext source;

  /// The button's colour, which the growing shape starts as.
  final Color color;

  Rect? _sourceRect;

  /// An even glide: speeds up out of the button and slows into place symmetrically, with no
  /// long tail where it seems to stall (Material's emphasized curve spent its last ~40%
  /// barely moving).
  static const _glide = Curves.easeInOutCubic;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 420);

  // See-through, so the page below shows around the shape. Kept see-through once open too:
  // making it opaque stopped painting the page below, and bringing it back when closing
  // cost a ~200 ms frame right as the shrink began.
  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

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
            // The same curve both ways, so closing is opening played back.
            final t = _glide.transform(animation.value);
            // The same tree on every frame, open or not: changing it would rebuild the page's state.
            final from = _measure() ?? Rect.fromCenter(center: full.center, width: 56, height: 56);
            // Width leads and height follows, so it swells as a round bubble before it
            // stretches to fill the screen.
            final width = lerpDouble(from.width, full.width, t)!;
            final height = lerpDouble(from.height, full.height, Curves.easeInQuad.transform(t))!;
            final center = Offset.lerp(from.center, full.center, t)!;
            final rect = Rect.fromCenter(center: center, width: width, height: height);
            // As round as the shape allows for most of the way, squaring off with the screen
            // only at the very end.
            final radius = (rect.shortestSide / 2) * (1 - Curves.easeInQuart.transform(t));
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: background),
                        // Laid out at full size and only scaled, so its layout never changes
                        // mid-morph; never faded (a full-page fade is a costly layer every frame).
                        OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: full.width,
                          maxWidth: full.width,
                          minHeight: full.height,
                          maxHeight: full.height,
                          child: Transform.scale(scale: width / full.width, alignment: Alignment.topLeft, child: child),
                        ),
                        // The button's colour over it, clearing as it grows: a cheap colour change.
                        IgnorePointer(
                          child: ColoredBox(
                            color: color.withValues(alpha: 1 - Curves.easeOut.transform((t / .45).clamp(0.0, 1.0))),
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
