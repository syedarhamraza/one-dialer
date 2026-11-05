import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';
import 'call_controls.dart';
import '../../l10n/l10n.dart';
import '../../widgets/call_glyph.dart';

/// ColorOS 17's 1-button ball: white with a dark handset, until a drag tints it.
const oneButtonWhite = Color(0xFFF2F2F4);
const oneButtonIcon = Color(0xFF2C2C2E);

/// Incoming call, ColorOS 17 style: Decline and Answer side by side, each dragged away to act,
/// with a text-only "Decline with SMS" pill underneath. Dragging one fades out everything else.
class IncomingControls extends StatefulWidget {
  const IncomingControls({
    super.key,
    required this.call,
    this.isCurrent,
    this.compact = false,
    this.onAnswer,
    this.answerHidden = false,
  });

  final CallInfo call;
  final bool Function()? isCurrent;
  final bool compact;

  /// Answers with the released ball's global rect and how far (global px) it still glides up to
  /// the top of its travel, so the screen can carry it on and fly it into the End pill.
  final void Function(Rect ball, double lift)? onAnswer;

  /// Hides the Answer ball once the screen has taken it over for that flight.
  final bool answerHidden;

  @override
  State<IncomingControls> createState() => _IncomingControlsState();
}

class _IncomingControlsState extends State<IncomingControls> {
  /// Which button is being dragged, and how close it is to acting (0–1). A notifier so a drag
  /// frame repaints only the fading neighbours, not the whole panel.
  final _dragged = ValueNotifier<(String?, double)>((null, 0));

  CallInfo get call => widget.call;
  bool Function()? get isCurrent => widget.isCurrent;
  bool get compact => widget.compact;

  void _progress(String label, double armed) => _dragged.value = (armed > 0 ? label : null, armed);

  /// Everything but the dragged button fades as it arms.
  Widget _fading(String? label, {required Widget child}) => ValueListenableBuilder(
    valueListenable: _dragged,
    builder: (context, dragged, child) {
      final (active, armed) = dragged;
      return Opacity(opacity: active == null || active == label ? 1 : 1 - armed, child: child);
    },
    child: child,
  );

  @override
  void dispose() {
    _dragged.dispose();
    super.dispose();
  }

