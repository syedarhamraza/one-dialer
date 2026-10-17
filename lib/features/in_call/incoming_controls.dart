import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_floating_modal.dart';

/// Incoming call, ColorOS style: slide the handle up to answer or down to decline, with
/// Message and Decline buttons beside it.
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
      padding: EdgeInsets.only(bottom: compact ? 8 : 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: canText
                ? _SideButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Message',
                    tooltip: 'Decline with message',
                    color: Colors.white.withValues(alpha: .16),
                    onPressed: () => _declineWithMessage(context),
                  )
                : const SizedBox.shrink(),
          ),
          SlideToAnswer(
            compact: compact,
            onAnswer: () => telecom.answer(call.id),
            onDecline: () => telecom.reject(call.id),
          ),
          Expanded(
            child: _SideButton(
              icon: Icons.call_end_rounded,
              label: 'Decline',
              color: OneUITheme.accentRed,
              onPressed: () {
                HapticFeedback.mediumImpact();
                telecom.reject(call.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });
  final IconData icon;
  final String label;
  final String? tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(
        dimension: 56,
        child: IconButton(
          tooltip: tooltip ?? label,
          iconSize: 26,
          style: IconButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: const CircleBorder()),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
      const SizedBox(height: 8),
      ExcludeSemantics(
        child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
      ),
    ],
  );
}

/// A handle that answers when released after sliding up past [upThreshold] and declines when
/// released after sliding down past [downThreshold]; anything shorter springs back. Taps do
/// nothing, so pocket touches can't answer; screen readers get Answer and Decline actions.
class SlideToAnswer extends StatefulWidget {
  const SlideToAnswer({super.key, required this.onAnswer, required this.onDecline, this.compact = false});

  final VoidCallback onAnswer;
  final VoidCallback onDecline;
  final bool compact;

  static const double handle = 76;
  static const double upThreshold = 110;
  static const double downThreshold = 64;

  @override
  State<SlideToAnswer> createState() => _SlideToAnswerState();
}

class _SlideToAnswerState extends State<SlideToAnswer> with TickerProviderStateMixin {
  /// Handle offset in px: negative is up (answer), positive is down (decline).
  late final AnimationController _offset = AnimationController.unbounded(vsync: this);
  late final AnimationController _hint = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _dragging = false;
  bool _fired = false;

  double get _scale => widget.compact ? .7 : 1;
  double get _up => SlideToAnswer.upThreshold * _scale;
  double get _down => SlideToAnswer.downThreshold * _scale;

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
      _hint
        ..stop()
        ..value = 0;
    }
  }

  void _fire(VoidCallback action) {
    if (_fired) return;
    _fired = true;
    _syncHint();
    HapticFeedback.heavyImpact();
    action();
  }

  void _onStart(DragStartDetails _) {
    if (_fired) return;
    _offset.stop();
    setState(() => _dragging = true);
    _syncHint();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_fired) return;
    final before = _offset.value;
    final next = (before + d.delta.dy).clamp(-_up * 1.25, _down * 1.25);
    if ((before > -_up) != (next > -_up) || (before < _down) != (next < _down)) HapticFeedback.selectionClick();
    _offset.value = next;
  }

  void _onEnd(DragEndDetails d) {
    if (_fired) return;
    final y = _offset.value;
    if (y <= -_up) return _fire(widget.onAnswer);
    if (y >= _down) return _fire(widget.onDecline);
    _springBack(d.velocity.pixelsPerSecond.dy);
  }

  void _springBack([double velocity = 0]) {
    setState(() => _dragging = false);
    _syncHint();
    if (MediaQuery.disableAnimationsOf(context)) {
      _offset.value = 0;
    } else {
      _offset.animateWith(
        SpringSimulation(
          SpringDescription.withDampingRatio(mass: 1, stiffness: 520, ratio: .62),
          _offset.value,
          0,
          velocity,
          snapToEnd: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _offset.dispose();
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = SlideToAnswer.handle * (widget.compact ? .85 : 1);
    final above = _up + 44 * _scale;
    final below = _down + 8;
    return Semantics(
      button: true,
      label: 'Answer',
      hint: 'Swipe up to answer, down to decline',
      onTap: () => _fire(widget.onAnswer),
      customSemanticsActions: {const CustomSemanticsAction(label: 'Decline'): () => _fire(widget.onDecline)},
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
          // Reset the offset at the pointer layer so that end can't trigger anything.
          onPointerCancel: (_) {
            if (!_fired) _offset.value = 0;
          },
          child: SizedBox(
            width: size + 48,
            height: above + size + below,
            child: AnimatedBuilder(
              animation: Listenable.merge([_offset, _hint]),
              builder: (context, _) {
                final y = _offset.value;
                final answer = (-y / _up).clamp(0.0, 1.0);
                final decline = (y / _down).clamp(0.0, 1.0);
                final h = _hint.value;
                final bob = _dragging || _fired ? 0.0 : -7 * math.pow(math.sin(math.pi * h), 2).toDouble();
                final color = Color.lerp(
                  Color.lerp(Colors.white, OneUITheme.accentGreen, answer),
                  OneUITheme.accentRed,
                  decline,
                )!;
                final iconColor = answer > .5 || decline > .5 ? Colors.white : OneUITheme.accentGreen;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Chevrons climb toward the answer point.
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        top: above - 30 * _scale - i * 18 * _scale,
                        child: Opacity(
                          opacity: (1 - answer - decline).clamp(0.0, 1.0) * _chevron(h, i),
                          child: Icon(Icons.keyboard_arrow_up_rounded, size: 30 * _scale, color: Colors.white),
                        ),
                      ),
                    Positioned(
                      top: above - 30 * _scale - 3 * 18 * _scale - 18,
                      child: Opacity(
                        opacity: (1 - 2 * (answer + decline)).clamp(0.0, 1.0),
                        child: const ExcludeSemantics(
                          child: Text('Swipe up to answer', style: TextStyle(fontSize: 13, color: Colors.white70)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: above + y + bob,
                      child: Transform.scale(
                        scale: 1 + .08 * math.max(answer, decline),
                        child: Container(
                          key: const ValueKey('answer-handle'),
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.lerp(Colors.black26, color.withValues(alpha: .5), math.max(answer, decline))!,
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: decline * 3 * math.pi / 4,
                            child: Icon(Icons.call_rounded, color: iconColor, size: size * .42),
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

  /// A wave of light travelling up the three chevrons.
  static double _chevron(double phase, int index) {
    final wave = math.sin(2 * math.pi * (phase - index * .18));
    return .25 + .75 * ((wave + 1) / 2);
  }
}
