import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../features/in_call/call_controls.dart' show answerGreen;
import '../l10n/l10n.dart';
import '../theme/one_ui_theme.dart';

/// Settings › Swipe to call or message: a row slides right to call (green) or left to message
/// (blue), acting on release past [_threshold] of its width, then springs back; never removed.
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

  late final _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  double _dx = 0, _width = 1;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _back.addListener(() => setState(() => _dx = _from * (1 - Curves.easeOutCubic.transform(_back.value))));
  }

  double _from = 0;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    _back.stop();
    var dx = _dx + d.delta.dx;
    if (widget.onCall == null) dx = dx.clamp(-_width, 0);
    if (widget.onMessage == null) dx = dx.clamp(0, _width);
    final armed = dx.abs() >= _width * _threshold;
    if (armed && !_armed) Haptics.tap();
    setState(() {
      _dx = dx;
      _armed = armed;
    });
  }

  void _end(DragEndDetails _) {
    if (_armed) (_dx > 0 ? widget.onCall : widget.onMessage)?.call();
    _armed = false;
    _from = _dx;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final right = _dx > 0;
    final color = right ? answerGreen : _blue;
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: _update,
          onHorizontalDragEnd: _end,
          child: Stack(
            children: [
              if (_dx != 0)
                Positioned.fill(
                  child: ColoredBox(
                    color: color.withValues(alpha: _armed ? 1 : 0.55),
                    child: Align(
                      alignment: right ? Alignment.centerLeft : Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Icon(
                          right ? Icons.call_rounded : Icons.message_rounded,
                          color: Colors.white,
                          semanticLabel: right ? context.l10n.call : context.l10n.message,
                        ),
                      ),
                    ),
                  ),
                ),
              // Opaque, so the colour shows only where the row has moved away.
              Transform.translate(
                offset: Offset(_dx, 0),
                child: ColoredBox(color: context.palette.page, child: widget.child),
              ),
            ],
          ),
        );
      },
    );
  }
}
