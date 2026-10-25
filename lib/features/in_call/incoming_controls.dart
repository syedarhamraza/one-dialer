import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';
import 'call_controls.dart';

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
            child: Row(
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
          SizedBox(height: compact ? 12 : 28),
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

  double get _threshold => SwipeUpButton.threshold * (widget.compact ? .75 : 1);

  // The spring back may wobble just past rest, never fling through to the other side.
  Offset get _offset => _drag * math.max(_hold.value, -.08);

  /// Only an upward drag arms, so a downward brush never fires.
  /// How far up the ball can go: ColorOS's released Answer rests about 1.85 diameters up.
  double get _maxTravel => _threshold * 1.4;

  bool _armedBy(Offset drag) => -drag.dy >= _threshold;

  double _armedFraction(Offset drag) => (-drag.dy / _threshold).clamp(0.0, 1.0);

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

  void _fire() {
    if (_fired) return;
    _fired = true;
    _syncHint();
    HapticFeedback.heavyImpact();
    final box = _ball.currentContext?.findRenderObject() as RenderBox?;
    final rect = box == null || !box.hasSize
        ? Rect.zero
        : MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    // The rest of the way to the travel cap, in global px (the screen may be scaled to `DesignWidth`).
    final scale = box == null || !box.hasSize ? 1.0 : rect.height / box.size.height;
    widget.onTriggered(rect, math.max(0.0, _maxTravel + _offset.dy) * scale);
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
    final limited = Offset(0, (_drag.dy + d.delta.dy).clamp(-_maxTravel, 16.0));
    if (_armedBy(_drag) != _armedBy(limited)) HapticFeedback.selectionClick();
    setState(() => _drag = limited);
    widget.onProgress?.call(_armedFraction(_drag));
  }

  void _onEnd(DragEndDetails d) {
    if (_fired) return;
    if (_armedBy(_drag)) return _fire();
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
      hint: 'Swipe up to ${widget.label.toLowerCase()}',
      onTap: _fire,
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
                final rise = Curves.easeOut.transform((phase / .7).clamp(0.0, 1.0));
                final still = !_dragging && !_fired && offset == Offset.zero;
                final dash = reduceMotion ? .6 : (!still || phase >= .7 ? 0.0 : .9 * (1 - rise));
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: travel - 22 - (reduceMotion ? 0 : 10 * rise),
                      child: Opacity(
                        opacity: dash,
                        child: CustomPaint(size: _ArcHint.size, painter: _ArcHint(widget.color)),
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
                                    widget.color,
                                    const CircleBorder(),
                                    glow: .3 + .25 * armed,
                                    blur: 22 + 10 * armed,
                                  ),
                                  foregroundDecoration: glassGlow(const CircleBorder()),
                                  child: Transform.rotate(
                                    // A decaying wiggle over the first 40% of each cycle, then still.
                                    angle: widget.shake && still && !reduceMotion && phase < .4
                                        ? .3 * math.sin(phase / .4 * 6 * math.pi) * (1 - phase / .4)
                                        : 0,
                                    child: Icon(widget.icon, color: Colors.white, size: size * .52),
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

// The ColorOS swipe hint: a true circular arc (a cap over the button), with rounded ends.
class _ArcHint extends CustomPainter {
  const _ArcHint(this.color);
  final Color color;

  static const double _radius = 15, _sweep = 1.75, _stroke = 3; // 100 degrees
  static final size = Size(
    2 * _radius * math.sin(_sweep / 2) + _stroke,
    _radius * (1 - math.cos(_sweep / 2)) + _stroke,
  );

  @override
  void paint(Canvas canvas, Size size) => canvas.drawArc(
    Rect.fromCircle(center: Offset(size.width / 2, _stroke / 2 + _radius), radius: _radius),
    -math.pi / 2 - _sweep / 2,
    _sweep,
    false,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(_ArcHint oldDelegate) => oldDelegate.color != color;
}
