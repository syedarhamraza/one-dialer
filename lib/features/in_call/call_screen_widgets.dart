import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../widgets/letter_avatar.dart';

/// Photo-led call backdrop: the caller's photo blurred once into a small bitmap, else a
/// tint of their avatar colour. Nothing is blurred or animated per frame.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({super.key, required this.child, this.photo, this.seed});
  final Widget child;
  final Uint8List? photo;

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
          child: photo != null ? _BlurredPhoto(photo: photo!, fallback: _tint(seed)) : _tint(seed),
        ),
      ),
      // Keeps white text readable on any photo and grounds the controls.
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, .4, 1],
            colors: [Color(0x40000000), Color(0x14000000), Color(0xD9000000)],
          ),
        ),
      ),
      child,
    ],
  );

  static Widget _tint(String? seed) {
    if (seed == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202638), Color(0xFF1C3A40), Color(0xFF0E1A21)],
          ),
        ),
      );
    }
    final hsl = HSLColor.fromColor(LetterAvatar.colorFor(seed));
    final top = hsl.withLightness(.30).withSaturation(math.min(hsl.saturation, .55)).toColor();
    final mid = hsl.withLightness(.16).withSaturation(math.min(hsl.saturation, .45)).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, const Color(0xFF07090C)],
        ),
      ),
    );
  }
}

class _BlurredPhoto extends StatefulWidget {
  const _BlurredPhoto({required this.photo, required this.fallback});
  final Uint8List photo;
  final Widget fallback;

  @override
  State<_BlurredPhoto> createState() => _BlurredPhotoState();
}

class _BlurredPhotoState extends State<_BlurredPhoto> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(_BlurredPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo != widget.photo) _render();
  }

  /// Blurs a tiny copy once; scaled up, it reads as a full-screen blur for free.
  Future<void> _render() async {
    final bytes = widget.photo;
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      final source = (await codec.getNextFrame()).image;
      codec.dispose();
      const width = 90, height = 200;
      final scale = math.max(width / source.width, height / source.height);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        source,
        Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
        Rect.fromCenter(
          center: const Offset(width / 2, height / 2),
          width: source.width * scale,
          height: source.height * scale,
        ),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10, tileMode: TileMode.clamp)
          ..colorFilter = const ColorFilter.mode(Color(0x59000000), BlendMode.srcATop),
      );
      final image = await recorder.endRecording().toImage(width, height);
      source.dispose();
      if (!mounted || bytes != widget.photo) return image.dispose();
      setState(() {
        _image?.dispose();
        _image = image;
      });
    } on Object {
      // A corrupt photo keeps the tinted fallback.
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _image == null
      ? widget.fallback
      : RawImage(image: _image, fit: BoxFit.cover, filterQuality: FilterQuality.medium);
}

String callerName(CallInfo call) {
  if (call.isConference) return 'Conference call';
  if (call.isPrivate) return 'Private number';
  final number = call.number ?? '';
  return ContactsRepository.instance.nameFor(number) ??
      ((call.name?.trim().isNotEmpty ?? false) ? call.name!.trim() : (call.formattedNumber ?? (number.isEmpty ? 'Unknown' : number)));
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
    final avatarSize = compact ? 84.0 : 120.0;
    final showDigits = digits.isNotEmpty && k > .5;
    final subtitle = showDigits
        ? name
        : [
            if (name != shownNumber && shownNumber.isNotEmpty && !call.isPrivate && !call.isConference) shownNumber,
            ?call.location,
          ].join(' · ');
    final held = call.state == CallState.holding;
    final ended = call.state == CallState.disconnected || call.state == CallState.disconnecting;
    Widget collapse(Widget child) => ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1 - Curves.easeInOutCubic.transform(k),
        child: Opacity(opacity: fade, child: child),
      ),
    );
    return AnimatedOpacity(
      opacity: ended ? .6 : (held ? .55 : 1),
      duration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          collapse(
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 16 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(icon: Icons.sim_card_outlined, label: sim?.label ?? 'Phone call'),
                      if (call.isHd) const _Badge(label: 'HD'),
                      if (call.isWifi) const _Badge(icon: Icons.wifi_rounded, label: 'Wi-Fi Calling'),
                    ],
                  ),
                  SizedBox(height: compact ? 16 : 28),
                  _RingingHalo(
                    active: call.state == CallState.ringing,
                    size: avatarSize,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(0, 6))],
                      ),
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
                          : LetterAvatar(name: name, photo: contact?.thumbnail, size: avatarSize),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              showDigits ? _tail(digits) : name,
              key: ValueKey(showDigits),
              textAlign: TextAlign.center,
              maxLines: showDigits ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 28 : 34,
                height: 1.15,
                fontWeight: showDigits ? FontWeight.w400 : FontWeight.w500,
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
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: .72)),
            ),
          ],
          const SizedBox(height: 8),
          CallStatus(call: call),
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
class _RingingHalo extends StatefulWidget {
  const _RingingHalo({required this.active, required this.size, required this.child});
  final bool active;
  final double size;
  final Widget child;

  @override
  State<_RingingHalo> createState() => _RingingHaloState();
}

class _RingingHaloState extends State<_RingingHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

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
    child: CustomPaint(
      painter: widget.active ? _HaloPainter(_pulse) : null,
      child: widget.child,
    ),
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
  const _Badge({required this.label, this.icon, this.bright = false});
  final String label;
  final IconData? icon;
  final bool bright;

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
        if (icon != null) ...[Icon(icon, size: 13, color: Colors.white70), const SizedBox(width: 5)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: bright ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ],
    ),
  );
}

class CallStatus extends StatefulWidget {
  const CallStatus({super.key, required this.call});
  final CallInfo call;
  @override
  State<CallStatus> createState() => _CallStatusState();
}

class _CallStatusState extends State<CallStatus> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  DateTime? _endedAt;
  late final AnimationController _holdPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    lowerBound: .45,
    value: 1,
  );

  bool get _ended => widget.call.state == CallState.disconnected || widget.call.state == CallState.disconnecting;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _ticker = widget.call.state == CallState.active && widget.call.connectTime != null
        ? Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  void _syncPulse() {
    if (widget.call.state == CallState.holding && !MediaQuery.disableAnimationsOf(context)) {
      if (!_holdPulse.isAnimating) _holdPulse.repeat(reverse: true);
    } else {
      _holdPulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _holdPulse.dispose();
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
      CallState.dialing || CallState.connecting || CallState.newCall || CallState.selectPhoneAccount => 'Calling…',
      CallState.ringing => 'Incoming call',
      CallState.holding => 'On hold',
      CallState.disconnecting || CallState.disconnected => _endedText(call),
      CallState.unknown => 'Phone call',
    };
    return SizedBox(
      height: 22,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
        child: FadeTransition(
          // Keyed by phase, not by text, so the timer ticks in place.
          key: ValueKey(call.state == CallState.active && call.connectTime != null ? 'timer' : call.state),
          opacity: _holdPulse,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: call.state == CallState.active ? const Color(0xFFB5E8D1) : Colors.white70,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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
