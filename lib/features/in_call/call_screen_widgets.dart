import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../widgets/letter_avatar.dart';

/// The call backdrop, as on ColorOS 17: the phone's own wallpaper, blurred by Android behind the
/// transparent call window (`WallpaperBackdrop.kt`), under black fades at the top and bottom.
/// When the system can't blur (Android < 12, battery saver, some devices), a soft gradient in the
/// wallpaper's own colours stands in, else an aurora tinted from the caller's avatar colour.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({super.key, required this.child, this.wallpaper, this.seed, this.dim});
  final Widget child;

  /// What Android reports about the wallpaper; null until it answers.
  final WallpaperBackdrop? wallpaper;

  /// The caller's name, tinting the fallback aurora when there are no wallpaper colours; null
  /// keeps it blue, teal and violet for private, conference and unknown calls.
  final String? seed;

  /// The keypad's open progress (0-1): the fades ease to an even dim behind it.
  final ValueListenable<double>? dim;

  @override
  Widget build(BuildContext context) {
    final blurred = wallpaper?.blur ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 400),
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: blurred
              // The blurred wallpaper shows through the transparent window.
              ? const SizedBox.expand(key: ValueKey('wallpaper'))
              : KeyedSubtree(
                  key: ValueKey<Object?>((wallpaper?.colors, seed)),
                  child: _aurora(wallpaper?.colors ?? const [], seed),
                ),
        ),
        ValueListenableBuilder(
          valueListenable: dim ?? const AlwaysStoppedAnimation(0.0),
          builder: (context, t, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .22, .5, .78, 1],
                colors: [
                  // ColorOS's black fades at the top and bottom, then an even dim behind the keypad.
                  for (final (rest, keypad) in const [
                    (Color(0x99000000), Color(0x99000000)),
                    (Color(0x33000000), Color(0x73000000)),
                    (Color(0x14000000), Color(0x80000000)),
                    (Color(0x80000000), Color(0x8C000000)),
                    (Color(0xE6000000), Color(0xB3000000)),
                  ])
                    Color.lerp(rest, keypad, t.clamp(0.0, 1.0))!,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  /// A soft aurora: a dark base with blurred-looking blobs, in the wallpaper's own colours when
  /// Android gives them, else in hues around the caller's avatar colour. Painted once.
  static Widget _aurora(List<Color> wallpaperColors, String? seed) {
    final Color Function(int i, double lightness, double saturation) tone;
    if (wallpaperColors.isNotEmpty) {
      tone = (i, lightness, saturation) {
        final hsl = HSLColor.fromColor(wallpaperColors[i % wallpaperColors.length]);
        return hsl.withLightness(lightness).withSaturation(math.min(hsl.saturation, saturation)).toColor();
      };
    } else {
      final hue = seed == null ? 200.0 : HSLColor.fromColor(LetterAvatar.colorFor(seed)).hue;
      const shifts = [0.0, 45.0, -50.0, 20.0, -30.0];
      tone = (i, lightness, saturation) =>
          HSLColor.fromAHSL(1, (hue + shifts[i % shifts.length]) % 360, saturation, lightness).toColor();
    }
    Widget blob(Alignment centre, double radius, Color color) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(center: centre, radius: radius, colors: [color, color.withValues(alpha: 0)]),
      ),
    );
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tone(0, .20, .45), tone(4, .12, .40), const Color(0xFF06080B)],
              ),
            ),
          ),
          blob(const Alignment(-.9, -.75), .95, tone(0, .42, .62).withValues(alpha: .75)),
          blob(const Alignment(1, -.1), .85, tone(1, .38, .62).withValues(alpha: .6)),
          blob(const Alignment(-.5, .7), .9, tone(2, .42, .62).withValues(alpha: .7)),
          blob(const Alignment(.8, .95), .75, tone(3, .40, .62).withValues(alpha: .6)),
        ],
      ),
    );
  }
}

String callerName(CallInfo call) {
  if (call.isConference) return 'Conference call';
  if (call.isPrivate) return 'Private number';
  final number = call.number ?? '';
  return ContactsRepository.instance.nameFor(number) ??
      ((call.name?.trim().isNotEmpty ?? false)
          ? call.name!.trim()
          : (call.formattedNumber ?? (number.isEmpty ? 'Unknown' : number)));
}

/// The caller's name when there is one worth tinting by; null for private, conference and bare numbers.
String? backdropSeed(CallInfo call) {
  if (call.isPrivate || call.isConference) return null;
  final name = callerName(call);
  return LetterAvatar.initials(name).isEmpty ? null : name;
}

class CallHeader extends StatelessWidget {
  const CallHeader({
    super.key,
    required this.call,
    required this.sims,
    required this.compact,
    this.keypadProgress = 0,
    this.digits = '',
    this.chip,
  });
  final CallInfo call;
  final List<SimCard> sims;
  final bool compact;
  final double keypadProgress;

  /// Typed DTMF digits; while the keypad is open they take the title's place.
  final String digits;

  /// A short status pill under the timer ("Muted", "Speaker on").
  final String? chip;

