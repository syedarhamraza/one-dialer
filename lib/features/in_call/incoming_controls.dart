import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_floating_modal.dart';

/// Incoming call, ColorOS style: Decline and Answer side by side, each swiped up to act,
/// with a "Decline with message" pill underneath.
class IncomingControls extends StatelessWidget {
  const IncomingControls({super.key, required this.call, this.isCurrent, this.compact = false});

  final CallInfo call;
  final bool Function()? isCurrent;
  final bool compact;

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
                SwipeUpButton(
                  color: OneUITheme.accentRed,
                  icon: Icons.call_end_rounded,
                  label: 'Decline',
                  compact: compact,
                  onTriggered: () => telecom.reject(call.id),
                ),
                SwipeUpButton(
                  color: OneUITheme.accentGreen,
                  icon: Icons.call_rounded,
                  label: 'Answer',
                  compact: compact,
                  // Offset so the two hints don't pulse in lockstep.
                  hintPhase: .5,
                  onTriggered: () => telecom.answer(call.id),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 28),
          if (canText)
            TextButton.icon(
              onPressed: () => _declineWithMessage(context),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Decline with message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .16),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }
}

/// A call button that acts when released after sliding up past [threshold]; shorter slides
/// spring back and taps do nothing, so pocket touches can't answer or decline. A dash above
/// it rises and fades to show the gesture. Screen readers can activate it directly.
class SwipeUpButton extends StatefulWidget {
  const SwipeUpButton({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTriggered,
    this.compact = false,
    this.hintPhase = 0,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTriggered;
  final bool compact;
  final double hintPhase;

  static const double size = 72;
  static const double threshold = 96;

  @override
  State<SwipeUpButton> createState() => _SwipeUpButtonState();
}

class _SwipeUpButtonState extends State<SwipeUpButton> with TickerProviderStateMixin {
  /// Upward travel in px: 0 at rest, positive while dragged up.
  late final AnimationController _lift = AnimationController.unbounded(vsync: this);
  late final AnimationController _hint = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  bool _dragging = false;
  bool _fired = false;

  double get _threshold => SwipeUpButton.threshold * (widget.compact ? .75 : 1);

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
    widget.onTriggered();
  }

  void _onStart(DragStartDetails _) {
    if (_fired) return;
    _lift.stop();
    setState(() => _dragging = true);
    _syncHint();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_fired) return;
    final before = _lift.value;
    final next = (before - d.delta.dy).clamp(0.0, _threshold * 1.3);
    if ((before >= _threshold) != (next >= _threshold)) HapticFeedback.selectionClick();
    _lift.value = next;
  }

  void _onEnd(DragEndDetails d) {
    if (_fired) return;
    if (_lift.value >= _threshold) return _fire();
    _springBack(-d.velocity.pixelsPerSecond.dy);
  }

  void _springBack([double velocity = 0]) {
    setState(() => _dragging = false);
    _syncHint();
    if (MediaQuery.disableAnimationsOf(context)) {
      _lift.value = 0;
    } else {
      _lift.animateWith(
        SpringSimulation(
          SpringDescription.withDampingRatio(mass: 1, stiffness: 520, ratio: .62),
          _lift.value,
          0,
          velocity,
          snapToEnd: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _lift.dispose();
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
          // Reset the lift at the pointer layer so that end can't trigger anything.
          onPointerCancel: (_) {
            if (!_fired) _lift.value = 0;
          },
          child: SizedBox(
            width: size + 40,
            height: travel + size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_lift, _hint]),
              builder: (context, _) {
                final lift = _lift.value;
                final armed = (lift / _threshold).clamp(0.0, 1.0);
                // The dash drifts up 10 px and fades out, once per cycle.
                final phase = (_hint.value + widget.hintPhase) % 1;
                final rise = Curves.easeOut.transform((phase / .7).clamp(0.0, 1.0));
                final dash = reduceMotion ? .6 : (_dragging || _fired || phase >= .7 ? 0.0 : .9 * (1 - rise));
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: travel - 22 - (reduceMotion ? 0 : 10 * rise),
                      child: Opacity(
                        opacity: dash,
                        child: CustomPaint(size: const Size(26, 6), painter: _ArcHint(widget.color)),
                      ),
                    ),
                    Positioned(
                      top: travel - lift,
                      child: Transform.scale(
                        scale: 1 + .1 * armed,
                        child: Container(
                          key: ValueKey('swipe-${widget.label}'),
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: .45 * armed), blurRadius: 28)],
                          ),
                          child: Icon(widget.icon, color: Colors.white, size: size * .42),
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

/// The ColorOS swipe hint: a shallow arc echoing the button's curve, with rounded ends.
class _ArcHint extends CustomPainter {
  const _ArcHint(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(1.5, size.height - 1.5)
      // A ~2.5 px rise over the width, close to the curve of the 72 px button.
      ..quadraticBezierTo(size.width / 2, size.height - 6.5, size.width - 1.5, size.height - 1.5),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(_ArcHint oldDelegate) => oldDelegate.color != color;
}
