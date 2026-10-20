import 'package:flutter/material.dart';

import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';

/// A list row's selection circle. It always occupies the same slot in the row (empty when
/// not selecting), so entering selection mode doesn't shift and rebuild the row's children.
/// Entering, the slot opens on the app's glass spring and the circle pops in; ticking
/// pops the check.
class SelectMark extends StatelessWidget {
  const SelectMark({super.key, required this.selected, required this.gap});

  /// null when not selecting.
  final bool? selected;
  final double gap;

  static const double _size = 24;

  static final _spring = GlassSpringCurve(
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
      curve: _spring,
      builder: (context, t, child) {
        if (t <= 0) return const SizedBox.shrink();
        return SizedBox(
          width: (_size + gap) * t.clamp(0.0, 1.0),
          height: _size,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: _size,
            maxWidth: _size,
            child: Transform.scale(scale: t, child: child),
          ),
        );
      },
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          selected == true ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          key: ValueKey(selected == true),
          size: _size,
          color: selected == true ? OneUITheme.accentBlue : OneUITheme.textTertiary,
        ),
      ),
    );
  }
}