  @override
  Widget build(BuildContext context) {
    final name = callerName(call);
    final number = call.number ?? '';
    final shownNumber = call.formattedNumber ?? number;
    final sim = sims.where((s) => s.id == call.simId).firstOrNull;
    final contact = call.isPrivate || call.isConference ? null : ContactsRepository.instance.contactFor(number);
    final k = keypadProgress.clamp(0.0, 1.0);
    final fade = 1 - Curves.easeOut.transform(k);
    final avatarSize = compact ? 60.0 : 76.0;
    final showDigits = digits.isNotEmpty && k > .5;
    // ColorOS 17: name, number and status on the left, photo on the right. With the keypad open
    // the photo folds away and the typed digits take the title's place, centred.
    final centred = k > .5;
    final align = centred ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centred ? TextAlign.center : TextAlign.start;
    // ColorOS puts the number and the city on lines of their own.
    final subtitles = showDigits
        ? [name]
        : [
            if (name != shownNumber && shownNumber.isNotEmpty && !call.isPrivate && !call.isConference) shownNumber,
            ?call.location,
          ];
    final held = call.state == CallState.holding;
    final ended = call.state == CallState.disconnected || call.state == CallState.disconnecting;
    final folded = Curves.easeInOutCubic.transform(k);
    return AnimatedOpacity(
      opacity: ended ? .6 : (held ? .55 : 1),
      duration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: align,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Text(
                        showDigits ? _tail(digits) : name,
                        key: ValueKey(showDigits),
                        textAlign: textAlign,
                        maxLines: showDigits ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 26 : 32,
                          height: 1.15,
                          fontWeight: showDigits ? FontWeight.w400 : FontWeight.w700,
                          letterSpacing: showDigits ? 2 : -0.4,
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    for (final (i, line) in subtitles.indexed) ...[
                      SizedBox(height: i == 0 ? 4 : 2),
                      Text(
                        line,
                        textAlign: textAlign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: .72)),
                      ),
                    ],
                    SizedBox(height: compact ? 12 : 18),
                    CallStatus(
                      call: call,
                      sim: sims.length > 1 ? sim : null,
                      alignment: centred ? Alignment.center : AlignmentDirectional.centerStart,
                    ),
                  ],
                ),
              ),
              // The photo folds away sideways as the keypad opens.
              ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 1 - folded,
                  child: Opacity(
                    opacity: fade,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 16, top: 2),
                      child: _RingingHalo(
                        // Ripples while it rings, and more slowly while we're calling out.
                        active: call.state == CallState.ringing || _calling(call.state),
                        slow: call.state != CallState.ringing,
                        size: avatarSize,
                        child: call.isPrivate || call.isConference
                            ? CircleAvatar(
                                radius: avatarSize / 2,
                                backgroundColor: Colors.white.withValues(alpha: 0.14),
                                child: Icon(
                                  call.isConference ? Icons.groups_rounded : Icons.person_rounded,
                                  size: avatarSize * 0.48,
                                  color: Colors.white70,
                                ),
                              )
                            : FutureBuilder(
                                future: contact?.thumbnail == null
                                    ? null
                                    : ContactsRepository.instance.fullPhoto(contact!.id),
                                builder: (context, full) =>
                                    LetterAvatar(name: name, photo: full.data ?? contact?.thumbnail, size: avatarSize),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: chip == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      key: ValueKey(chip),
                      padding: const EdgeInsets.only(top: 10),
                      child: _Badge(label: chip!, bright: true),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Long DTMF strings keep their latest digits visible.
  static String _tail(String digits) => digits.length > 18 ? '…${digits.substring(digits.length - 17)}' : digits;
}

/// Soft rings breathing out from the avatar while the phone rings.
bool _calling(CallState state) =>
    state == CallState.dialing || state == CallState.connecting || state == CallState.newCall;

class _RingingHalo extends StatefulWidget {
  const _RingingHalo({required this.active, required this.size, required this.child, this.slow = false});
  final bool active;
  final bool slow;
  final double size;
  final Widget child;

  @override
  State<_RingingHalo> createState() => _RingingHaloState();
}

class _RingingHaloState extends State<_RingingHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_RingingHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    _pulse.duration = Duration(milliseconds: widget.slow ? 3200 : 2400);
    if (run && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!run && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: CustomPaint(painter: widget.active ? _HaloPainter(_pulse) : null, child: widget.child),
  );
}

class _HaloPainter extends CustomPainter {
  _HaloPainter(this.pulse) : super(repaint: pulse);
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    for (final offset in const [0.0, 0.5]) {
      final t = (pulse.value + offset) % 1;
      canvas.drawCircle(
        size.center(Offset.zero),
        radius * (1 + .45 * Curves.easeOut.transform(t)),
        Paint()..color = Colors.white.withValues(alpha: .16 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter oldDelegate) => oldDelegate.pulse != pulse;
}

/// The transient status toast under the timer ("Muted", "Speaker on").
class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.bright = false});
  final String label;
  final bool bright;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: bright ? .18 : .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: bright ? Colors.white : Colors.white70),
    ),
  );
}

