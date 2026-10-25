import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../widgets/letter_avatar.dart';
import 'call_controls.dart';

/// The call backdrop: a soft aurora tinted from the caller's avatar colour, under black fades at
/// the top and bottom.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({super.key, required this.child, this.seed, this.dim, this.shown = true});
  final Widget child;

  /// False until the first call arrives: the window stays black, then fades straight into this
  /// caller's tint instead of the default one first.
  final bool shown;

  /// The caller's name, tinting the aurora; null keeps it blue, teal and violet for private,
  /// conference and unknown calls.
  final String? seed;

  /// The keypad's open progress (0-1): the fades ease to an even dim behind it.
  final ValueListenable<double>? dim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // A new caller's tint fades in over the last one.
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 400),
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: shown
              ? KeyedSubtree(key: ValueKey(seed), child: _aurora(seed))
              : const SizedBox.expand(key: ValueKey('black')),
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
                    (Color(0x24000000), Color(0x80000000)),
                    (Color(0xA6000000), Color(0x8C000000)),
                    (Color(0xF2000000), Color(0xB3000000)),
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

  /// A soft aurora: a dark base with blurred-looking blobs in hues around the caller's avatar
  /// colour. Painted once.
  static Widget _aurora(String? seed) {
    final hue = seed == null ? 200.0 : HSLColor.fromColor(LetterAvatar.colorFor(seed)).hue;
    const shifts = [0.0, 45.0, -50.0, 20.0, -30.0];
    Color tone(int i, double lightness, double saturation) =>
        HSLColor.fromAHSL(1, (hue + shifts[i % shifts.length]) % 360, saturation, lightness).toColor();
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
  const CallHeader({super.key, required this.call, required this.sims, required this.compact, this.keypadProgress = 0});
  final CallInfo call;
  final List<SimCard> sims;
  final bool compact;
  final double keypadProgress;

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
    // ColorOS 17: a contact with a photo gets name, number and status on the left and the photo in
    // a circle on the right; everyone else gets them centred with no circle. As the keypad opens
    // the photo folds away, the lines glide to the centre and the number and city fold up, all
    // with the keypad's progress.
    final photo = contact?.thumbnail;
    final folded = k; // Already eased by the screen; easing it again made it lurch mid-way.
    final line = AlignmentDirectional(photo == null ? 0 : folded - 1, -1);
    final textAlign = photo == null || folded == 1 ? TextAlign.center : TextAlign.start;
    // ColorOS puts the number and the city on lines of their own.
    final subtitles = [
      if (name != shownNumber && shownNumber.isNotEmpty && !call.isPrivate && !call.isConference) shownNumber,
      ?call.location,
    ];
    final held = call.state == CallState.holding;
    final ended = call.state == CallState.disconnected || call.state == CallState.disconnecting;
    return AnimatedOpacity(
      opacity: ended ? .6 : (held ? .55 : 1),
      duration: const Duration(milliseconds: 250),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: line,
                  child: Text(
                    name,
                    textAlign: textAlign,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 26 : 32,
                      height: 1.15,
                      // Medium, not bold: vivo's system font draws 700 very heavy.
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 1 - folded,
                    child: Opacity(
                      opacity: fade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, subtitle) in subtitles.indexed) ...[
                            SizedBox(height: i == 0 ? 4 : 2),
                            Align(
                              alignment: line,
                              child: Text(
                                subtitle,
                                textAlign: textAlign,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: .72)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 12 : 18),
                CallStatus(
                  call: call,
                  sim: sims.length > 1 ? sim : null,
                  simSlot: sim == null ? 0 : sims.indexOf(sim) + 1,
                  alignment: line,
                ),
              ],
            ),
          ),
          // The photo folds away sideways as the keypad opens.
          if (photo != null)
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                widthFactor: 1 - folded,
                child: Opacity(
                  opacity: fade,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16, top: 4),
                    // Just the photo, as on ColorOS: no ring and no ripple.
                    child: FutureBuilder(
                      future: ContactsRepository.instance.fullPhoto(contact!.id),
                      builder: (context, full) => LetterAvatar(name: name, photo: full.data ?? photo, size: avatarSize),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

bool _calling(CallState state) =>
    state == CallState.dialing || state == CallState.connecting || state == CallState.newCall;

class CallStatus extends StatefulWidget {
  const CallStatus({super.key, required this.call, this.sim, this.simSlot = 0, this.alignment = Alignment.center});
  final CallInfo call;

  /// Shown as a small numbered SIM mark; only passed on dual-SIM phones, as on ColorOS.
  final SimCard? sim;

  /// The SIM's slot number (1-based) printed in the mark.
  final int simSlot;
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
          child: ExcludeSemantics(child: _SimMark(slot: widget.simSlot)),
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

/// ColorOS's SIM mark: a small outlined SIM card, clipped at one corner, with its slot number.
class _SimMark extends StatelessWidget {
  const _SimMark({required this.slot});
  final int slot;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _SimOutline(),
    child: SizedBox(
      width: 12,
      height: 15,
      child: Center(
        child: Text(
          slot > 0 ? '$slot' : '',
          style: const TextStyle(fontSize: 8.5, height: 1, fontWeight: FontWeight.w800, color: Colors.white70),
        ),
      ),
    ),
  );
}

class _SimOutline extends CustomPainter {
  const _SimOutline();

  @override
  void paint(Canvas canvas, Size size) {
    const corner = 2.0, cut = 4.0;
    final r = Offset.zero & size;
    canvas.drawPath(
      Path()
        ..moveTo(r.left + corner, r.top)
        ..lineTo(r.right - cut, r.top)
        ..lineTo(r.right, r.top + cut)
        ..lineTo(r.right, r.bottom - corner)
        ..quadraticBezierTo(r.right, r.bottom, r.right - corner, r.bottom)
        ..lineTo(r.left + corner, r.bottom)
        ..quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - corner)
        ..lineTo(r.left, r.top + corner)
        ..quadraticBezierTo(r.left, r.top, r.left + corner, r.top)
        ..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white70,
    );
  }

  @override
  bool shouldRepaint(_SimOutline oldDelegate) => false;
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

/// The other call, on hold, as a frosted card above the caller: its avatar, name and "On hold",
/// with a Switch pill. Tapping anywhere on it switches to that call.
class HeldCallCard extends StatelessWidget {
  const HeldCallCard({super.key, required this.call, required this.onSwitch});
  final CallInfo call;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final name = callerName(call);
    return Semantics(
      button: true,
      label: 'Switch to $name, on hold',
      excludeSemantics: true,
      onTap: onSwitch,
      child: CallBody(
        radius: 28,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSwitch,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                LetterAvatar(name: name, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text('On hold', style: TextStyle(fontSize: 13, color: Colors.white60)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const DecoratedBox(
                  decoration: ShapeDecoration(color: Color(0x29FFFFFF), shape: StadiumBorder()),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_vert_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Switch',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
