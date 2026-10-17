import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import 'call_controls.dart';

/// Actions recede while the keypad rises within one reversible animated panel.
/// The bottom row is outside the changing panel, so it never moves.
class CallControlPanel extends StatefulWidget {
  const CallControlPanel({
    super.key,
    required this.call,
    required this.audio,
    required this.callCount,
    required this.progress,
    required this.animating,
    required this.keypadOpen,
    required this.width,
    required this.compact,
    required this.landscape,
    required this.digits,
    required this.onDigit,
    required this.onToggle,
  });
  final CallInfo call;
  final AudioInfo audio;
  final int callCount;
  final double progress;
  final bool animating;
  final bool keypadOpen;
  final double width;
  final bool compact;
  final bool landscape;
  final String digits;
  final ValueChanged<String> onDigit;
  final VoidCallback onToggle;

  @override
  State<CallControlPanel> createState() => _CallControlPanelState();
}

class _CallControlPanelState extends State<CallControlPanel> {
  String? _tone;
  static const _keys = [
    ('1', ''),
    ('2', 'ABC'),
    ('3', 'DEF'),
    ('4', 'GHI'),
    ('5', 'JKL'),
    ('6', 'MNO'),
    ('7', 'PQRS'),
    ('8', 'TUV'),
    ('9', 'WXYZ'),
    ('*', ''),
    ('0', '+'),
    ('#', ''),
  ];

  void _stopTone() {
    if (_tone == null) return;
    _tone = null;
    TelecomBridge.instance.stopDtmf(widget.call.id);
  }

  void _startTone(String digit) {
    _stopTone();
    setState(() => _tone = digit);
    HapticFeedback.lightImpact();
    widget.onDigit(digit);
    TelecomBridge.instance.playDtmf(widget.call.id, digit);
  }

