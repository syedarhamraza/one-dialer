import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../core/haptics/haptics.dart';
import '../core/prefs/dialer_prefs.dart';
import '../features/in_call/call_controls.dart' show answerGreen;
import '../l10n/l10n.dart';
import '../theme/one_ui_theme.dart';

/// Settings › Swipe to call or message: a row slides right to call (green) or left to message
/// (blue), acting on release past [_threshold] of its width, then springs back; never removed.
/// Its look is Settings › Swipe style ([DialerPrefs.swipeStyle], beta: `pill`, `wash`, `bubble`,
/// `card`). No blur or opacity layers: colours carry their own alpha.
class SwipeAction extends StatefulWidget {
  const SwipeAction({super.key, required this.child, this.onCall, this.onMessage});

  final Widget child;
  final VoidCallback? onCall, onMessage;

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<SwipeAction> with SingleTickerProviderStateMixin {
  static const _threshold = 0.35;
  static const _blue = Color(0xFF3D8BFF);
  static const _fade = Duration(milliseconds: 150);
  // The app's ColorOS spring (the Calls header morph's).
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 240, ratio: .78);

  // Unbounded: the controller's value is the row's offset in pixels.
  late final _dx = AnimationController.unbounded(vsync: this)..addListener(() => setState(() {}));
  double _width = 1;
  bool _armed = false;

  @override
  void dispose() {
    _dx.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    var dx = _dx.value + d.delta.dx;
    if (widget.onCall == null) dx = dx.clamp(-_width, 0);
    if (widget.onMessage == null) dx = dx.clamp(0, _width);
    final armed = dx.abs() >= _width * _threshold;
    if (armed && !_armed) Haptics.tap();
    _armed = armed;
    _dx.value = dx; // stops a running spring-back
  }

  void _end(DragEndDetails d) {
    if (_armed) (_dx.value > 0 ? widget.onCall : widget.onMessage)?.call();
    _armed = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _dx.value = 0;
    } else {
      _dx.animateWith(SpringSimulation(_spring, _dx.value, 0, d.primaryVelocity ?? 0));
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: DialerPrefs.instance.swipeStyle,
    builder: (context, style, _) => LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        final dx = _dx.value;
        final card = style == 'card';
        final p = (dx.abs() / (_width * _threshold)).clamp(0.0, 1.0);
        Widget row = widget.child;
        row = card && dx != 0
            ? DecoratedBox(
                decoration: ShapeDecoration(
                  color: context.palette.card,
                  shape: SquircleBorder(borderRadius: BorderRadius.circular(18 * p)),
                ),
                child: row,
              )
            // Opaque, so the background shows only where the row has moved away.
            : ColoredBox(color: context.palette.page, child: row);
        if (card && dx != 0) row = Transform.scale(scale: 1 - 0.04 * p, child: row);
        return GestureDetector(
          onHorizontalDragUpdate: _update,
          onHorizontalDragEnd: _end,
          child: Stack(
            children: [
              if (dx != 0) Positioned.fill(child: _background(context, style, dx, p)),
              Transform.translate(offset: Offset(dx, 0), child: row),
            ],
          ),
        );
      },
    ),
  );

  Widget _background(BuildContext context, String style, double dx, double p) {
    final right = dx > 0;
    final color = right ? answerGreen : _blue;
    final gap = dx.abs();
    final l10n = context.l10n;
    final icon = right ? Icons.call_rounded : Icons.message_rounded;
    final label = right ? l10n.call : l10n.message;
    final page = context.palette.page;

    // Fades a colour pair as the swipe arms and disarms.
    Widget armedLerp(Widget Function(double t) builder) => TweenAnimationBuilder<double>(
      tween: Tween(end: _armed ? 1 : 0),
      duration: _fade,
      builder: (context, t, _) => builder(t),
    );

    // The exposed gap beside the row, with [child] hugging the row's edge.
    Widget inGap(Widget child, {double inset = 20}) => Align(
      alignment: right ? Alignment.centerLeft : Alignment.centerRight,
      child: SizedBox(
        width: gap,
        child: OverflowBox(
          maxWidth: double.infinity,
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: right ? 0 : inset, right: right ? inset : 0),
            child: child,
          ),
        ),
      ),
    );

    Widget iconLabel(Color fg, double labelT) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!right && labelT > 0) ...[_label(label, fg, labelT), const SizedBox(width: 8)],
        AnimatedScale(
          scale: _armed ? 1.12 : 0.9,
          duration: _fade,
          child: Icon(icon, color: fg, semanticLabel: label),
        ),
        if (right && labelT > 0) ...[const SizedBox(width: 8), _label(label, fg, labelT)],
      ],
    );

    switch (style) {
      case 'wash':
        return ColoredBox(
          color: Color.alphaBlend(color.withValues(alpha: 0.35 + 0.65 * p), page),
          child: armedLerp((t) => inGap(iconLabel(Colors.white, t))),
        );
      case 'bubble':
        final size = 16 + 30 * p;
        return armedLerp(
          (t) => ColoredBox(
            color: Color.alphaBlend(color.withValues(alpha: 0.15 * t), page),
            child: Align(
              alignment: right ? Alignment.centerLeft : Alignment.centerRight,
              child: SizedBox(
                width: gap,
                child: Center(
                  child: AnimatedScale(
                    scale: _armed ? 1.15 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Icon(icon, size: size * 0.5, color: Colors.white, semanticLabel: label),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case 'card':
        return ColoredBox(
          color: page,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: Color.alphaBlend(color.withValues(alpha: 0.35 + 0.65 * p), page),
                shape: SquircleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: armedLerp((t) => inGap(iconLabel(Colors.white, t), inset: 16)),
            ),
          ),
        );
      default: // pill
        final width = math.max(0.0, gap - 16);
        return ColoredBox(
          color: page,
          child: Align(
            alignment: right ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: armedLerp(
                (t) => Container(
                  width: width,
                  height: 44,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: Color.lerp(context.palette.pill, color, t),
                    shape: const StadiumBorder(),
                  ),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: Icon(icon, color: Color.lerp(color, Colors.white, t), semanticLabel: label),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }

  static Widget _label(String text, Color color, double t) => Text(
    text,
    style: TextStyle(
      color: color.withValues(alpha: t),
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );
}
