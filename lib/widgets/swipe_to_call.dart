import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/telecom/telecom_bridge.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_toast.dart';
import 'place_call.dart';

/// A deliberate horizontal swipe, released past half the row, calls or messages.
class SwipeToCallOrMessage extends StatefulWidget {
  const SwipeToCallOrMessage({
    super.key,
    required this.number,
    required this.child,
    this.simId,
    this.enabled = true,
    this.color = OneUITheme.surfaceCard,
  });
  final String number;
  final String? simId;
  final Widget child;
  final bool enabled;
  final Color color;

  @override
  State<SwipeToCallOrMessage> createState() => _SwipeToCallOrMessageState();
}

class _SwipeToCallOrMessageState extends State<SwipeToCallOrMessage> {
  double _offset = 0;
  bool _dragging = false;
  bool _busy = false;

  @override
  void didUpdateWidget(SwipeToCallOrMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || widget.number != oldWidget.number) {
      _offset = 0;
      _dragging = false;
    }
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _offset = 0;
      _dragging = false;
    });
  }

  Future<void> _release(_IntentDrag drag, double width) async {
    final distance = drag.travel.dx;
    final act = widget.enabled && !_busy && drag.deliberate && distance.abs() >= width * .5;
    _reset();
    if (!act) return;
    _busy = true;
    try {
      HapticFeedback.mediumImpact();
      if (distance > 0) {
        await placeCall(context, widget.number, simId: widget.simId);
      } else {
        await TelecomBridge.instance.sendSms(widget.number);
      }
    } on PlatformException {
      if (mounted) OneUIToast.show(context, "Couldn't open this action");
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      return RawGestureDetector(
        gestures: {
          if (widget.enabled)
            _IntentDrag: GestureRecognizerFactoryWithHandlers<_IntentDrag>(_IntentDrag.new, (drag) {
              drag
                ..onStart = (_) {
                  setState(() => _dragging = true);
                }
                ..onUpdate = (_) {
                  setState(() => _offset = drag.deliberate ? drag.travel.dx.clamp(-box.maxWidth, box.maxWidth) : 0);
                }
                ..onCancel = _reset
                ..onEnd = (_) => _release(drag, box.maxWidth);
            }),
        },
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: _offset >= 0 ? OneUITheme.accentGreen : OneUITheme.accentBlue,
                  child: Align(
                    alignment: _offset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Icon(
                        _offset >= 0 ? Icons.call_rounded : Icons.message_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: _dragging || MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(_offset, 0, 0),
                child: ColoredBox(color: widget.color, child: widget.child),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Reject diagonal intent before claiming the arena, leaving scrolling free to win.
/// Once horizontal motion wins, a turn toward vertical cancels the action too.
class _IntentDrag extends HorizontalDragGestureRecognizer {
  Offset travel = Offset.zero;
  bool deliberate = true;
  int? _pointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null) {
      deliberate = false;
      return;
    }
    _pointer = event.pointer;
    travel = Offset.zero;
    deliberate = true;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer == _pointer && event is PointerMoveEvent) {
      travel += event.delta;
      if (travel.distance > kTouchSlop && travel.dx.abs() < travel.dy.abs() * 2) {
        deliberate = false;
        resolve(GestureDisposition.rejected);
        return;
      }
    }
    if (event is PointerCancelEvent) deliberate = false;
    super.handleEvent(event);
    if (event.pointer == _pointer && (event is PointerUpEvent || event is PointerCancelEvent)) _pointer = null;
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    super.didStopTrackingLastPointer(pointer);
    _pointer = null;
  }
}
