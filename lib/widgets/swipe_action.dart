import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../core/haptics/haptics.dart';
import '../core/prefs/dialer_prefs.dart';
import '../features/in_call/call_controls.dart' show TintedCallBody, answerGreen;
import '../l10n/l10n.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart' show kMainGlassGlow, mainGlass;

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

class _SwipeActionState extends State<SwipeAction> with TickerProviderStateMixin {
  static const _threshold = 0.35;
  static const _blue = Color(0xFF3D8BFF);
  static const _fade = Duration(milliseconds: 150);
  // Past the threshold the row follows the finger this much (a rubber band), so it can't fly off.
  static const _resistance = 0.35;
  // The app's ColorOS spring (the Calls header morph's).
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 240, ratio: .78);

  // Unbounded: the controller's value is the row's offset in pixels.
  late final _dx = AnimationController.unbounded(vsync: this)..addListener(() => setState(() {}));
  // The glass pill's swell when it arms, and its held flash when the swipe acts.
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 320))
    ..addListener(() => setState(() {}));
  double _width = 1, _raw = 0;
  bool _armed = false, _confirmed = false;
  // Only the glass pill swells and holds its flash; the other styles spring straight back.
  bool get _pill => DialerPrefs.instance.swipeStyle.value == 'pill';

  double get _limit => _width * _threshold;

  double _band(double raw) => raw.abs() <= _limit ? raw : raw.sign * (_limit + (raw.abs() - _limit) * _resistance);

  double _unband(double dx) => dx.abs() <= _limit ? dx : dx.sign * (_limit + (dx.abs() - _limit) / _resistance);

  @override
  void dispose() {
    _dx.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _start(DragStartDetails _) {
    // Caught mid spring-back or mid flash: carry on from where the row is.
    _pop.stop();
    _confirmed = false;
    _raw = _unband(_dx.value);
  }

  void _update(DragUpdateDetails d) {
    var raw = _raw + d.delta.dx;
    if (widget.onCall == null) raw = math.min(raw, 0);
    if (widget.onMessage == null) raw = math.max(raw, 0);
    _raw = raw;
    final dx = _band(raw);
    final armed = dx.abs() >= _limit;
    if (armed && !_armed) {
      Haptics.tap();
      if (_pill && !MediaQuery.disableAnimationsOf(context)) _pop.forward(from: 0);
    } else if (!armed && _armed) {
      HapticFeedback.selectionClick(); // lighter: letting go now does nothing
    }
    _armed = armed;
    _dx.value = dx; // stops a running spring-back
  }

  void _end(DragEndDetails d) {
    final acted = _armed;
    if (acted) (_dx.value > 0 ? widget.onCall : widget.onMessage)?.call();
    _armed = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _dx.value = 0;
      return;
    }
    void springBack() => _dx.animateWith(SpringSimulation(_spring, _dx.value, 0, acted ? 0 : d.primaryVelocity ?? 0));
    if (!acted || !_pill) return springBack();
    // Acted: the pill holds lit and swells once, then everything springs back.
    _confirmed = true;
    _pop.forward(from: 0).then((_) {
      if (!mounted || !_confirmed) return;
      _confirmed = false;
      springBack();
    });
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
        // Opaque, so the background shows only where the row has moved away; its corners round
        // as it pulls away, so it reads as a sheet over the colour rather than a cut.
        row = dx == 0
            ? ColoredBox(color: context.palette.page, child: row)
            : DecoratedBox(
                decoration: ShapeDecoration(
                  color: card ? context.palette.card : context.palette.page,
                  shape: SquircleBorder(borderRadius: BorderRadius.circular(18 * p)),
                ),
                child: row,
              );
        if (card && dx != 0) row = Transform.scale(scale: 1 - 0.04 * p, child: row);
        return GestureDetector(
          onHorizontalDragStart: _start,
          onHorizontalDragUpdate: _update,
          onHorizontalDragEnd: _end,
          // Lost to a scroll: never acts, just springs back.
          onHorizontalDragCancel: () {
            _armed = false;
            _end(DragEndDetails());
          },
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
      tween: Tween(end: _armed || _confirmed ? 1 : 0),
      duration: _fade,
      builder: (context, t, _) => builder(t),
    );

    // The exposed gap beside the row, with [child] hugging the row's edge.
    Widget inGap(Widget child, {double inset = 20}) => Align(
      alignment: right ? Alignment.centerLeft : Alignment.centerRight,
      child: SizedBox(
        width: gap,
        // minWidth 0: else the gap's tight width stretches the content and it sits at the far edge.
        child: OverflowBox(
          minWidth: 0,
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
        return ColoredBox(
          color: page,
          child: armedLerp((t) => _glassPill(context, right, color, gap, p, t, icon, label)),
        );
    }
  }

  /// The glass pill: call glass that fills with the action colour from its outer edge as the row
  /// slides (full exactly at the threshold), then lights up and glows; the icon rides at the
  /// row's edge and the word joins it once there's room. [t] is how lit it is (0–1).
  Widget _glassPill(
    BuildContext context,
    bool right,
    Color color,
    double gap,
    double p,
    double t,
    IconData icon,
    String label,
  ) {
    const height = 42.0; // the avatar's, so it lines up with the row
    const outer = 12.0, inner = 8.0;
    final width = math.max(0.0, gap - outer - inner);
    final fx = OneUIEffectsController.instance;
    final light = context.palette.isLight;
    final look = mainGlass(context);
    final swell = 1 + 0.06 * math.sin(math.pi * _pop.value);
    final labelT = ((width - 96) / 32).clamp(0.0, 1.0);
    final fg = Color.lerp(color, Colors.white, t)!;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (right && labelT > 0) ...[_label(label, fg, labelT), const SizedBox(width: 6)],
        Transform.scale(
          scale: 0.6 + 0.4 * p,
          child: AnimatedScale(
            scale: t > .5 ? 1.12 : 1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: Icon(icon, size: 22, color: fg, semanticLabel: label),
          ),
        ),
        if (!right && labelT > 0) ...[const SizedBox(width: 6), _label(label, fg, labelT)],
      ],
    );
    return Align(
      alignment: right ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(left: right ? outer : 0, right: right ? 0 : outer),
        child: Transform.scale(
          scale: swell,
          alignment: right ? Alignment.centerLeft : Alignment.centerRight,
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                // Below full effects: the flat One UI fill, no glow (reduced and off stay flat).
                color: fx.isFull ? null : fx.oneUIFill(light: light),
                shadows: fx.isFull && t > 0
                    ? [
                        // An even glow all round, not a drop shadow (that read as a second, darker edge).
                        BoxShadow(color: color.withValues(alpha: .4 * t), blurRadius: 18),
                      ]
                    : null,
              ),
              child: CustomPaint(
                painter: fx.isFull
                    ? TintedCallBody(height / 2, glow: kMainGlassGlow * look.opacity, edges: look.edges, light: light)
                    : null,
                // Over the glass, under the icon and word.
                child: CustomPaint(
                  painter: _PillFill(color: color, progress: p, lit: t, fromLeft: right, glow: fx.isFull),
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: right ? 0 : 12, right: right ? 12 : 0),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

/// The glass pill's colour: a stadium growing from the outer edge with the swipe ([progress],
/// full at the threshold), solid once [lit], with the lit buttons' brighter lower edge when [glow].
class _PillFill extends CustomPainter {
  _PillFill({
    required this.color,
    required this.progress,
    required this.lit,
    required this.fromLeft,
    required this.glow,
  });

  final Color color;
  final double progress, lit;
  final bool fromLeft, glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final r = Radius.circular(size.height / 2);
    final w = size.width * math.max(progress, lit);
    if (w > 0) {
      // A full stadium reaching in from past the outer edge, cut to the pill: its leading edge is
      // always round and its outer end follows the pill's curve, even while it's a sliver.
      final h = size.height;
      final rect = fromLeft ? Rect.fromLTRB(-h, 0, w, h) : Rect.fromLTRB(size.width - w, 0, size.width + h, h);
      canvas
        ..save()
        ..clipRRect(RRect.fromRectAndRadius(Offset.zero & size, r))
        ..drawRRect(RRect.fromRectAndRadius(rect, r), Paint()..color = color.withValues(alpha: 0.45 + 0.55 * lit))
        ..restore();
    }
    if (glow && lit > 0) {
      final whole = Offset.zero & size;
      canvas.drawRRect(
        RRect.fromRectAndRadius(whole, r),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0x00FFFFFF),
              const Color(0x00FFFFFF),
              Colors.white.withValues(alpha: .24 * lit),
            ],
            stops: const [0, .5, 1],
          ).createShader(whole),
      );
    }
  }

  @override
  bool shouldRepaint(_PillFill old) =>
      old.color != color || old.progress != progress || old.lit != lit || old.fromLeft != fromLeft || old.glow != glow;
}