  void _releaseTone() {
    _stopTone();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CallControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.id != widget.call.id) {
      if (_tone != null) TelecomBridge.instance.stopDtmf(oldWidget.call.id);
      _tone = null;
    } else if (!widget.keypadOpen || widget.animating) {
      _stopTone();
    }
  }

  @override
  void dispose() {
    _stopTone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telecom = TelecomBridge.instance;
    final p = widget.progress;
    final compact = widget.compact;
    final circle = widget.landscape
        ? 48.0
        : compact
        ? 64.0
        : 80.0;
    final actionSize = widget.landscape
        ? 48.0
        : compact
        ? 56.0
        : 76.0;
    final stride =
        circle +
        (widget.landscape
            ? 4
            : compact
            ? 6
            : 8);
    final upperHeight = lerpDouble(
      widget.landscape
          ? 96
          : compact
          ? 112
          : 128,
      32 + stride * 4 - (widget.landscape ? 4 : 0),
      p,
    )!;
    final holding = widget.call.state == CallState.holding;
    final actions = <({IconData icon, String label, bool active, VoidCallback? tap})>[
      (
        icon: widget.audio.muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
        label: 'Mute',
        active: widget.audio.muted,
        tap: () => telecom.setMuted(!widget.audio.muted),
      ),
      (
        icon: Icons.pause_rounded,
        label: holding ? 'Resume' : 'Hold',
        active: holding,
        tap: widget.call.canHold || holding
            ? () => holding ? telecom.unhold(widget.call.id) : telecom.hold(widget.call.id)
            : null,
      ),
      (icon: Icons.add_call, label: 'Add call', active: false, tap: telecom.openDialer),
      (
        icon: Icons.call_merge_rounded,
        label: 'Merge',
        active: false,
        tap: widget.callCount > 1 && widget.call.canMerge ? () => telecom.merge(widget.call.id) : null,
      ),
    ];
    final route = widget.audio.route;
    final routeLabel = switch (route) {
      AudioRoute.bluetooth => 'Bluetooth',
      AudioRoute.wiredHeadset => 'Headset',
      _ => 'Speaker',
    };
    final upper = IgnorePointer(
      ignoring: widget.animating,
      child: ExcludeSemantics(
        excluding: widget.animating,
        child: SizedBox(
          key: const ValueKey('call-upper-panel'),
          height: upperHeight,
          width: widget.width,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (p > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 28,
                  child: Opacity(
                    opacity: Curves.easeInOut.transform(p),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.digits,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, letterSpacing: 3, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (p < 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: widget.landscape
                      ? 96
                      : compact
                      ? 112
                      : 128,
                  child: IgnorePointer(
                    ignoring: p > 0,
                    child: ExcludeSemantics(
                      excluding: p > 0,
                      child: Opacity(
                        opacity: 1 - const Interval(0, .7, curve: Curves.easeOut).transform(p),
                        child: Transform.scale(
                          key: const ValueKey('receding-call-actions'),
                          scale: 1 - .12 * Curves.easeOutBack.transform(p),
                          alignment: Alignment.topCenter,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final action in actions)
                                Expanded(
                                  child: CallAction(
                                    icon: action.icon,
                                    label: action.label,
                                    active: action.active,
                                    onPressed: action.tap,
                                    size: actionSize,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (p > 0)
                for (var i = 0; i < 12; i++) _keypadKey(i, p, circle, stride, upperHeight),
            ],
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.landscape) Expanded(child: SingleChildScrollView(reverse: true, child: upper)) else upper,
        Padding(
          padding: EdgeInsets.only(
            top: compact ? 8 : 20,
            bottom: widget.landscape
                ? 8
                : compact
                ? 16
                : 56,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: compact ? 72 : 92,
                child: CallAction(
                  icon: switch (route) {
                    AudioRoute.bluetooth => Icons.bluetooth_audio_rounded,
                    AudioRoute.wiredHeadset => Icons.headset_rounded,
                    _ => Icons.volume_up_rounded,
                  },
                  label: routeLabel,
                  active: route != AudioRoute.earpiece,
                  size: actionSize,
                  onPressed: widget.audio.supportedRoutes.contains(AudioRoute.bluetooth)
                      ? () => chooseCallAudioRoute(context, widget.audio)
                      : () => telecom.setAudioRoute(
                          route == AudioRoute.speaker ? AudioRoute.earpiece : AudioRoute.speaker,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: actionSize,
                    child: IconButton.filled(
                      tooltip: 'End call',
                      iconSize: 32,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEE5265),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        telecom.hangUp(widget.call.id);
                      },
                      icon: const Icon(Icons.call_end_rounded),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: compact ? 72 : 92,
                child: CallAction(
                  icon: widget.keypadOpen ? Icons.keyboard_arrow_down_rounded : Icons.dialpad_rounded,
                  label: widget.keypadOpen ? 'Hide keypad' : 'Keypad',
                  size: actionSize,
                  onPressed: widget.onToggle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keypadKey(int index, double p, double size, double stride, double upperHeight) {
    final (digit, letters) = _keys[index];
    // Overshoot only the painted key, keeping layout and the bottom row stable.
    final spring = Curves.easeOutBack.transform(p);
    final fullHeight = 32 + stride * 4 - (widget.landscape ? 4 : 0);
    final top = upperHeight - fullHeight + 32 + index ~/ 3 * stride + (1 - p) * 24;
    // Reveal whole circles as space opens, avoiding a sliced circle at either edge.
    final edgeReveal = (top / 16).clamp(0.0, 1.0) * ((upperHeight - top - size) / 4).clamp(0.0, 1.0);
    return Positioned(
      key: ValueKey('morph-key-$digit'),
      left: (index % 3 + .5) * widget.width / 3 - size / 2,
      top: top,
      width: size,
      height: size,
      child: Opacity(
        opacity: Curves.easeInOut.transform(p) * edgeReveal,
        child: Transform.scale(
          key: ValueKey('keypad-spring-$digit'),
          scale: .92 + .08 * spring,
          child: ExcludeSemantics(
            excluding: p < 1,
            child: Semantics(
              button: true,
              label: digit,
              excludeSemantics: true,
              onTap: () {
                _startTone(digit);
                _releaseTone();
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _startTone(digit),
                onTapUp: (_) => _releaseTone(),
                onTapCancel: _releaseTone,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _tone == digit ? const Color(0xFF617A80) : callControlFill,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(digit, style: const TextStyle(fontSize: 30, height: 1.05, color: Colors.white)),
                        Text(
                          letters.isEmpty ? ' ' : letters,
                          style: const TextStyle(fontSize: 9, height: 1.2, letterSpacing: 1, color: Colors.white70),
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
    );
  }
}
