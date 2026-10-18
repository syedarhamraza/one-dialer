import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../widgets/letter_avatar.dart';

/// Photo-led call backdrop, ColorOS 17 poster style: the caller's photo full-screen and sharp
/// with a dark band at the bottom behind the controls, else an aurora tinted from their avatar
/// colour. Nothing is blurred or animated per frame.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({super.key, required this.child, this.photo, this.contactId, this.seed, this.blur});
  final Widget child;

  /// The contact's thumbnail, shown at once while [contactId]'s full-size photo loads.
  final Uint8List? photo;
  final String? contactId;

  /// How far the photo is blurred, 0 to 1: ColorOS blurs the poster while the keypad is open.
  final ValueListenable<double>? blur;

  /// The caller's name; null keeps the neutral navy for private, conference and unknown calls.
  final String? seed;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 400),
        layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: KeyedSubtree(
          key: ValueKey<Object?>(photo ?? seed),
          child: photo != null ? _PosterPhoto(thumbnail: photo!, contactId: contactId, blur: blur) : _tint(seed),
        ),
      ),
      // A photo keeps its face clear, with a shade at the top for the name and a dark band at the
      // bottom behind the controls; behind the keypad it eases to an even grey, as on ColorOS. The
      // aurora only needs a light touch.
      if (photo != null)
        ValueListenableBuilder(
          valueListenable: blur ?? const AlwaysStoppedAnimation(0.0),
          builder: (context, t, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .28, .5, .72, 1],
                colors: [
                  for (final (sharp, blurred) in const [
                    (Color(0x73000000), Color(0x80000000)),
                    (Color(0x0D000000), Color(0x73000000)),
                    (Color(0x0D000000), Color(0x80000000)),
                    (Color(0xC7000000), Color(0x8C000000)),
                    (Color(0xF2000000), Color(0xA6000000)),
                  ])
                    Color.lerp(sharp, blurred, t)!,
                ],
              ),
            ),
          ),
        )
      else
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .4, 1],
              colors: [Color(0x40000000), Color(0x14000000), Color(0x8C000000)],
            ),
          ),
        ),
      child,
    ],
  );

  /// A soft aurora: a dark base with three blurred-looking blobs in neighbouring hues, so the
  /// glass controls have colour and light to bend. Painted once; nothing animates.
  static Widget _tint(String? seed) {
    final hue = seed == null ? 200.0 : HSLColor.fromColor(LetterAvatar.colorFor(seed)).hue;
    Color tone(double shift, double lightness, [double saturation = .62]) =>
        HSLColor.fromAHSL(1, (hue + shift) % 360, saturation, lightness).toColor();
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
                colors: [tone(0, .20, .45), tone(-30, .12, .40), const Color(0xFF06080B)],
              ),
            ),
          ),
          blob(const Alignment(-.9, -.75), .95, tone(0, .42).withValues(alpha: .75)),
          blob(const Alignment(1, -.1), .85, tone(45, .38).withValues(alpha: .6)),
          blob(const Alignment(-.5, .7), .9, tone(-50, .42).withValues(alpha: .7)),
          blob(const Alignment(.8, .95), .75, tone(20, .40).withValues(alpha: .6)),
        ],
      ),
    );
  }
}

/// The contact's photo, sharp and cover-fit; the thumbnail stands in until the full size loads.
/// It blurs progressively as [blur] rises, the way ColorOS softens the poster behind its keypad.
class _PosterPhoto extends StatelessWidget {
  const _PosterPhoto({required this.thumbnail, this.contactId, this.blur});
  final Uint8List thumbnail;
  final String? contactId;
  final ValueListenable<double>? blur;

  @override
  Widget build(BuildContext context) {
    final photo = FutureBuilder(
      future: contactId == null ? null : ContactsRepository.instance.fullPhoto(contactId!),
      builder: (context, full) => LayoutBuilder(
        builder: (context, box) => Image.memory(
          full.data ?? thumbnail,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          // Decoded at screen size, not the camera's full resolution.
          cacheHeight: (box.maxHeight * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      ),
    );
    if (blur == null) return photo;
    return ValueListenableBuilder(
      valueListenable: blur!,
      child: photo,
      builder: (context, t, child) => ImageFiltered(
        enabled: t > 0,
        imageFilter: ImageFilter.blur(sigmaX: 28 * t, sigmaY: 28 * t, tileMode: TileMode.clamp),
        child: child!,
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
    final subtitle = showDigits
        ? name
        : [
            if (name != shownNumber && shownNumber.isNotEmpty && !call.isPrivate && !call.isConference) shownNumber,
            ?call.location,
          ].join(' · ');
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
                          fontSize: compact ? 26 : 30,
                          height: 1.15,
                          fontWeight: showDigits ? FontWeight.w400 : FontWeight.w600,
                          letterSpacing: showDigits ? 2 : -0.4,
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: textAlign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: .72)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    CallStatus(call: call, alignment: centred ? Alignment.center : AlignmentDirectional.centerStart),
                  ],
                ),
              ),
              // The photo folds away sideways as the keypad opens. A contact photo is already the
              // full-screen poster behind, so the circle only shows for everyone else.
              if (contact?.thumbnail == null)
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
                              : LetterAvatar(name: name, size: avatarSize),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1 - folded,
              child: Opacity(
                opacity: fade,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(icon: Icons.sim_card_outlined, label: sim?.label ?? 'Phone call', dot: sim?.color),
                      if (call.isHd) const _Badge(label: 'HD'),
                      if (call.isWifi) const _Badge(icon: Icons.wifi_rounded, label: 'Wi-Fi Calling'),
                    ],
                  ),
                ),
              ),
            ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon, this.bright = false, this.dot});
  final String label;
  final IconData? icon;
  final bool bright;

  /// The SIM's own colour, as Android shows it.
  final Color? dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: bright ? .18 : .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ] else if (icon != null) ...[
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: bright ? Colors.white : Colors.white70),
          ),
        ),
      ],
    ),
  );
}

class CallStatus extends StatefulWidget {
  const CallStatus({super.key, required this.call, this.alignment = Alignment.center});
  final CallInfo call;
  final AlignmentGeometry alignment;
  @override
  State<CallStatus> createState() => _CallStatusState();
}

class _CallStatusState extends State<CallStatus> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  DateTime? _endedAt;
  int _dots = 3;

  /// Breathes the "On hold" text. The live dot stays still: a call can last an hour.
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
      fontSize: 16,
      color: call.state == CallState.active ? const Color(0xFFB5E8D1) : Colors.white70,
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
    return SizedBox(
      height: 28,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
        // Keyed by phase, not by text, so the timer ticks in place.
        child: KeyedSubtree(
          key: ValueKey(_live ? 'timer' : call.state),
          child: _live
              ? Align(
                  alignment: widget.alignment,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 3, 12, 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _pulse,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: Color(0xFF5BD69A), shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: 7),
                        label,
                      ],
                    ),
                  ),
                )
              : Align(
                  alignment: widget.alignment,
                  child: FadeTransition(opacity: _pulse, child: label),
                ),
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
