import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';

/// Incoming call: swipe the green circle to answer or the red one to decline (Samsung style),
/// plus "Decline with message".
class IncomingControls extends StatelessWidget {
  const IncomingControls({super.key, required this.call});

  final CallInfo call;

  Future<void> _declineWithMessage(BuildContext context) async {
    // Edited in Settings › Quick decline messages.
    final quickReplies = await TelecomBridge.instance.getQuickReplies();
    if (!context.mounted) return;
    final message = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: OneUITheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(OneUITheme.radiusCard)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Decline with message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final m in quickReplies)
              ListTile(title: Text(m), onTap: () => Navigator.of(context).pop(m)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (message != null) await TelecomBridge.instance.rejectWithMessage(call.id, message);
  }

  @override
  Widget build(BuildContext context) {
    final telecom = TelecomBridge.instance;
    final canText = !call.isPrivate && (call.number?.isNotEmpty ?? false);
    return Column(
      children: [
        if (canText)
          TextButton.icon(
            onPressed: () => _declineWithMessage(context),
            icon: const Icon(Icons.message_outlined),
            label: const Text('Decline with message'),
            style: TextButton.styleFrom(foregroundColor: OneUITheme.textSecondary),
          ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SwipeCircle(
                color: OneUITheme.accentGreen,
                icon: Icons.call_rounded,
                label: 'Answer',
                onTriggered: () => telecom.answer(call.id),
              ),
              SwipeCircle(
                color: OneUITheme.accentRed,
                icon: Icons.call_end_rounded,
                label: 'Decline',
                onTriggered: () => telecom.reject(call.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Swipe to answer or decline', style: TextStyle(fontSize: 13, color: OneUITheme.textTertiary)),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// A call button that triggers when released at least [threshold] away from its start, in
/// any direction; released closer (or slid back), it springs back and nothing happens.
/// Pocket taps don't answer calls; screen readers can still activate it.
class SwipeCircle extends StatefulWidget {
  const SwipeCircle({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTriggered,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTriggered;

  static const double size = 72;
  static const double threshold = 96;

  @override
  State<SwipeCircle> createState() => _SwipeCircleState();
}

class _SwipeCircleState extends State<SwipeCircle> with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  bool _fired = false;
  late final AnimationController _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
    ..addListener(() => setState(() => _drag = _from * (1 - Curves.easeOut.transform(_back.value))));
  Offset _from = Offset.zero;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _fire() {
    if (_fired) return;
    _fired = true;
    HapticFeedback.heavyImpact();
    widget.onTriggered();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_drag.distance / SwipeCircle.threshold).clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label: widget.label,
      onTap: _fire,
      excludeSemantics: true,
      child: GestureDetector(
        onPanStart: (_) => _back.stop(),
        onPanUpdate: (d) {
          final before = _drag.distance >= SwipeCircle.threshold;
          setState(() => _drag += d.delta);
          // A tick when crossing the line, so you can feel it's armed before letting go.
          if (!before && _drag.distance >= SwipeCircle.threshold) HapticFeedback.selectionClick();
        },
        onPanEnd: (_) {
          if (_drag.distance >= SwipeCircle.threshold) _fire();
          _from = _drag;
          _back.forward(from: 0);
        },
        onPanCancel: () {
          _from = _drag;
          _back.forward(from: 0);
        },
        child: SizedBox.square(
          dimension: SwipeCircle.size + SwipeCircle.threshold * 0.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo that grows with the drag, so the gesture reads as "pull this".
              Container(
                width: SwipeCircle.size + 40 * progress + 16,
                height: SwipeCircle.size + 40 * progress + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.15 + 0.2 * progress),
                ),
              ),
              Transform.translate(
                offset: _drag,
                child: Container(
                  width: SwipeCircle.size,
                  height: SwipeCircle.size,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  child: Icon(widget.icon, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