  Future<void> _declineWithMessage(BuildContext context) async {
    // Edited in Settings › Quick decline messages.
    final quickReplies = await TelecomBridge.instance.getQuickReplies();
    if (!context.mounted || isCurrent?.call() == false) return;
    final message = await OneUIFloatingModal.show<String>(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.declineWithSms, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (quickReplies.isEmpty)
                    Padding(padding: const EdgeInsets.all(16), child: Text(context.l10n.noQuickReplies)),
                  for (final m in quickReplies)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m),
                      onTap: () => Navigator.of(context).pop(m),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (message != null && context.mounted && isCurrent?.call() != false) {
      await TelecomBridge.instance.rejectWithMessage(call.id, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final telecom = TelecomBridge.instance;
    final canText = !call.isPrivate && (call.number?.isNotEmpty ?? false);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Near the edges like ColorOS, leaving room between the two targets.
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 20),
            child: ListenableBuilder(
              // Settings › Answer buttons › 1 button: one ball, up answers and down declines, or the
              // other way round with "Swipe down to answer".
              listenable: Listenable.merge([DialerPrefs.instance.answerStyle, DialerPrefs.instance.answerDirection]),
              builder: (context, _) =>
                  DialerPrefs.instance.answerStyle.value == 'one' &&
                      DialerPrefs.instance.answerDirection.value == 'down'
                  ? SwipeUpButton(
                      color: oneButtonWhite,
                      iconColor: oneButtonIcon,
                      icon: Icons.call_rounded,
                      shake: true,
                      label: context.l10n.decline,
                      upColor: endRed,
                      upIcon: Icons.call_end_rounded,
                      compact: compact,
                      onProgress: (armed) => _progress('Answer', armed),
                      hidden: widget.answerHidden,
                      onTriggered: (_, _) => telecom.reject(call.id),
                      onSwipeDown: (ball, lift) =>
                          widget.onAnswer != null ? widget.onAnswer!(ball, lift) : telecom.answer(call.id),
                      downLabel: context.l10n.answer,
                      downColor: answerGreen,
                      downIcon: Icons.call_rounded,
                    )
                  : DialerPrefs.instance.answerStyle.value == 'one'
                  ? SwipeUpButton(
                      color: oneButtonWhite,
                      iconColor: oneButtonIcon,
                      upColor: answerGreen,
                      icon: Icons.call_rounded,
                      shake: true,
                      label: context.l10n.answer,
                      compact: compact,
                      hidden: widget.answerHidden,
                      onProgress: (armed) => _progress('Answer', armed),
                      onTriggered: (ball, lift) =>
                          widget.onAnswer != null ? widget.onAnswer!(ball, lift) : telecom.answer(call.id),
                      onSwipeDown: (_, _) => telecom.reject(call.id),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _fading(
                          'Decline',
                          child: SwipeUpButton(
                            // The connected screen's End red.
                            color: endRed,
                            icon: Icons.call_end_rounded,
                            label: context.l10n.decline,
                            compact: compact,
                            onProgress: (armed) => _progress('Decline', armed),
                            onTriggered: (_, _) => telecom.reject(call.id),
                          ),
                        ),
                        _fading(
                          'Answer',
                          child: SwipeUpButton(
                            color: answerGreen,
                            icon: Icons.call_rounded,
                            // The handset rings, like ColorOS's Answer.
                            shake: true,
                            label: context.l10n.answer,
                            compact: compact,
                            hidden: widget.answerHidden,
                            // Offset so the two hints don't pulse in lockstep.
                            hintPhase: .5,
                            onProgress: (armed) => _progress('Answer', armed),
                            onTriggered: (ball, lift) =>
                                widget.onAnswer != null ? widget.onAnswer!(ball, lift) : telecom.answer(call.id),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // ColorOS 17 rests the 1-button ball high, about 260 dp above the screen's bottom edge,
          // leaving room under it to be pulled down toward End.
          ValueListenableBuilder(
            valueListenable: DialerPrefs.instance.answerStyle,
            builder: (context, style, _) =>
                SizedBox(height: (compact ? 12 : 28) + (style == 'one' ? (compact ? 40 : 116) : 0)),
          ),
          if (canText)
            _fading(
              null,
              // Frosted like the connected screen's buttons, with the same glass press.
              child: CallBody(
                pill: true,
                child: TextButton(
                  onPressed: () => _declineWithMessage(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    context.l10n.declineWithSms,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A call button that follows the finger anywhere and acts when released at least [threshold]
/// away and above where it started; shorter or downward drags spring back and taps do nothing,
/// so pocket touches can't answer or decline. A dash above it rises and fades to show the
/// gesture. Screen readers can activate it directly.
class SwipeUpButton extends StatefulWidget {
  const SwipeUpButton({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTriggered,
    this.onProgress,
    this.compact = false,
    this.hidden = false,
    this.hintPhase = 0,
    this.shake = false,
    this.onSwipeDown,
    this.downLabel,
    this.downColor = endRed,
    this.downIcon = Icons.call_end_rounded,
    this.upColor,
    this.upIcon,
    this.iconColor = Colors.white,
  });

  final Color color;

  final IconData icon;
  final String label;

  /// Gets the ball's global rect where it was released (its resting rect from a screen reader) and
  /// the global distance left to the top of its travel.
  final void Function(Rect ball, double lift) onTriggered;

  /// How armed the drag is, 0 at rest to 1 at [threshold].
  final ValueChanged<double>? onProgress;
  final bool compact;
  final bool hidden;
  final double hintPhase;

  /// Wiggles the icon once per hint cycle while the ball rests, as a ringing handset.
  final bool shake;

  /// Makes a downward swipe act too (1-button answering): the ball rests in [color] and turns
  /// [downColor] with [downIcon] on the way down, and [upColor] with [upIcon] on the way up,
  /// like ColorOS 17's white ball between a red and a green arc.
  final void Function(Rect ball, double lift)? onSwipeDown;
  final String? downLabel;
  final Color downColor;
  final IconData downIcon;
  final Color? upColor;
  final IconData? upIcon;
  final Color iconColor;

  static const double size = 72;
  static const double threshold = 96;

  @override
  State<SwipeUpButton> createState() => _SwipeUpButtonState();
}

class _SwipeUpButtonState extends State<SwipeUpButton> with TickerProviderStateMixin {
  /// Where the finger has taken the ball, relative to its resting place.
  Offset _drag = Offset.zero;

  /// Scales [_drag]: 1 while held, springing to 0 when let go short.
  late final AnimationController _hold = AnimationController.unbounded(vsync: this, value: 1);
  late final AnimationController _hint = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  final _ball = GlobalKey();
  bool _dragging = false;
  bool _fired = false;

  // ColorOS 17's 1-button ball arms after a short pull (a few frames of the finger in its recording).
  double get _threshold => (_twoWay ? 80 : SwipeUpButton.threshold) * (widget.compact ? .75 : 1);

  // The spring back may wobble just past rest, never fling through to the other side.
  Offset get _offset => _drag * math.max(_hold.value, -.08);

  /// Only an upward drag arms, so a downward brush never fires.
  /// How far up the ball can go: ColorOS's released Answer rests about 1.85 diameters up.
  double get _maxTravel => _threshold * 1.4;

  bool get _twoWay => widget.onSwipeDown != null;

  bool _armedBy(Offset drag) => (_twoWay ? drag.dy.abs() : -drag.dy) >= _threshold;

  double _armedFraction(Offset drag) => ((_twoWay ? drag.dy.abs() : -drag.dy) / _threshold).clamp(0.0, 1.0);

  /// Touched: the ball grows a little under the finger, like a glass button.
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down && mounted) setState(() => _pressed = down);
  }

  @override
  void initState() {
    super.initState();
    _hold.addListener(() {
      if (!_dragging && !_fired) widget.onProgress?.call(_armedFraction(_offset));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHint();
  }

  void _syncHint() {
    final run = !_dragging && !_fired && !MediaQuery.disableAnimationsOf(context);
    if (run && !_hint.isAnimating) {
      _hint.repeat();
    } else if (!run && _hint.isAnimating) {
      _hint.stop();
    }
  }

  void _fire({bool down = false}) {
    if (_fired) return;
    _fired = true;
    _syncHint();
    HapticFeedback.heavyImpact();
    final box = _ball.currentContext?.findRenderObject() as RenderBox?;
    final rect = box == null || !box.hasSize
        ? Rect.zero
        : MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    // The 1-button ball turns into End from where it's let go; the 2-button one glides on to the
    // travel cap first, in global px (the screen may be scaled to `DesignWidth`).
    if (down) return widget.onSwipeDown!(rect, 0);
    final scale = box == null || !box.hasSize ? 1.0 : rect.height / box.size.height;
    widget.onTriggered(rect, _twoWay ? 0 : math.max(0.0, _maxTravel + _offset.dy) * scale);
  }

  void _onStart(DragStartDetails _) {
    if (_fired) return;
    _drag = _offset;
    _hold
      ..stop()
      ..value = 1;
    setState(() => _dragging = true);
    _syncHint();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_fired) return;
    // Straight up only, a little past the threshold; downward can't act, so it only gives a
    // little and never slides under the pill below.
    final limited = Offset(0, (_drag.dy + d.delta.dy).clamp(-_maxTravel, _twoWay ? _maxTravel : 16.0));
    if (_armedBy(_drag) != _armedBy(limited)) HapticFeedback.selectionClick();
    setState(() => _drag = limited);
    widget.onProgress?.call(_armedFraction(_drag));
  }

  void _onEnd(DragEndDetails d) {
    if (_fired) return;
    if (_armedBy(_drag)) return _fire(down: _drag.dy > 0);
    _springBack(d.velocity.pixelsPerSecond);
  }

  void _springBack([Offset velocity = Offset.zero]) {
    setState(() => _dragging = false);
    _syncHint();
    if (MediaQuery.disableAnimationsOf(context) || _drag == Offset.zero) {
      _drag = Offset.zero;
      _hold.value = 1;
      widget.onProgress?.call(0);
      return;
    }
    // The fling's speed along the drag, as a rate of change of the 0-1 hold.
    // A third of the fling carries into the return, so a hard flick can't hurl the ball past rest.
    final along = .35 * (velocity.dx * _drag.dx + velocity.dy * _drag.dy) / (_drag.distance * _drag.distance);
    _hold.animateWith(SpringSimulation(GlassSpring.snappy(), _hold.value, 0, along, snapToEnd: true));
  }

  @override
  void dispose() {
    _hold.dispose();
    _hint.dispose();
    super.dispose();
  }

  /// "answer" or "decline" for the swipe hint, in the app's language.
  String _verb(String label) => label == context.l10n.answer ? context.l10n.answerVerb : context.l10n.declineVerb;

  @override
  Widget build(BuildContext context) {
    final size = SwipeUpButton.size * (widget.compact ? .85 : 1);
    final travel = _threshold + 28;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final downLabel = widget.downLabel ?? context.l10n.decline;
    return Semantics(
      button: true,
      label: widget.label,
      hint: _twoWay
          ? context.l10n.swipeUpDownHint(_verb(widget.label), _verb(downLabel))
          : context.l10n.swipeUpHint(_verb(widget.label)),
      onTap: _fire,
      customSemanticsActions: _twoWay ? {CustomSemanticsAction(label: downLabel): () => _fire(down: true)} : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onStart,
        onVerticalDragUpdate: _onUpdate,
        onVerticalDragEnd: _onEnd,
        onVerticalDragCancel: () {
          if (!_fired) _springBack();
        },
        child: Listener(
          // A cancelled accepted drag can be reported as a drag end by the recognizer.
          // Reset the drag at the pointer layer so that end can't trigger anything.
          onPointerDown: (_) => _press(true),
          onPointerUp: (_) => _press(false),
          onPointerCancel: (_) {
            _press(false);
            if (!_fired) _drag = Offset.zero;
          },
          child: SizedBox(
            width: size + 40,
            height: travel + size,
            // Three layers that each repaint only for what moves them: the arcs and the icon with the
            // idle hint, the ball's blurred glass only with the drag, so a ringing ball isn't repainted
            // every frame.
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_hold, _hint]),
                      builder: (context, _) => _arcs(size, travel, reduceMotion),
                    ),
                  ),
                ),
                Positioned(
                  top: travel,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _hold,
                      builder: (context, icon) => _body(size, reduceMotion, icon!),
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_hold, _hint]),
                          builder: (context, _) => _icon(size, reduceMotion),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Where the idle hint is in its cycle.
  double get _phase => (_hint.value + widget.hintPhase) % 1;

  bool get _still => !_dragging && !_fired && _offset == Offset.zero;

  // Swiping down turns the ball into Decline.
  bool get _goingDown => _offset.dy > 0;

  /// A two-way ball takes on the look of the action it's heading for: the 1-button ball turns red
  /// or green as it follows the finger toward that side.
  double get _turn => !_twoWay ? 0.0 : (_fired ? 1.0 : _armedFraction(_offset));

  Widget _arcs(double size, double travel, bool reduceMotion) {
    final armed = _armedFraction(_offset);
    // The dash drifts up 10 px and fades out, once per cycle.
    final phase = _phase;
    final still = _still;
    // Idle, every ball's arcs drift away from it and fade, once per cycle. The 1-button arcs
    // hold still while the ball is held, so the one it's pulled over can fade, and go once it's let go.
    final rise = _twoWay && !still ? 0.0 : Curves.easeOut.transform((phase / .7).clamp(0.0, 1.0));
    final dash = reduceMotion
        ? (_twoWay && _fired ? 0.0 : .6)
        : _twoWay && !still
        ? (_fired ? 0.0 : .9)
        : (!still || phase >= .7 ? 0.0 : .9 * (1 - rise));
    final goingDown = _goingDown;
    // The arc the 1-button ball is pulled over fades, rather than showing through its tint.
    final upDash = _twoWay && !goingDown ? dash * (1 - armed) : dash;
    final downDash = goingDown ? dash * (1 - armed) : dash;
    // The fade is the stroke's alpha: one stroke, so no layer is needed for it.
    final upHint = ArcHint((widget.upColor ?? widget.color).withValues(alpha: upDash), radius: size / 2);
    final downHint = ArcHint(widget.downColor.withValues(alpha: downDash), radius: size / 2);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: travel - 22 - (reduceMotion ? 0 : 10 * rise),
          child: CustomPaint(size: upHint.size, painter: upHint),
        ),
        if (_twoWay)
          Positioned(
            // The same dash mirrored under the ball, drifting down.
            top: travel + size + 22 - downHint.size.height + (reduceMotion ? 0 : 10 * rise),
            child: RotatedBox(
              quarterTurns: 2,
              child: CustomPaint(size: downHint.size, painter: downHint),
            ),
          ),
      ],
    );
  }

  Widget _body(double size, bool reduceMotion, Widget icon) {
    final offset = _offset;
    final armed = _armedFraction(offset);
    final color = Color.lerp(widget.color, _goingDown ? widget.downColor : widget.upColor ?? widget.color, _turn)!;
    return Transform.translate(
      offset: offset,
      child: AnimatedScale(
        scale: _pressed && !_fired ? 1.08 : 1,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: Transform.scale(
          scale: 1 + .1 * armed,
          child: Opacity(
            opacity: widget.hidden ? 0 : 1,
            child: KeyedSubtree(
              key: _ball,
              child: Container(
                key: ValueKey('swipe-${widget.label}'),
                width: size,
                height: size,
                // The connected screen's End pill finish, lit from below, its glow
                // brightening as the drag arms.
                decoration: glassBody(
                  color,
                  const CircleBorder(),
                  glow: .3 + .25 * armed,
                  blur: 22 + 10 * armed,
                  flat: callFlat(context),
                ),
                foregroundDecoration: callGlassGlow(context, const CircleBorder()),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(double size, bool reduceMotion) {
    final phase = _phase;
    final turn = _turn;
    final iconColor = Color.lerp(widget.iconColor, Colors.white, turn)!;
    final target = _goingDown ? widget.downIcon : widget.upIcon ?? widget.icon;
    // Toward Decline the handset crossfades into the hang-up glyph alongside the colour, each
    // glyph faded by its colour's alpha.
    final morph = target == widget.icon ? 0.0 : turn;
    return Transform.rotate(
      // A decaying wiggle over the first 40% of each cycle, then still.
      angle: widget.shake && _still && !reduceMotion && phase < .4
          ? .3 * math.sin(phase / .4 * 6 * math.pi) * (1 - phase / .4)
          : 0,
      // Our hang-up glyph is the handset turned 135°: tip the one handset over instead of crossfading.
      child: widget.icon == Icons.call_rounded && target == Icons.call_end_rounded
          ? Transform.rotate(
              angle: 3 * math.pi / 4 * morph,
              child: CallGlyph(
                widget.icon,
                color: iconColor,
                size: size * .52 * lerpDouble(1, CallGlyph.tipGrowth, morph)!,
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                CallGlyph(
                  widget.icon,
                  color: iconColor.withValues(alpha: iconColor.a * (1 - morph)),
                  size: size * .52,
                ),
                if (morph > 0)
                  CallGlyph(
                    target,
                    color: iconColor.withValues(alpha: iconColor.a * morph),
                    size: size * .52,
                  ),
              ],
            ),
    );
  }
}

/// The ColorOS swipe hint: a true circular arc with rounded ends, as round as the ball it caps
/// ([radius] is the ball's). Also drawn small in Settings' previews.
class ArcHint extends CustomPainter {
  const ArcHint(this.color, {required this.radius, this.stroke = 3, this.sweep = .75});
  final Color color;
  final double radius, stroke;

  /// In radians: .75 is about 43 degrees, a short cap.
  final double sweep;

  Size get size => Size(2 * radius * math.sin(sweep / 2) + stroke, radius * (1 - math.cos(sweep / 2)) + stroke);

  @override
  void paint(Canvas canvas, Size size) => canvas.drawArc(
    Rect.fromCircle(center: Offset(size.width / 2, stroke / 2 + radius), radius: radius),
    -math.pi / 2 - sweep / 2,
    sweep,
    false,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(ArcHint oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.stroke != stroke ||
      oldDelegate.sweep != sweep;
}
