import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../core/haptics/haptics.dart';
import '../core/prefs/dialer_prefs.dart';
import '../features/in_call/call_controls.dart' show answerGreen;
import '../l10n/l10n.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart' show CallGlass;
import 'call_glyph.dart';
import 'press_glow.dart' show LitButton;

/// Settings › Swipe to call or message: a row slides right to call (green) or left to message
/// (blue), acting on release past [_threshold] of its width, then springs back; never removed.
/// Its look is Settings › Swipe style ([DialerPrefs.swipeStyle], beta: `pill` Glass button, `flat`).
/// No blur or opacity layers: colours carry their own alpha.
class SwipeAction extends StatefulWidget {
  const SwipeAction({super.key, required this.child, this.onCall, this.onMessage});

  final Widget child;
  final VoidCallback? onCall, onMessage;

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<SwipeAction> with TickerProviderStateMixin {
  static const _threshold = 0.35;
  // Past the threshold the row follows the finger this much (a rubber band), so it can't fly off.
  static const _resistance = 0.8;
  // Stiffer than the Calls header morph's spring, with a hint of bounce: the row snaps home quickly.
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: .82);

  // Unbounded: the controller's value is the row's offset in pixels.
  late final _dx = AnimationController.unbounded(vsync: this)..addListener(() => setState(() {}));
  // The glass pill's swell when it arms, and its held flash when the swipe acts.
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 160))
    ..addListener(() => setState(() {}));
  double _width = 1, _raw = 0;
  bool _armed = false, _confirmed = false;

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
      if (!MediaQuery.disableAnimationsOf(context)) _pop.forward(from: 0);
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
    if (!acted) return springBack();
    // Acted: the button holds lit and swells once, then everything springs back.
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
        final flat = style == 'flat';
        final p = (dx.abs() / (_width * _threshold)).clamp(0.0, 1.0);
        // Its own layer: sliding only moves the row's picture, never repaints its text, avatar and buttons.
        // Opaque, so the background shows only where the row has moved away. With Flat, its corners
        // morph into a squircle as it pulls away from the colour. The same widgets at rest and while
        // sliding, so starting a swipe never rebuilds the row.
        final Widget row = DecoratedBox(
          decoration: ShapeDecoration(
            color: context.palette.page,
            shape: SquircleBorder(borderRadius: BorderRadius.circular(flat ? OneUITheme.radiusCard * p : 0)),
          ),
          child: RepaintBoundary(key: const ValueKey('kq4v9sarz7od2'), child: widget.child),
        );
        return GestureDetector(
          // From touch-down, so the row stays under the finger instead of trailing it by the slop.
          dragStartBehavior: DragStartBehavior.down,
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
              Transform.translate(key: const ValueKey('row'), offset: Offset(dx, 0), child: row),
            ],
          ),
        );
      },
    ),
  );

  /// What the row uncovers. Glass button: the Calls header's round glass button, centred in the
  /// gap, turning into the keypad's lit Call button (the app's blue for Message) once letting go
  /// would act. Flat: the row's whole space in that colour, the glyph beside the row's edge. Both
  /// use the contact page's glyphs ([CallGlyph]) and pop when they arm.
  Widget _background(BuildContext context, String style, double dx, double p) {
    final right = dx > 0;
    final lit = _armed || _confirmed;
    final color = right ? answerGreen : OneUITheme.accentBlue;
    final gap = dx.abs();
    final l10n = context.l10n;
    final icon = right ? Icons.call_rounded : Icons.chat_rounded;
    final label = right ? l10n.call : l10n.message;
    final swell = 1 + 0.08 * math.sin(math.pi * _pop.value);
    final page = context.palette.page;

    // [child] in the gap: centred, or docked beside the row's edge; drawn once, then only moved and scaled.
    Widget place(Widget child, {required double scale, bool docked = false}) {
      final align = docked ? (right ? Alignment.centerRight : Alignment.centerLeft) : Alignment.center;
      return Align(
        alignment: right ? Alignment.centerLeft : Alignment.centerRight,
        child: SizedBox(
          width: gap,
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: align,
            child: Padding(
              padding: docked ? EdgeInsets.only(left: right ? 0 : 24, right: right ? 24 : 0) : EdgeInsets.zero,
              child: Transform.scale(
                scale: scale * swell,
                alignment: align,
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
        ),
      );
    }

    if (style == 'flat') {
      return ColoredBox(
        color: Color.alphaBlend(color.withValues(alpha: lit ? 1 : 0.7), page),
        child: place(
          Semantics(
            label: label,
            child: CallGlyph(icon, color: Colors.white, size: 26),
          ),
          scale: lit ? 1.1 : 0.8 + 0.2 * p,
          docked: true,
        ),
      );
    }
    const size = 48.0; // the header buttons'
    Widget glyph(Color fg) => SizedBox.square(
      dimension: size,
      child: Center(
        child: Semantics(
          label: label,
          child: CallGlyph(icon, color: fg, size: 24),
        ),
      ),
    );
    final button = lit
        ? LitButton(key: const ValueKey('lit'), color: color, shape: const CircleBorder(), child: glyph(Colors.white))
        : CallGlass(
            key: const ValueKey('glass'),
            blur: false, // on the plain page, where a blur shows nothing
            child: glyph(context.palette.textPrimary),
          );
    return ColoredBox(
      color: page,
      child: place(button, scale: 0.55 + 0.45 * p),
    );
  }
}
