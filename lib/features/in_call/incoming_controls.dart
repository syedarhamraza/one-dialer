import 'dart:math' as math;

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

/// ColorOS 17's 1-button ball: white with a dark handset, until a drag tints it.
const oneButtonWhite = Color(0xFFF2F2F4);
const oneButtonIcon = Color(0xFF2C2C2E);

/// Incoming call, ColorOS 17 style: Decline and Answer side by side, each dragged away to act,
/// with a "Decline with message" pill underneath. Dragging one fades out everything else.
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
  /// Which button is being dragged, and how close it is to acting (0–1).
  String? _active;
  double _armed = 0;

  CallInfo get call => widget.call;
  bool Function()? get isCurrent => widget.isCurrent;
  bool get compact => widget.compact;

  void _progress(String label, double armed) {
    if (_active == label && _armed == armed) return;
    setState(() {
      _active = armed > 0 ? label : null;
      _armed = armed;
    });
  }

  /// Everything but the dragged button fades as it arms.
  double _opacityFor(String? label) => _active == null || _active == label ? 1 : 1 - _armed;

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
            const Text('Decline with message', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (quickReplies.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text('No quick replies saved')),
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
                      label: 'Decline',
                      upColor: endRed,
                      upIcon: Icons.call_end_rounded,
                      compact: compact,
                      onProgress: (armed) => _progress('Answer', armed),
                      hidden: widget.answerHidden,
                      onTriggered: (_, _) => telecom.reject(call.id),
                      onSwipeDown: (ball, lift) =>
                          widget.onAnswer != null ? widget.onAnswer!(ball, lift) : telecom.answer(call.id),
                      downLabel: 'Answer',
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
                      label: 'Answer',
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
                        Opacity(
                          opacity: _opacityFor('Decline'),
                          child: SwipeUpButton(
                            // The connected screen's End red.
                            color: endRed,
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            compact: compact,
                            onProgress: (armed) => _progress('Decline', armed),
                            onTriggered: (_, _) => telecom.reject(call.id),
                          ),
                        ),
                        Opacity(
                          opacity: _opacityFor('Answer'),
                          child: SwipeUpButton(
                            color: answerGreen,
                            icon: Icons.call_rounded,
                            // The handset rings, like ColorOS's Answer.
                            shake: true,
                            label: 'Answer',
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
          // leaving room under it to glide down to the answer spot.
          ValueListenableBuilder(
            valueListenable: DialerPrefs.instance.answerStyle,
            builder: (context, style, _) =>
                SizedBox(height: (compact ? 12 : 28) + (style == 'one' ? (compact ? 40 : 116) : 0)),
          ),
          if (canText)
            Opacity(
              opacity: _opacityFor(null),
              // Frosted like the connected screen's buttons, with the same glass press.
              child: CallBody(
                pill: true,
                child: TextButton.icon(
                  onPressed: () => _declineWithMessage(context),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                  label: const Text(
                    'Decline with message',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const StadiumBorder(),
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
    this.downLabel = 'Decline',
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
  final String downLabel;
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

  /// Where a released 1-button ball comes to rest, from its start: 1.85 diameters, about half a
  /// diameter under the End pill it then springs up into, as recorded.
  double get _answerSpot => SwipeUpButton.size * (widget.compact ? .85 : 1) * 1.85;

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
    // The rest of the way to the travel cap (or the 1-button answer spot), in global px (the screen
    // may be scaled to `DesignWidth`); negative is downward.
    final scale = box == null || !box.hasSize ? 1.0 : rect.height / box.size.height;
    final shown = _offset.dy;
    if (down) return widget.onSwipeDown!(rect, -math.max(0.0, _answerSpot - shown) * scale);
    final cap = _twoWay ? _answerSpot : _maxTravel;
    widget.onTriggered(rect, math.max(0.0, cap + shown) * scale);
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

  @override
  Widget build(BuildContext context) {
    final size = SwipeUpButton.size * (widget.compact ? .85 : 1);
    final travel = _threshold + 28;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.label,
      hint: _twoWay
          ? 'Swipe up to ${widget.label.toLowerCase()}, down to ${widget.downLabel.toLowerCase()}'
          : 'Swipe up to ${widget.label.toLowerCase()}',
      onTap: _fire,
      customSemanticsActions: _twoWay
          ? {CustomSemanticsAction(label: widget.downLabel): () => _fire(down: true)}
          : null,
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
            child: AnimatedBuilder(
              animation: Listenable.merge([_hold, _hint]),
              builder: (context, _) {
                final offset = _offset;
                final armed = _armedFraction(offset);
                // The dash drifts up 10 px and fades out, once per cycle.
                final phase = (_hint.value + widget.hintPhase) % 1;
                // The 1-button arcs hold still, as on ColorOS 17; the 2-button dashes drift up and fade.
                final rise = _twoWay ? 0.0 : Curves.easeOut.transform((phase / .7).clamp(0.0, 1.0));
                final still = !_dragging && !_fired && offset == Offset.zero;
                // As on ColorOS 17, the 1-button arcs stay put while the ball is held and go once it's let go.
                final dash = _twoWay
                    ? (_fired ? 0.0 : (reduceMotion ? .6 : .9))
                    : reduceMotion
                    ? .6
                    : (!still || phase >= .7 ? 0.0 : .9 * (1 - rise));
                // Swiping down turns the ball into Decline.
                // A two-way ball takes on the look of the action it's heading for.
                final goingDown = offset.dy > 0;
                // The 1-button ball turns red or green as it follows the finger toward that side.
                final turn = !_twoWay ? 0.0 : (_fired ? 1.0 : armed);
                final color = Color.lerp(
                  widget.color,
                  goingDown ? widget.downColor : widget.upColor ?? widget.color,
                  turn,
                )!;
                final iconColor = Color.lerp(widget.iconColor, Colors.white, turn)!;
                final upHint = ArcHint(widget.upColor ?? widget.color);
                // The arc the 1-button ball is pulled over fades, rather than showing through its tint.
                final upDash = _twoWay && !goingDown ? dash * (1 - armed) : dash;
                final downDash = goingDown ? dash * (1 - armed) : dash;
                final downHint = ArcHint(widget.downColor);
                final target = goingDown ? widget.downIcon : widget.upIcon ?? widget.icon;
                // Toward Decline the handset morphs as in the Answer → End flight: it tips over, then
                // the hang-up glyph fades in over it before the handset fades out underneath.
                final morph = target == widget.icon ? 0.0 : turn;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: travel - 22 - (reduceMotion ? 0 : 10 * rise),
                      child: Opacity(
                        opacity: upDash,
                        child: CustomPaint(size: upHint.size, painter: upHint),
                      ),
                    ),
                    if (_twoWay)
                      Positioned(
                        // The same dash mirrored under the ball, drifting down.
                        top: travel + size + 22 - downHint.size.height + (reduceMotion ? 0 : 10 * rise),
                        child: Opacity(
                          opacity: downDash,
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: CustomPaint(size: downHint.size, painter: downHint),
                          ),
                        ),
                      ),
                    Positioned(
                      top: travel,
                      child: Transform.translate(
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
                                  foregroundDecoration: glassGlow(const CircleBorder(), flat: callFlat(context)),
                                  child: Transform.rotate(
                                    // A decaying wiggle over the first 40% of each cycle, then still.
                                    angle: widget.shake && still && !reduceMotion && phase < .4
                                        ? .3 * math.sin(phase / .4 * 6 * math.pi) * (1 - phase / .4)
                                        : 0,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Opacity(
                                          opacity: 1 - ((morph - .6) / .4).clamp(0.0, 1.0),
                                          child: Transform.rotate(
                                            angle: 2.36 * Curves.easeInOut.transform(morph),
                                            child: Icon(widget.icon, color: iconColor, size: size * .52),
                                          ),
                                        ),
                                        if (morph > .4)
                                          Opacity(
                                            opacity: ((morph - .4) / .4).clamp(0.0, 1.0),
                                            child: Icon(target, color: iconColor, size: size * .52),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The ColorOS swipe hint: a true circular arc (a cap over the button), with rounded ends.
/// Also drawn small in Settings' previews.
class ArcHint extends CustomPainter {
  const ArcHint(this.color, {this.radius = 15, this.stroke = 3});
  final Color color;
  final double radius, stroke;

  static const double _sweep = 1.75; // 100 degrees

  Size get size => Size(2 * radius * math.sin(_sweep / 2) + stroke, radius * (1 - math.cos(_sweep / 2)) + stroke);

  @override
  void paint(Canvas canvas, Size size) => canvas.drawArc(
    Rect.fromCircle(center: Offset(size.width / 2, stroke / 2 + radius), radius: radius),
    -math.pi / 2 - _sweep / 2,
    _sweep,
    false,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(ArcHint oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius || oldDelegate.stroke != stroke;
}
