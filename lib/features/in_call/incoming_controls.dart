import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_floating_modal.dart';

/// Incoming call: swipe the green circle to answer or the red one to decline (Samsung style),
/// plus "Decline with message".
class IncomingControls extends StatelessWidget {
  const IncomingControls({super.key, required this.call, this.isCurrent});

  final CallInfo call;
  final bool Function()? isCurrent;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canText)
          TextButton.icon(
            onPressed: () => _declineWithMessage(context),
            icon: const Icon(Icons.message_outlined),
            label: const Text('Decline with message'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: const StadiumBorder(),
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwipeCircle(
                      color: OneUITheme.accentGreen,
                      icon: Icons.call_rounded,
                      label: 'Answer',
                      onTriggered: () => telecom.answer(call.id),
                    ),
                    const ExcludeSemantics(
                      child: Text('Answer', style: TextStyle(fontSize: 15, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwipeCircle(
                      color: OneUITheme.accentRed,
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      onTriggered: () => telecom.reject(call.id),
                    ),
                    const ExcludeSemantics(
                      child: Text('Decline', style: TextStyle(fontSize: 15, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Swipe to answer or decline',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 20),
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

class _SwipeCircleState extends State<SwipeCircle> {
  Offset _drag = Offset.zero;
  bool _fired = false;

  void _fire() {
    if (_fired) return;
    _fired = true;
    HapticFeedback.heavyImpact();
    widget.onTriggered();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    onTap: _fire,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _drag = Offset.zero,
      onPanUpdate: (d) {
        final before = _drag.distance >= SwipeCircle.threshold;
        _drag += d.delta;
        if (!before && _drag.distance >= SwipeCircle.threshold) HapticFeedback.selectionClick();
      },
      onPanEnd: (_) {
        if (_drag.distance >= SwipeCircle.threshold) _fire();
        _drag = Offset.zero;
      },
      onPanCancel: () => _drag = Offset.zero,
      child: Listener(
        // A cancelled accepted drag can be reported as a pan end by the recognizer.
        // Clear its distance at the pointer layer before any release handling.
        onPointerCancel: (_) => _drag = Offset.zero,
        child: SizedBox.square(
          dimension: SwipeCircle.size + SwipeCircle.threshold * 0.6,
          child: Center(
            child: Container(
              width: SwipeCircle.size,
              height: SwipeCircle.size,
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
              child: Icon(widget.icon, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    ),
  );
}
