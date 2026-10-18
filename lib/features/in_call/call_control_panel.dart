import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
    this.endKey,
    this.hideEnd = false,
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

  /// Locates the End pill, where an answered call's Answer ball lands.
  final Key? endKey;

  /// Hides the End pill while the Answer ball is still flying into its place.
  final bool hideEnd;

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
      _noteAt = null;
      _hasNote = false;
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
    // ColorOS 17 keys are wide stadiums, three across.
    final keyHeight = widget.landscape
        ? 44.0
        : compact
        ? 48.0
        : 58.0;
    final actionSize = widget.landscape
        ? 48.0
        : compact
        ? 56.0
        : 76.0;
    final stride =
        keyHeight +
        (widget.landscape
            ? 6
            : compact
            ? 8
            : 12);
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
    final canMerge = widget.callCount > 1 && widget.call.canMerge;
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
      // Merge only matters with two calls; otherwise the slot holds a note, kept on screen.
      if (canMerge)
        (icon: Icons.call_merge_rounded, label: 'Merge', active: false, tap: () => telecom.merge(widget.call.id))
      else
        (icon: Icons.edit_note_rounded, label: 'Note', active: _hasNote, tap: _editNote),
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
                              Expanded(
                                child: Opacity(
                                  opacity: 1 - _outerOut.transform(p),
                                  child: _moreMenu(actionSize, showNote: canMerge),
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
                for (var i = 0; i < 12; i++) _keypadKey(i, p, keyHeight, stride, upperHeight),
            ],
          ),
        ),
      ),
    );
    return CallGlassLayer(
      child: Column(
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
                      child: Column(
                        children: [
                          PressScale(
                            scale: .95,
                            child: LayoutBuilder(
                              builder: (context, box) => Align(
                                alignment: Alignment.topCenter,
                                child: AnimatedOpacity(
                                  key: widget.endKey,
                                  opacity: widget.hideEnd ? 0 : (_ending ? .55 : 1),
                                  duration: widget.hideEnd ? Duration.zero : const Duration(milliseconds: 220),
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
                          const SizedBox(height: 8),
                          const ExcludeSemantics(
                            child: Text('End', style: TextStyle(fontSize: 12, height: 1.1, color: Colors.white)),
                          ),
                        ],
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
      ),
    );
  }

  /// ColorOS keeps the rarer actions behind More, in the package's glass menu that grows out
  /// of the More circle; the label stays put underneath.
  Widget _moreMenu(double size, {required bool showNote}) => CallAction(
    icon: Icons.more_vert_rounded,
    label: 'More',
    size: size,
    onPressed: () {},
    menu: (circle) => GlassMenu(
      menuAlignment: GlassMenuAlignment.bottomRight,
      menuWidth: 210,
      quality: GlassQuality.premium,
      triggerBuilder: (context, toggle) => circle(toggle),
      items: [
        GlassMenuItem(
          icon: const Icon(Icons.add_call, color: Colors.white),
          title: 'Add call',
          onTap: TelecomBridge.instance.openDialer,
        ),
        if (showNote)
          GlassMenuItem(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            title: 'Note',
            onTap: _editNote,
          ),
        GlassMenuItem(
          icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
          title: 'Audio output',
          onTap: () => chooseCallAudioRoute(context, widget.audio),
        ),
      ],
    ),
  );

  // Room above the top row so its edge reveal reaches full opacity.
  static const double _keypadTop = 16;
  static const _innerOut = Interval(0, .32, curve: Curves.easeOut);
  static const _outerOut = Interval(.08, .40, curve: Curves.easeOut);

  /// When this call's note was first opened; the note's identity for Recents.
  DateTime? _noteAt;
  bool _hasNote = false;

  Future<void> _editNote() async {
    final at = _noteAt ??= DateTime.now();
    final hasNote = await editCallNote(context, widget.call.number ?? '', at);
    if (mounted) setState(() => _hasNote = hasNote);
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
    final column = widget.width / 3;
    return Positioned(
      key: ValueKey('morph-key-$digit'),
      left: (index % 3) * column + 6,
      top: top,
      width: column - 12,
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
                child: AnimatedScale(
                  duration: Duration(milliseconds: _tone == digit ? 40 : 220),
                  scale: _tone == digit ? .94 : 1,
                  child: CallGlass(
                    radius: size / 2,
                    pressed: _tone == digit,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(digit, style: const TextStyle(fontSize: 30, height: 1.05, color: Colors.white)),
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
        ),
      ),
    );
  }
}
