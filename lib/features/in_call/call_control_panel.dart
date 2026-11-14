import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_menu.dart';
import 'call_controls.dart';
import '../../l10n/l10n.dart';
import '../../widgets/call_glyph.dart';
import '../../widgets/call_icons.dart';

/// Actions recede while the keypad rises within one reversible animated panel.
/// The bottom row is outside the changing panel, so it never moves.
class CallControlPanel extends StatefulWidget {
  const CallControlPanel({
    super.key,
    required this.call,
    required this.audio,
    this.recorder,
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

  /// The companion recorder; null without it, and then More has no Record.
  final RecorderInfo? recorder;
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

class _CallControlPanelState extends State<CallControlPanel> with TickerProviderStateMixin {
  /// The keys' and actions' own steady clock (0 closed, 1 open), so they play out evenly rather
  /// than riding the panel's spring, which does most of its travel at the start.
  late final AnimationController _keysIn;

  /// Which script the clock is playing: opening and closing move differently (ColorOS 17), so
  /// each has its own, picked when it starts from rest. One interrupted mid-way is simply rewound.
  bool _closing = false;

  static const _scriptMs = 450.0;

  /// Milliseconds into the script being played.
  double get _ms => (_closing ? 1 - _keysIn.value : _keysIn.value) * _scriptMs;

  @override
  void initState() {
    super.initState();
    // Created here, not lazily: a lazy field would first be read after the keypad opened.
    _keysIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: widget.keypadOpen ? 1 : 0,
    );
    TelecomBridge.instance.canMeetCall().then((can) {
      if (mounted && can) setState(() => _canMeet = true);
    }, onError: (Object _) {});
  }

  /// Whether Google Meet is installed to take the Video call.
  bool _canMeet = false;
  final _moreKey = GlobalKey();
  final _routeKey = GlobalKey();

  void _openMore(bool merging) {
    final call = widget.call;
    final number = call.number ?? '';
    final canVideo = _canMeet && !call.isPrivate && !call.isConference && number.isNotEmpty;
    final holding = call.state == CallState.holding;
    final telecom = TelecomBridge.instance;
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _moreKey,
      scale: 1.15,
      width: 290,
      items: [
        // Without the recorder, Hold sits in the row where Record would be.
        if (widget.recorder != null)
          OneUIFloatingMenuItem(
            label: holding ? context.l10n.resume : context.l10n.hold,
            glyph: CallIconShape.hold,
            enabled: call.canHold || holding,
            onTap: () => holding ? telecom.unhold(call.id) : telecom.hold(call.id),
          ),
        if (merging)
          OneUIFloatingMenuItem(
            label: context.l10n.merge,
            icon: Icons.call_merge_rounded,
            onTap: () => telecom.merge(call.id),
          )
        else
          OneUIFloatingMenuItem(label: context.l10n.addCall, glyph: CallIconShape.addCall, onTap: telecom.openDialer),
        OneUIFloatingMenuItem(
          label: context.l10n.switchToVideoCall,
          glyph: CallIconShape.video,
          enabled: canVideo,
          onTap: () => telecom.meetCall(number),
        ),
      ],
    );
  }

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _keysIn.value = widget.keypadOpen ? 1 : 0;
    }
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
    if (oldWidget.keypadOpen != widget.keypadOpen || oldWidget.call.id != widget.call.id) {
      if (MediaQuery.disableAnimationsOf(context) || oldWidget.call.id != widget.call.id) {
        _keysIn.value = widget.keypadOpen ? 1 : 0;
      } else {
        if (!_keysIn.isAnimating) _closing = !widget.keypadOpen;
        widget.keypadOpen ? _keysIn.forward() : _keysIn.reverse();
      }
    }
  }

  @override
  void dispose() {
    _keysIn.dispose();
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
          ? 104
          : 120,
      _keypadTop + stride * 4 - (widget.landscape ? 4 : 0),
      layoutProgress,
    )!;
    final holding = widget.call.state == CallState.holding;
    final canMerge = widget.callCount > 1 && widget.call.canMerge;
    final recorder = widget.recorder;
    // ColorOS 17's glyphs fill about half the circle (measured off screenshots), more than IconButton's default.
    const glyphShare = .65;
    final actions = <({CallIconShape glyph, String label, bool active, VoidCallback? tap, Key? key})>[
      (
        // ColorOS shows the slashed mic either way; muted lights the circle.
        glyph: CallIconShape.mute,
        label: context.l10n.mute,
        active: widget.audio.muted,
        tap: () => telecom.setMuted(!widget.audio.muted),
        key: null,
      ),
      if (recorder != null)
        (
          glyph: CallIconShape.record,
          label: recorder.recording ? context.l10n.stopRecording : context.l10n.record,
          active: recorder.recording,
          tap: recorder.recording || (recorder.ready && widget.call.state == CallState.active)
              ? telecom.toggleRecording
              : null,
          key: null,
        )
      else
        (
          glyph: CallIconShape.hold,
          label: holding ? context.l10n.resume : context.l10n.hold,
          active: holding,
          tap: widget.call.canHold || holding
              ? () => holding ? telecom.unhold(widget.call.id) : telecom.hold(widget.call.id)
              : null,
          key: null,
        ),
      (glyph: CallIconShape.notes, label: context.l10n.notes, active: _hasNote, tap: _editNote, key: null),
      (
        glyph: CallIconShape.more,
        label: context.l10n.more,
        active: false,
        tap: () => _openMore(canMerge),
        key: _moreKey,
      ),
    ];
    final route = widget.audio.route;
    final routeGlyph = switch (route) {
      AudioRoute.bluetooth => CallIconShape.bluetooth,
      AudioRoute.wiredHeadset => CallIconShape.headset,
      _ => CallIconShape.speaker,
    };
    final routeLabel = switch (route) {
      AudioRoute.bluetooth => widget.audio.activeBluetoothLabel,
      AudioRoute.wiredHeadset => context.l10n.headset,
      _ => context.l10n.speaker,
    };
    final upper = IgnorePointer(
      ignoring: widget.animating || (!widget.keypadOpen && p > 0),
      child: ExcludeSemantics(
        excluding: widget.animating || (!widget.keypadOpen && p > 0),
        child: SizedBox(
          key: const ValueKey('call-upper-panel'),
          height: upperHeight,
          width: widget.width,
          child: Stack(
            // The keys follow their own script, not the panel's growing edge (landscape scrolls, and clips).
            clipBehavior: widget.landscape ? Clip.hardEdge : Clip.none,
            children: [
              if (p < 1 || !widget.keypadOpen)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: widget.landscape
                      ? 96
                      : compact
                      ? 104
                      : 120,
                  child: IgnorePointer(
                    ignoring: p > 0,
                    child: ExcludeSemantics(
                      excluding: p > 0,
                      child: rise(
                        const Interval(0, .62, curve: Curves.easeOutCubic),
                        AnimatedBuilder(
                          animation: _keysIn,
                          builder: (context, child) => Opacity(opacity: _actionsScript.$2, child: child),
                          key: const ValueKey('receding-call-actions'),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final action in actions)
                                Expanded(
                                  // Each button shrinks toward a point just under its circle.
                                  child: AnimatedBuilder(
                                    animation: _keysIn,
                                    builder: (context, child) => Transform.scale(
                                      scale: _actionsScript.$1,
                                      alignment: const Alignment(0, -.1),
                                      child: child,
                                    ),
                                    child: CallAction(
                                      icon: Icons.circle,
                                      glyph: (color) => CallIcon(
                                        action.glyph,
                                        key: ValueKey(action.glyph),
                                        color: color,
                                        size: actionSize * glyphShare,
                                      ),
                                      label: action.label,
                                      active: action.active,
                                      onPressed: action.tap,
                                      size: actionSize,
                                      circleKey: action.key,
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
    // ColorOS 17: the End pill is a little smaller than the row it sits in, 90% of the circles' height
    // and 87.5% of the space between them (measured off a recording).
    final endHeight = actionSize * .9;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.landscape) Expanded(child: SingleChildScrollView(reverse: true, child: upper)) else upper,
        Padding(
          padding: EdgeInsets.only(
            // With the keypad open, a little more than a key-row gap separates the keys from the bottom
            // row (landscape drops the last row's own gap).
            top: lerpDouble(
              compact ? 0 : 2,
              widget.landscape
                  ? 4
                  : compact
                  ? 6
                  : 10,
              layoutProgress,
            )!,
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
                    icon: audioRouteIcon(route == AudioRoute.earpiece ? AudioRoute.speaker : route),
                    glyph: (color) =>
                        CallIcon(routeGlyph, key: ValueKey(routeGlyph), color: color, size: actionSize * glyphShare),
                    label: routeLabel,
                    active: route != AudioRoute.earpiece,
                    size: actionSize,
                    circleKey: _routeKey,
                    onPressed: widget.audio.supportedRoutes.contains(AudioRoute.bluetooth)
                        ? () => chooseCallAudioRoute(context, widget.audio, _routeKey)
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
                          builder: (context, box) => SizedBox(
                            height: actionSize,
                            child: Center(
                              child: AnimatedOpacity(
                                key: widget.endKey,
                                opacity: widget.hideEnd ? 0 : (_ending ? .55 : 1),
                                // Only ending dims gradually; the pill appears at once when the Answer ball lands on it.
                                duration: _ending ? const Duration(milliseconds: 220) : Duration.zero,
                                // The red glow sits outside the press below, whose clip would cut it off.
                                child: AnimatedContainer(
                                  duration: MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 280),
                                  curve: Curves.easeInOutCubic,
                                  decoration: ShapeDecoration(
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(endHeight / 2),
                                    ),
                                    shadows: solidBody(
                                      endRed,
                                      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(endHeight / 2)),
                                      // ColorOS 17's End casts only a faint glow.
                                      glow: _ending ? 0 : .15,
                                      flat: callFlat(context),
                                    ).shadows,
                                  ),
                                  // Solid red, but with the glass package's press: glow and stretch, no glass body.
                                  child: GlassButton.custom(
                                    style: GlassButtonStyle.transparent,
                                    onTap: _noTap,
                                    excludeFromSemantics: true,
                                    canRequestFocus: false,
                                    // Below full call screen effects: no glass lighting on press.
                                    glowColor: callFlat(context) ? Colors.transparent : null,
                                    ambientBaseLight: callFlat(context) ? 0 : null,
                                    shape: LiquidRoundedRectangle(borderRadius: endHeight / 2),
                                    child: AnimatedContainer(
                                      // While ending, the pill draws in to a circle.
                                      duration: MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 280),
                                      curve: Curves.easeInOutCubic,
                                      width: _ending ? endHeight : box.maxWidth * .875,
                                      height: endHeight,
                                      // ColorOS 17's solid tomato red, with squircle ends like the keys.
                                      decoration: endPillBody(
                                        RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(endHeight / 2)),
                                        flat: callFlat(context),
                                      ),
                                      child: Semantics(
                                        label: context.l10n.endCall,
                                        child: IconButton(
                                          iconSize: 46,
                                          style: IconButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            disabledForegroundColor: Colors.white,
                                            shape: const StadiumBorder(),
                                          ),
                                          onPressed: _ending ? null : _endCall,
                                          icon: const CallGlyph(Icons.call_end_rounded),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ExcludeSemantics(
                          child: Text(
                            context.l10n.end,
                            style: const TextStyle(fontSize: 12, height: 1.1, color: Color(0xC7FFFFFF)),
                          ),
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
                    glyph: (color) => IconTheme.merge(
                      data: IconThemeData(size: actionSize * glyphShare),
                      child: DialPadGlyph(color: color),
                    ),
                    label: context.l10n.dialPad,
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
    );
  }

  /// The End pill's taps belong to its IconButton; the glass button only animates the press.
  static void _noTap() {}

  // Room above the top row so its edge reveal reaches full opacity.
  static const double _keypadTop = 16;

  // The scripts below were measured per frame off a 120 fps ColorOS 17 recording (docs/call-screens.md).

  /// Opening: how far below its place a key is, as a share of its distance from the bottom row,
  /// by milliseconds. The keypad spreads up from the bottom row, 3% past its place, and eases back.
  static const _spread = [
    (0.0, .36), (8.0, .34), (33.0, .26), (50.0, .21), (67.0, .15), (83.0, .10), (100.0, .06), //
    (117.0, .02), (133.0, .0), (150.0, -.012), (167.0, -.02), (183.0, -.025), (200.0, -.029),
    (234.0, -.029), (250.0, -.025), (267.0, -.02), (300.0, -.016), (325.0, -.012), (350.0, -.006), (392.0, .0),
  ];

  static double _sample(List<(double, double)> points, double x) {
    if (x <= points.first.$1) return points.first.$2;
    for (var i = 1; i < points.length; i++) {
      final (x0, y0) = points[i - 1];
      final (x1, y1) = points[i];
      if (x <= x1) return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
    }
    return points.last.$2;
  }

  /// The action row's scale and opacity. Opening, each button shrinks to half and fades in 105 ms;
  /// closing, they wait 200 ms for the keys to go, then grow back (170 ms) and fade in (250 ms).
  (double, double) get _actionsScript {
    if (_closing) {
      final ms = _ms - 200;
      return (
        .5 + .5 * Curves.decelerate.transform((ms / 170).clamp(0.0, 1.0)),
        Curves.decelerate.transform((ms / 250).clamp(0.0, 1.0)),
      );
    }
    final out = (_ms / 105).clamp(0.0, 1.0);
    return (1 - .5 * out, 1 - out);
  }

  /// When this call's note was first opened; the note's identity for Recents.
  DateTime? _noteAt;
  bool _hasNote = false;

  Future<void> _editNote() async {
    // The menu item can fire after the call ended and took this panel with it.
    if (!mounted) return;
    final at = _noteAt ??= DateTime.now();
    final hasNote = await editCallNote(context, widget.call.number ?? '', at, light: true);
    if (mounted) setState(() => _hasNote = hasNote);
  }

  Widget _keypadKey(int index, double p, double size, double stride, double upperHeight) {
    final (digit, letters) = _keys[index];
    // ColorOS 17: the keypad spreads up out of the bottom row. Rows fade in bottom-up 29 ms apart,
    // upper rows more slowly and trailing 11 ms each, and in each row the middle key leads its
    // neighbours by 18 ms. Closing, every key sinks back toward the bottom row and fades together.
    final row = index ~/ 3;
    final fromBottom = 3 - row;
    final side = index % 3 != 1;
    // From the key's centre to the bottom row's top edge, where the spread is anchored.
    final reach = 58 + fromBottom * stride;
    final fullHeight = _keypadTop + stride * 4 - (widget.landscape ? 4 : 0);
    final top = upperHeight - fullHeight + _keypadTop + row * stride;
    // Landscape clips at the panel's edge: reveal whole keys as space opens, never a sliced one.
    final edgeReveal = widget.landscape
        ? (top / 16).clamp(0.0, 1.0) * ((upperHeight - top - size) / 4).clamp(0.0, 1.0)
        : 1.0;
    final column = widget.width / 3;
    return Positioned(
      key: ValueKey('morph-key-$digit'),
      left: (index % 3) * column + 6,
      top: top,
      width: column - 12,
      height: size,
      child: AnimatedBuilder(
        animation: _keysIn,
        builder: (context, child) {
          final ms = _ms;
          final double below, opacity;
          if (_closing) {
            below = .0021 * math.min(ms, 160);
            opacity = math.pow(1 - (ms / 160).clamp(0.0, 1.0), 1.6).toDouble();
          } else {
            below = _sample(_spread, ms - 11 * fromBottom - (side ? 18 : 0));
            opacity = Curves.decelerate.transform(
              ((ms - 29 * fromBottom) / ((110 + 37 * fromBottom) * (side ? 1.2 : 1))).clamp(0.0, 1.0),
            );
          }
          return Opacity(
            key: ValueKey('keypad-fade-$digit'),
            opacity: opacity * edgeReveal,
            // Paint-only, so the key's hit area stays put.
            child: Transform.translate(offset: Offset(0, below * reach), child: child),
          );
        },
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
                          // The font sets "*" high, like a superscript; lower it to sit centred.
                          Transform.translate(
                            offset: Offset(0, digit == '*' ? 7 : 0),
                            child: Text(digit, style: const TextStyle(fontSize: 30, height: 1.05, color: Colors.white)),
                          ),
                          // Keys without letters (1, *, #) centre their digit rather than leaving
                          // room for an empty line.
                          if (letters.isNotEmpty)
                            Text(
                              letters,
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
