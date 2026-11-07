import 'package:flutter/material.dart';

import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';

/// A list row's selection box at the row's end (ColorOS): a rounded square, grey outline
/// when off, green with a white tick when on. It always occupies the same slot in the row
/// (empty when not selecting), so entering selection mode doesn't shift and rebuild the
/// row's children. Entering, the slot opens on the app's glass spring and the box pops in;
/// ticking grows the green from the centre, unticking shrinks it back into the outline.
class SelectMark extends StatelessWidget {
  const SelectMark({super.key, required this.selected, this.gap = 12, this.end = 0});

  /// null when not selecting.
  final bool? selected;

  /// Space before the box, and after it.
  final double gap, end;

  static const double _size = 22;
  static const _radius = BorderRadius.all(Radius.circular(6));

  /// The slot's spring; a row's own trailing control can leave on it too.
  static final spring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: .7),
    const Duration(milliseconds: 450),
  );

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected == null ? 0 : 1),
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
      curve: spring,
      builder: (context, t, child) {
        if (t <= 0) return const SizedBox.shrink();
        return SizedBox(
          width: (_size + gap + end) * t.clamp(0.0, 1.0),
          height: _size,
          child: OverflowBox(
            alignment: Alignment.centerRight,
            minWidth: _size + end,
            maxWidth: _size + end,
            child: Padding(
              padding: EdgeInsets.only(right: end),
              child: Transform.scale(scale: t, child: child),
            ),
          ),
        );
      },
      child: SizedBox.square(
        dimension: _size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                shape: SquircleBorder(
                  borderRadius: _radius,
                  side: BorderSide(color: context.palette.textTertiary, width: 1.5),
                ),
              ),
            ),
            // Faded by its colours, not an Opacity layer.
            TweenAnimationBuilder<double>(
              tween: Tween(end: selected == true ? 1 : 0),
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              builder: (context, f, _) {
                if (f <= 0) return const SizedBox.shrink();
                return Transform.scale(
                  scale: .4 + .6 * f,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: OneUITheme.dialGreen.withValues(alpha: f),
                      shape: const SquircleBorder(borderRadius: _radius),
                    ),
                    child: Icon(Icons.check_rounded, size: 18, color: Colors.white.withValues(alpha: f)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A selected row's grey background, fading in and out with its [SelectMark]. Goes under the
/// row's content (a `Positioned.fill` in a `Stack`).
class SelectHighlight extends StatelessWidget {
  const SelectHighlight({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      color: selected
          ? (context.palette.isLight ? const Color(0x0F000000) : OneUITheme.surfaceCard)
          : Colors.transparent,
    );
  }
}
