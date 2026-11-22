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
import 'press_glow.dart' show LitButton;

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
  // Past the threshold the row follows the finger this much (a rubber band), so it can't fly off.
  static const _resistance = 0.5;
  // The app's ColorOS spring (the Calls header morph's).
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 240, ratio: .78);

  // Unbounded: the controller's value is the row's offset in pixels.
  late final _dx = AnimationController.unbounded(vsync: this)..addListener(() => setState(() {}));
  // The glass pill's swell when it arms, and its held flash when the swipe acts.
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
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
        final card = style == 'card';
        final p = (dx.abs() / (_width * _threshold)).clamp(0.0, 1.0);
        // Its own layer: sliding (and Card lift's shrink) only moves the row's picture, never
        // repaints its text, avatar and buttons.
        Widget row = RepaintBoundary(child: widget.child);
        // Opaque, so the background shows only where the row has moved away. Card lift turns the
        // row into one of the app's grey cards as it pulls away. The same widgets at rest and while
        // sliding, so starting a swipe never rebuilds the row.
        final lift = card ? p : 0.0;
        row = Transform.scale(
          scale: 1 - 0.04 * lift,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: lift > 0 ? context.palette.card : context.palette.page,
              shape: SquircleBorder(borderRadius: BorderRadius.circular(OneUITheme.radiusCard * lift)),
            ),
            child: row,
          ),
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

  /// What the row uncovers: only the app's own buttons. Before letting go would act, the Calls
  /// header's glass (a circle, or the keypad's stadium key); after, the keypad's lit Call button
  /// (the app's blue for Message), with a small pop. They follow Settings › Reduce visual effects.
  Widget _background(BuildContext context, String style, double dx, double p) {
    final right = dx > 0;
    final lit = _armed || _confirmed;
    final color = right ? answerGreen : OneUITheme.accentBlue;
    final gap = dx.abs();
    final l10n = context.l10n;
    final icon = right ? Icons.call_rounded : Icons.message_rounded;
    final label = right ? l10n.call : l10n.message;
    final swell = 1 + 0.08 * math.sin(math.pi * _pop.value);
    const size = 48.0; // the header buttons' and the keypad keys' height

    Widget button({required bool glass, bool key = false}) {
      final fg = glass ? context.palette.textPrimary : Colors.white;
      final content = Container(
        width: key ? null : size,
        height: size,
        // The key fits its word (Message, Messaggio...) with the keypad keys' side room.
        padding: EdgeInsets.symmetric(horizontal: key ? 22 : 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: fg, semanticLabel: label),
            if (key) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg),
              ),
            ],
          ],
        ),
      );
      final OutlinedBorder shape = key ? const StadiumBorder() : const CircleBorder();
      return glass
          ? CallGlass(
              key: const ValueKey('glass'),
              radius: key ? size / 2 : null,
              blur: false, // on the plain page, where a blur shows nothing
              child: content,
            )
          : LitButton(key: const ValueKey('lit'), color: color, shape: shape, child: content);
    }

    // [child] in the gap: centred, or docked beside the row's edge.
    Widget place(Widget child, {required double scale, bool docked = false}) => Align(
      alignment: right ? Alignment.centerLeft : Alignment.centerRight,
      child: SizedBox(
        width: gap,
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          alignment: docked ? (right ? Alignment.centerRight : Alignment.centerLeft) : Alignment.center,
          child: Padding(
            padding: docked ? EdgeInsets.only(left: right ? 0 : 12, right: right ? 12 : 0) : EdgeInsets.zero,
            child: Transform.scale(
              scale: scale * swell,
              alignment: docked ? (right ? Alignment.centerRight : Alignment.centerLeft) : Alignment.center,
              // Drawn once (glass, rim, glow), then only moved and scaled.
              child: RepaintBoundary(child: child),
            ),
          ),
        ),
      ),
    );

    final grow = 0.55 + 0.45 * p;
    final Widget content = switch (style) {
      // Glass key: the keypad's stadium key with the word, riding at the row's edge.
      // (shrunk to fit while the gap is narrower than the key, so it never runs off the screen)
      'wash' => place(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.max(1, gap - 24)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: button(glass: !lit, key: true),
          ),
        ),
        scale: grow,
        docked: true,
      ),
      // Green button: the shell's lit green button the whole way, small until it would act.
      'bubble' => place(button(glass: false), scale: lit ? 1 : 0.45 + 0.4 * p),
      // Card lift: the row becomes a card; the glass button waits beside it.
      'card' => place(button(glass: !lit), scale: grow, docked: true),
      // Glass button: the header's round glass button, centred in the gap.
      _ => place(button(glass: !lit), scale: grow),
    };
    return ColoredBox(color: context.palette.page, child: content);
  }
}
