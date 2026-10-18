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
        // ColorOS shows the slashed mic either way; muted fills the circle white.
        icon: Icons.mic_off_rounded,
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
      (icon: Icons.add_call, label: 'Add call', active: false, tap: telecom.openDialer),
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
                        KeyedSubtree(
                          key: const ValueKey('receding-call-actions'),
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
                for (var i = 0; i < 12; i++) _keypadKey(i, p, keyHeight, stride, upperHeight),
            ],
          ),
        ),
      ),
    );
    // Every control's frost shares one backdrop read.
    return BackdropGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.landscape) Expanded(child: SingleChildScrollView(reverse: true, child: upper)) else upper,
          Padding(
            padding: EdgeInsets.only(
              // With the keypad open, the gap matches the key rows' (landscape drops the last row's own gap).
              top: lerpDouble(compact ? 2 : 6, widget.landscape ? 4 : 0, layoutProgress)!,
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
                          LayoutBuilder(
                            builder: (context, box) => Align(
                              alignment: Alignment.topCenter,
                              // Solid red, but with the glass package's press: glow and stretch, no glass body.
                              child: GlassButton.custom(
                                style: GlassButtonStyle.transparent,
                                onTap: _noTap,
                                excludeFromSemantics: true,
                                canRequestFocus: false,
                                shape: LiquidRoundedRectangle(borderRadius: actionSize / 2),
                                child: AnimatedOpacity(
                                  key: widget.endKey,
                                  opacity: widget.hideEnd ? 0 : (_ending ? .55 : 1),
                                  // Only ending dims gradually; the pill appears at once when the Answer ball lands on it.
                                  duration: _ending ? const Duration(milliseconds: 220) : Duration.zero,
                                  child: AnimatedContainer(
                                    // While ending, the pill draws in to a circle.
                                    duration: MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 280),
                                    curve: Curves.easeInOutCubic,
                                    width: _ending ? actionSize : box.maxWidth,
                                    height: actionSize,
                                    // A gloss across the top half, as on ColorOS.
                                    foregroundDecoration: ShapeDecoration(
                                      shape: RoundedSuperellipseBorder(
                                        borderRadius: BorderRadius.circular(actionSize / 2),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0x40FFFFFF), Color(0x0AFFFFFF), Color(0x00FFFFFF)],
                                        stops: [0, .45, .55],
                                      ),
                                    ),
                                    decoration: ShapeDecoration(
                                      // ColorOS 17's tomato red, with a glossy rim.
                                      // Squircle ends, like the keys.
                                      shape: RoundedSuperellipseBorder(
                                        borderRadius: BorderRadius.circular(actionSize / 2),
                                        side: const BorderSide(color: Color(0x40FFFFFF), width: .8),
                                      ),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFFE5604F), Color(0xFFC93D31)],
                                      ),
                                      shadows: [
                                        BoxShadow(
                                          color: const Color(0xFFC93D31).withValues(alpha: _ending ? 0 : .3),
                                          blurRadius: 22,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      tooltip: 'End call',
                                      iconSize: 38,
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
                          const SizedBox(height: 6),
                          const ExcludeSemantics(
                            child: Text('End', style: TextStyle(fontSize: 12, height: 1.1, color: Color(0xC7FFFFFF))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: compact ? 72 : 92,
                    child: CallAction(
                      // As on ColorOS: same button either way, lit white while the keypad is open.
                      icon: Icons.dialpad_rounded,
                      glyph: (color) => DialPadGlyph(color: color),
                      label: 'Dial pad',
                      active: widget.keypadOpen,
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

  /// The End pill's taps belong to its IconButton; the glass button only animates the press.
  static void _noTap() {}

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
    // Keys fade in as the panel opens from the bottom, rows a beat apart bottom-up; paint-only.
    final row = index ~/ 3;
    final q = Interval(.2 + (3 - row) * .06, .8 + (3 - row) * .06, curve: Curves.easeOut).transform(p);
    final fullHeight = _keypadTop + stride * 4 - (widget.landscape ? 4 : 0);
    final top = upperHeight - fullHeight + _keypadTop + row * stride;
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
        key: ValueKey('keypad-fade-$digit'),
        opacity: q * edgeReveal,
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
            child: CallBody(
              radius: size / 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _startTone(digit),
                onTapUp: (_) => _releaseTone(),
                onTapCancel: _releaseTone,
                child: SizedBox.expand(
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
    );
  }
}