class CallStatus extends StatefulWidget {
  const CallStatus({super.key, required this.call, this.sim, this.alignment = Alignment.center});
  final CallInfo call;

  /// Shown as a small SIM mark in its colour; only passed on dual-SIM phones, as on ColorOS.
  final SimCard? sim;
  final AlignmentGeometry alignment;
  @override
  State<CallStatus> createState() => _CallStatusState();
}

class _CallStatusState extends State<CallStatus> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  DateTime? _endedAt;
  int _dots = 3;

  /// Breathes the "On hold" text.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    lowerBound: .45,
    value: 1,
  );

  bool get _ended => widget.call.state == CallState.disconnected || widget.call.state == CallState.disconnecting;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ticker ?? _syncTicker();
    _syncPulse();
  }

  @override
  void didUpdateWidget(CallStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.state != widget.call.state || oldWidget.call.connectTime != widget.call.connectTime) {
      _syncTicker();
      _syncPulse();
    }
  }

  void _syncTicker() {
    _ticker?.cancel();
    // The duration freezes when the call ends rather than counting through the summary.
    if (_ended) _endedAt ??= DateTime.now();
    _dots = 3;
    if (widget.call.state == CallState.active && widget.call.connectTime != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (_calling(widget.call.state) && !MediaQuery.disableAnimationsOf(context)) {
      _ticker = Timer.periodic(const Duration(milliseconds: 400), (_) {
        if (mounted) setState(() => _dots = (_dots + 1) % 4);
      });
    } else {
      _ticker = null;
    }
  }

  bool get _live => widget.call.state == CallState.active && widget.call.connectTime != null;

  void _syncPulse() {
    if (widget.call.state == CallState.holding && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _endedText(CallInfo call) {
    final reason = switch (call.disconnectCode) {
      'busy' => 'Line busy',
      'rejected' => 'Call declined',
      'missed' => 'Missed call',
      'canceled' => 'Call cancelled',
      'error' => call.disconnectLabel ?? 'Call failed',
      _ => 'Call ended',
    };
    final start = call.connectTime;
    return start == null ? reason : '$reason · ${_format((_endedAt ?? DateTime.now()).difference(start))}';
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final text = switch (call.state) {
      CallState.active when call.connectTime != null => _format(DateTime.now().difference(call.connectTime!)),
      CallState.active => 'Connected',
      CallState.dialing || CallState.connecting || CallState.newCall || CallState.selectPhoneAccount => 'Calling',
      CallState.ringing => 'Incoming call',
      CallState.holding => 'On hold',
      CallState.disconnecting || CallState.disconnected => _endedText(call),
      CallState.unknown => 'Phone call',
    };
    final style = TextStyle(
      fontSize: 20,
      height: 1.2,
      color: call.state == CallState.active ? Colors.white : Colors.white.withValues(alpha: .85),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final Widget label = text == 'Calling'
        // Dots fill in one by one; the hidden ones keep the width steady.
        ? Text.rich(
            TextSpan(
              text: 'Calling',
              children: [
                for (var i = 0; i < 3; i++)
                  TextSpan(
                    text: '.',
                    style: TextStyle(color: i < _dots ? null : Colors.transparent),
                  ),
              ],
            ),
            style: style,
          )
        : Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    // ColorOS: small glyphs for the line (HD, Wi-Fi, which SIM), then the status as plain text.
    final glyphs = [
      if (call.isHd) const _HdCallGlyph(),
      if (call.isWifi) const Icon(Icons.wifi_calling_rounded, size: 17, color: Colors.white70),
      if (widget.sim case final sim?)
        Semantics(
          label: sim.label,
          child: Icon(Icons.sim_card_rounded, size: 16, color: sim.color),
        ),
    ];
    return SizedBox(
      height: 30,
      child: Align(
        alignment: widget.alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final glyph in glyphs) ...[glyph, const SizedBox(width: 6)],
            if (glyphs.isNotEmpty) const SizedBox(width: 2),
            Flexible(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
                // Keyed by phase, not by text, so the timer ticks in place.
                child: KeyedSubtree(
                  key: ValueKey(_live ? 'timer' : call.state),
                  // "On hold" breathes; the timer stays still, since a call can last an hour.
                  child: _live ? label : FadeTransition(opacity: _pulse, child: label),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(Duration duration) {
    final seconds = duration.isNegative ? 0 : duration.inSeconds;
    final minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '${seconds ~/ 3600}:$minutes:$rest' : '$minutes:$rest';
  }
}

/// ColorOS's HD call mark: a handset with a small "HD" beside its top.
class _HdCallGlyph extends StatelessWidget {
  const _HdCallGlyph();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'HD call',
    child: const ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.call_rounded, size: 16, color: Colors.white70),
          Text(
            'HD',
            style: TextStyle(fontSize: 8, height: 1, fontWeight: FontWeight.w800, color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}

class HeldCallChip extends StatelessWidget {
  const HeldCallChip({super.key, required this.call, required this.onSwap});
  final CallInfo call;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onSwap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_rounded, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'On hold: ${callerName(call)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Swap',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFB5E8D1)),
            ),
          ],
        ),
      ),
    ),
  );
}
