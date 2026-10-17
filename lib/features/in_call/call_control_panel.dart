import 'dart:async';
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
    required this.onDigit,
    required this.onToggle,
    this.entrance = kAlwaysCompleteAnimation,
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
  final ValueChanged<String> onDigit;
  final VoidCallback onToggle;

  /// Runs once when the controls first appear: rows fade and rise in, staggered.
  final Animation<double> entrance;

  @override
  State<CallControlPanel> createState() => _CallControlPanelState();
}

class _CallControlPanelState extends State<CallControlPanel> {
  String? _tone;
  bool _ending = false;
  Timer? _endingTimeout;

  void _endCall() {
    HapticFeedback.mediumImpact();
    setState(() => _ending = true);
    TelecomBridge.instance.hangUp(widget.call.id);
    // If Telecom doesn't end the call, give the button back rather than leave it dead.
    _endingTimeout?.cancel();
    _endingTimeout = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _ending = false);
    });
  }

  /// A soft settle for keys: a little overshoot, much gentler than easeOutBack.
  static const _settle = Cubic(.34, 1.3, .64, 1);
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
      _ending = false;
      _endingTimeout?.cancel();
    } else if (!widget.keypadOpen || widget.animating) {
      _stopTone();
    }
  }

  @override
  void dispose() {
    _stopTone();
    _endingTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telecom = TelecomBridge.instance;
    final p = widget.progress;
    Widget rise(Interval interval, Widget child) => AnimatedBuilder(
      animation: widget.entrance,
      child: child,
      builder: (context, child) {
        final t = interval.transform(widget.entrance.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
        );
      },
    );
    final layoutProgress = const Interval(0, .65, curve: Curves.easeOutCubic).transform(p);
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
      _keypadTop + stride * 4 - (widget.landscape ? 4 : 0),
      layoutProgress,
    )!;
    final holding = widget.call.state == CallState.holding;
    final number = widget.call.number ?? '';
    final canMessage = !widget.call.isPrivate && !widget.call.isConference && number.isNotEmpty;
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
      // Merge only matters with two calls; otherwise the slot offers a message to the caller.
      if ((widget.callCount > 1 && widget.call.canMerge) || !canMessage)
        (
          icon: Icons.call_merge_rounded,
          label: 'Merge',
          active: false,
          tap: widget.callCount > 1 && widget.call.canMerge ? () => telecom.merge(widget.call.id) : null,
        )
      else
        (icon: Icons.chat_bubble_outline_rounded, label: 'Message', active: false, tap: () => _message(number)),
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
                      child: rise(
                        const Interval(0, .62, curve: Curves.easeOutCubic),
                        Transform.scale(
                          key: const ValueKey('receding-call-actions'),
                          scale: 1 - .10 * const Interval(0, .45, curve: Curves.easeOut).transform(p),
                          alignment: Alignment.topCenter,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (i, action) in actions.indexed)
                                Expanded(
                                  // The middle pair leaves first, then the outer pair.
                                  child: Opacity(
                                    opacity: 1 - (i == 1 || i == 2 ? _innerOut : _outerOut).transform(p),
                                    child: CallAction(
                                      icon: action.icon,
                                      label: action.label,
                                      active: action.active,
                                      onPressed: action.tap,
                                      size: actionSize,
                                    ),
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
            // With the keypad open, the gap matches the key rows' (landscape drops the last row's own gap).
            top: lerpDouble(compact ? 8 : 20, widget.landscape ? 4 : 0, layoutProgress)!,
            bottom: widget.landscape
                ? 8
                : compact
                ? 16
                : 56,
          ),
          child: rise(
            const Interval(.12, .74, curve: Curves.easeOutCubic),
            Row(
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
                    child: PressScale(
                      scale: .95,
                      child: LayoutBuilder(
                        builder: (context, box) => Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedOpacity(
                            opacity: _ending ? .55 : 1,
                            duration: const Duration(milliseconds: 220),
                            child: AnimatedContainer(
                              // While ending, the pill draws in to a circle.
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 280),
                              curve: Curves.easeInOutCubic,
                              width: _ending ? actionSize : box.maxWidth,
                              height: actionSize,
                              decoration: ShapeDecoration(
                                shape: const StadiumBorder(),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFF26573), Color(0xFFE0465A)],
                                ),
                                shadows: [
                                  BoxShadow(
                                    color: const Color(0xFFE0465A).withValues(alpha: _ending ? 0 : .38),
                                    blurRadius: 22,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                tooltip: 'End call',
                                iconSize: 32,
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: _ending ? null : _endCall,
                                icon: const Icon(Icons.call_end_rounded),
                              ),
                            ),
                          ),
                        ),
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
        ),
      ],
    );
  }

  // Room above the top row so its edge reveal reaches full opacity.
  static const double _keypadTop = 16;
  static const _innerOut = Interval(0, .32, curve: Curves.easeOut);
  static const _outerOut = Interval(.08, .40, curve: Curves.easeOut);

  Future<void> _message(String number) async {
    try {
      await TelecomBridge.instance.sendSms(number);
    } on PlatformException {
      // No SMS app: nothing to open.
    }
  }

  Widget _keypadKey(int index, double p, double size, double stride, double upperHeight) {
    final (digit, letters) = _keys[index];
    // The panel opens from the bottom, so rows cascade bottom-up with it; motion is paint-only.
    final row = index ~/ 3;
    final q = Interval((3 - row) * .08, (3 - row) * .08 + .76).transform(p);
    final spring = _settle.transform(q);
    final fullHeight = _keypadTop + stride * 4 - (widget.landscape ? 4 : 0);
    final top = upperHeight - fullHeight + _keypadTop + row * stride + (1 - spring) * 24;
    // Reveal whole circles as space opens, avoiding a sliced circle at either edge.
    final edgeReveal = (top / 16).clamp(0.0, 1.0) * ((upperHeight - top - size) / 4).clamp(0.0, 1.0);
    return Positioned(
      key: ValueKey('morph-key-$digit'),
      left: (index % 3 + .5) * widget.width / 3 - size / 2,
      top: top,
      width: size,
      height: size,
      child: Opacity(
        opacity: const Interval(0, .6, curve: Curves.easeOut).transform(q) * edgeReveal,
        child: Transform.scale(
          key: ValueKey('keypad-spring-$digit'),
          scale: .85 + .15 * spring,
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
                child: AnimatedContainer(
                  duration: Duration(milliseconds: _tone == digit ? 40 : 220),
                  width: size,
                  height: size,
                  transformAlignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(_tone == digit ? .94 : 1, _tone == digit ? .94 : 1, 1),
                  decoration: callControlBody(pressed: _tone == digit),
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(digit, style: const TextStyle(fontSize: 32, height: 1.05, color: Colors.white)),
                        Text(
                          letters.isEmpty ? ' ' : letters,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                          ),
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
