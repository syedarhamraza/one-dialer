import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/sim_badge.dart';
import 'call_controls.dart';
import '../../l10n/l10n.dart';
import '../../widgets/call_glyph.dart';
import '../../widgets/call_marks.dart';
import 'call_background.dart';

/// The call backdrop: a soft aurora tinted from the caller's photo or avatar colour (or the
/// [background] picked for the call), under black fades at the top and bottom.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({
    super.key,
    required this.child,
    this.seed,
    this.tones,
    this.background,
    this.frosted = false,
    this.dim,
    this.shown = true,
  });
  final Widget child;

  /// False until the first call arrives: the window stays black, then fades straight into this
  /// caller's tint instead of the default one first.
  final bool shown;

  /// The caller's name, tinting the aurora; null keeps it blue, teal and violet for private,
  /// conference and unknown calls.
  final String? seed;

  /// The caller's photo colours ([photoTones]), tinting the aurora in place of [seed]'s.
  final List<Color>? tones;

  /// A colour or photo in place of the caller's tint (see [CallBackgrounds.forCall]).
  final CallBackground? background;

  /// Connected: a photo [background] frosts under the controls (ringing keeps it sharp).
  final bool frosted;

  /// The keypad's open progress (0-1): the fades ease to an even dim behind it, and a photo
  /// [background] blurs all over.
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
              ? KeyedSubtree(
                  key: ValueKey((seed, tones == null ? null : Object.hashAll(tones!), background)),
                  child: _fill(seed, tones, background, frosted, dim),
                )
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

  static Widget _fill(
    String? seed,
    List<Color>? tones,
    CallBackground? background,
    bool frosted,
    ValueListenable<double>? dim,
  ) {
    final hue = switch ((background?.colour, seed)) {
      (final colour?, _) => HSLColor.fromColor(colour).hue,
      (_, final seed?) => HSLColor.fromColor(LetterAvatar.colorFor(seed)).hue,
      _ => 200.0,
    };
    final image = background?.image;
    // The photo's colours only for the default background: a picked colour or photo wins.
    if (image == null) return _aurora(hue, background?.colour == null ? tones : null);
    return _PhotoFill(image: image, fallback: _aurora(hue), frosted: frosted, soft: background!.soft, dim: dim);
  }

  /// A soft aurora: a dark base with blurred-looking blobs in hues around [hue], or in the photo's
  /// [tones] (base, then one per blob; their saturation caps the aurora's). Painted once.
  static Widget _aurora(double hue, [List<Color>? tones]) {
    const shifts = [0.0, 45.0, -50.0, 20.0, -30.0];
    // tone(0-3) are the blobs (and 0 the base's top-left), tone(4) the base: the photo's regions.
    const region = [1, 2, 3, 4, 0];
    Color tone(int i, double lightness, double saturation) {
      if (tones == null) {
        return HSLColor.fromAHSL(1, (hue + shifts[i % shifts.length]) % 360, saturation, lightness).toColor();
      }
      final hsl = HSLColor.fromColor(tones[region[i % 5]]);
      return HSLColor.fromAHSL(1, hsl.hue, math.min(saturation, hsl.saturation), lightness).toColor();
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

/// A photo filling the call screen. The controls draw no live blur of their own (the aurora is
/// soft already), so the photo carries it: sharp while ringing, frosted toward the bottom once
/// [frosted] (connected), and blurred all over with the keypad's [dim] progress. Both blurred
/// copies are made once, then only cross-faded: no blur runs per frame. [fallback] shows while
/// the photo decodes, or if it can't. [soft] (Blur & dim) shows it blurred and dimmed all over.
class _PhotoFill extends StatefulWidget {
  const _PhotoFill({required this.image, required this.fallback, required this.frosted, this.soft = false, this.dim});
  final ImageProvider image;
  final Widget fallback;
  final bool frosted;
  final bool soft;
  final ValueListenable<double>? dim;

  @override
  State<_PhotoFill> createState() => _PhotoFillState();
}

class _PhotoFillState extends State<_PhotoFill> with SingleTickerProviderStateMixin {
  ImageStream? _stream;
  late final _listener = ImageStreamListener(
    (info, _) {
      if (mounted) setState(() => _image = info.image);
    },
    onError: (_, _) {
      if (mounted) setState(() => _image = null);
    },
  );
  ui.Image? _image;
  _PhotoPainter? _painter;
  late final _frost = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: widget.frosted ? 1 : 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_PhotoFill old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) _resolve();
    if (old.frosted != widget.frosted) {
      final target = widget.frosted ? 1.0 : 0.0;
      if (MediaQuery.disableAnimationsOf(context)) {
        _frost.value = target;
      } else {
        _frost.animateTo(target, curve: Curves.easeOut);
      }
    }
  }

  void _resolve() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _painter?.dispose();
    _frost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image != null) {
      final ratio = MediaQuery.devicePixelRatioOf(context);
      final old = _painter;
      if (old == null || old.image != image || old.ratio != ratio || old.dim != widget.dim || old.soft != widget.soft) {
        old?.dispose();
        _painter = _PhotoPainter(image, ratio, _frost, widget.dim, soft: widget.soft);
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // The photo itself, as Image draws it: full quality, never through the baked copies.
        RepaintBoundary(
          child: Image(
            image: widget.image,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // A little darker all over, so white text reads on bright photos between the fades.
            color: const Color(0x33000000),
            colorBlendMode: BlendMode.srcATop,
            frameBuilder: (_, child, frame, sync) => frame == null && !sync ? widget.fallback : child,
            // A deleted or unreadable photo falls back to the tint.
            errorBuilder: (_, _, _) => widget.fallback,
          ),
        ),
        if (image != null)
          RepaintBoundary(
            child: CustomPaint(painter: _painter, size: Size.infinite),
          ),
      ],
    );
  }
}

/// The blurred copies laid over the photo: frosted under the controls ([frost]) and all over
/// ([dim], the keypad). Made once per size (the keypad one on first use), then only drawn at their
/// opacities. [soft] draws only a dimmer all-over copy, always.
class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.image, this.ratio, this.frost, this.dim, {this.soft = false})
    : super(repaint: soft ? null : Listenable.merge([frost, ?dim]));
  final ui.Image image;
  final double ratio;
  final Animation<double> frost;
  final ValueListenable<double>? dim;
  final bool soft;

  /// How soft the blurred copies are.
  static const _sigma = 22.0;

  Size? _size;
  ui.Image? _frosted, _blurred;

  /// The photo blurred all over or, with [fade], only from just above the controls down; darkened
  /// like the [Image] under it.
  ui.Image _bake(Size size, {required bool fade}) {
    final rect = Offset.zero & size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    canvas.saveLayer(rect, Paint());
    canvas.saveLayer(
      rect,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma, tileMode: TileMode.clamp),
    );
    paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.cover, filterQuality: FilterQuality.medium);
    // Blur & dim: darker, as a wallpaper under the call.
    canvas.drawRect(rect, Paint()..color = soft ? const Color(0x73000000) : const Color(0x33000000));
    canvas.restore();
    if (fade) {
      // Sharp under the name, frosted under the buttons.
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [.58, .68], // just above the controls (from ~67% down)
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(rect),
      );
    }
    canvas.restore();
    final picture = recorder.endRecording();
    final baked = picture.toImageSync((size.width * ratio).ceil(), (size.height * ratio).ceil());
    picture.dispose();
    return baked;
  }

  void _draw(Canvas canvas, ui.Image baked, Rect rect, double opacity) {
    if (opacity <= 0) return;
    canvas.drawImageRect(
      baked,
      Rect.fromLTWH(0, 0, baked.width.toDouble(), baked.height.toDouble()),
      rect,
      Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    if (soft) {
      if (_size != size) {
        dispose();
        _blurred = _bake(size, fade: false);
        _size = size;
      }
      _draw(canvas, _blurred!, rect, 1);
      return;
    }
    if (_size != size) {
      dispose();
      _frosted = _bake(size, fade: true);
      _size = size;
    }
    _draw(canvas, _frosted!, rect, frost.value);
    // Made only once the keypad opens: most calls never do, and each copy is a full-screen bake.
    final dimmed = dim?.value ?? 0;
    if (dimmed > 0) _draw(canvas, _blurred ??= _bake(size, fade: false), rect, dimmed);
  }

  void dispose() {
    _frosted?.dispose();
    _blurred?.dispose();
    _frosted = _blurred = null;
  }

  @override
  bool shouldRepaint(_PhotoPainter old) => old.image != image || old.ratio != ratio || old.soft != soft;
}

/// Started by `inCallMain`, long before the call screen first draws (only once its activity
/// shows): loads contacts and fetches each caller's photo as calls arrive, so [CallHeader] lays
/// out the name and photo together.
abstract final class CallerLookup {
  /// The latest call state, for the screen to start from: it subscribes later, and the broadcast
  /// stream doesn't replay what this listener already got.
  static CallSnapshot? latest;

  static void start() {
    final repo = ContactsRepository.instance..ignoreChanges = true;
    // Caller lookup must not prevent answering if a contacts provider is unavailable.
    repo.start().catchError((Object _) {});
    final backgrounds = CallBackgrounds.instance;
    void prefetch() {
      final calls = latest?.calls ?? const <CallInfo>[];
      if (calls.isNotEmpty) backgrounds.load('all');
      for (final call in calls) {
        if (call.isPrivate || call.isConference) continue;
        if (repo.contactFor(call.number ?? '') case final contact?) {
          repo.thumbnail(contact.id);
          // The header loads the full photo anyway; the backdrop shares it.
          backgrounds.load(contact.id);
          backgrounds.loadPhoto(contact.id);
          backgrounds.loadTones(contact.id);
        }
      }
    }

    TelecomBridge.instance.callState.listen((s) {
      latest = s;
      if (s.calls.isEmpty) {
        repo.forgetPhotos();
        backgrounds.forgetPhotos();
      }
      prefetch();
    }, onError: (Object _) {});
    repo.contacts.addListener(prefetch);
  }
}

String callerName(AppLocalizations l10n, CallInfo call) {
  if (call.isConference) return l10n.conferenceCall;
  if (call.isPrivate) return l10n.privateNumber;
  final number = call.number ?? '';
  return ContactsRepository.instance.nameFor(number) ??
      ((call.name?.trim().isNotEmpty ?? false)
          ? call.name!.trim()
          : (call.formattedNumber ?? (number.isEmpty ? l10n.unknown : number)));
}

/// The caller's name when there is one worth tinting by; null for private, conference and bare numbers.
String? backdropSeed(CallInfo call) {
  if (call.isPrivate || call.isConference) return null;
  final name = callerName(
    lookupAppLocalizations(const Locale('en')),
    call,
  ); // English: the tint stays the same in every language
  return LetterAvatar.initials(name).isEmpty ? null : name;
}

class CallHeader extends StatelessWidget {
  const CallHeader({
    super.key,
    required this.call,
    required this.sims,
    required this.compact,
    this.keypadProgress = 0,
    this.recording = false,
  });
  final CallInfo call;

  /// The companion recorder is recording this call: a red dot by the timer.
  final bool recording;
  final List<SimCard> sims;
  final bool compact;
  final double keypadProgress;

  @override
  Widget build(BuildContext context) {
    final number = call.number ?? '';
    final contact = call.isPrivate || call.isConference ? null : ContactsRepository.instance.contactFor(number);
    if (contact == null) return _header(context, null, null);
    // Only the caller's photo, one row: reading every contact's photo froze the call screen.
    final repo = ContactsRepository.instance;
    return ListenableBuilder(
      listenable: CallBackgrounds.instance,
      // With the photo filling the screen, ColorOS drops the small one and centres the lines.
      builder: (context, _) => CallBackgrounds.instance.callerPhotoFills(contact.id)
          ? _header(context, contact, null)
          : FutureBuilder(
              future: repo.thumbnail(contact.id),
              initialData: repo.cachedThumbnail(contact.id),
              builder: (context, thumb) => _header(context, contact, thumb.data),
            ),
    );
  }

  Widget _header(BuildContext context, DialerContact? contact, Uint8List? photo) {
    final name = callerName(context.l10n, call);
    final number = call.number ?? '';
    final shownNumber = call.formattedNumber ?? number;
    final sim = sims.where((s) => s.id == call.simId).firstOrNull;
    final k = keypadProgress.clamp(0.0, 1.0);
    final fade = 1 - Curves.easeOut.transform(k);
    // Stacked (Settings › Caller photo): a big round photo, the name, then the status, all centred.
    final stacked = photo != null && DialerPrefs.instance.callerLayout.value == 'stacked';
    final side = photo != null && !stacked;
    // ColorOS 17: a contact with a photo gets name, number and status on the left and the photo in
    // a circle on the right; everyone else gets them centred with no circle. As the keypad opens
    // the photo folds away, the lines glide to the centre and the number and city fold up, all
    // with the keypad's progress.
    final folded = k; // Already eased by the screen; easing it again made it lurch mid-way.
    final line = AlignmentDirectional(side ? folded - 1 : 0, -1);
    final textAlign = !side || folded == 1 ? TextAlign.center : TextAlign.start;
    // ColorOS puts the number and the city on lines of their own.
    final subtitles = [
      if (name != shownNumber &&
          shownNumber.isNotEmpty &&
          !call.isPrivate &&
          !call.isConference &&
          !(contact != null && DialerPrefs.instance.hideContactNumbers.value))
        shownNumber,
      ?call.location,
    ];
    final subtitleStyle = TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: .72));
    final held = call.state == CallState.holding;
    final ended = call.state == CallState.disconnected || call.state == CallState.disconnecting;
    // Just the photo, as on ColorOS: no ring and no ripple.
    Widget avatar(double size) => FutureBuilder(
      future: ContactsRepository.instance.fullPhoto(contact!.id),
      builder: (context, full) => LetterAvatar(name: name, photo: full.data ?? photo, size: size),
    );
    final nameText = Align(
      alignment: line,
      child: Text(
        name,
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 28 : 36,
          height: 1.15,
          // Semibold, not bold: vivo's system font draws 700 very heavy.
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
    final subtitleLines = ClipRect(
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
                    style: subtitleStyle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final status = CallStatus(
      call: call,
      recording: recording,
      sim: sims.length > 1 ? sim : null,
      simSlot: sim == null ? 0 : sims.indexOf(sim) + 1,
      alignment: line,
    );
    final Widget body;
    if (stacked) {
      // The photo folds up into the status line as the keypad opens.
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1 - folded,
              child: Opacity(
                opacity: fade,
                child: Padding(
                  padding: EdgeInsets.only(bottom: compact ? 16 : 24),
                  child: Center(child: avatar(compact ? 96 : 120)),
                ),
              ),
            ),
          ),
          nameText,
          subtitleLines,
          // Under the name, as in the side layout: the time reads with who it's with.
          SizedBox(height: compact ? 16 : 24),
          status,
        ],
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                nameText,
                subtitleLines,
                SizedBox(height: compact ? 16 : 24),
                status,
              ],
            ),
          ),
          // The photo folds away sideways as the keypad opens.
          if (side)
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                widthFactor: 1 - folded,
                child: Opacity(
                  opacity: fade,
                  child: Padding(
                    // Its top lines up with the top of the name's capitals.
                    padding: const EdgeInsetsDirectional.only(start: 16, top: 8),
                    child: avatar(compact ? 64 : 80),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return AnimatedOpacity(
      opacity: ended ? .6 : (held ? .55 : 1),
      duration: const Duration(milliseconds: 250),
      // ColorOS keeps the caller a little further from the edges than the controls.
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: body),
    );
  }
}

bool _calling(CallState state) =>
    state == CallState.dialing || state == CallState.connecting || state == CallState.newCall;

class CallStatus extends StatefulWidget {
  const CallStatus({
    super.key,
    required this.call,
    this.sim,
    this.simSlot = 0,
    this.alignment = Alignment.center,
    this.recording = false,
  });
  final CallInfo call;
  final bool recording;

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
      'busy' => context.l10n.lineBusy,
      'rejected' => context.l10n.callDeclined,
      'missed' => context.l10n.callTypeMissed,
      'canceled' => context.l10n.callCancelled,
      'error' => call.disconnectLabel ?? context.l10n.callFailed,
      _ => context.l10n.callEnded,
    };
    final start = call.connectTime;
    return start == null ? reason : '$reason · ${_format((_endedAt ?? DateTime.now()).difference(start))}';
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final text = switch (call.state) {
      CallState.active when call.connectTime != null => _format(DateTime.now().difference(call.connectTime!)),
      CallState.active => context.l10n.connected,
      CallState.dialing ||
      CallState.connecting ||
      CallState.newCall ||
      CallState.selectPhoneAccount => context.l10n.calling,
      CallState.ringing => context.l10n.callTypeIncoming,
      CallState.holding => context.l10n.onHold,
      CallState.disconnecting || CallState.disconnected => _endedText(call),
      CallState.unknown => context.l10n.phoneCall,
    };
    final style = TextStyle(
      fontSize: 22,
      height: 1.2,
      color: call.state == CallState.active ? Colors.white : Colors.white.withValues(alpha: .85),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final Widget label = text == context.l10n.calling
        // Dots fill in one by one; the hidden ones keep the width steady.
        ? Text.rich(
            TextSpan(
              text: context.l10n.calling,
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
      if (widget.recording)
        Semantics(
          label: context.l10n.recordingNow,
          child: const ExcludeSemantics(
            child: SizedBox.square(
              dimension: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(color: endRed, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      if (call.isVonr || call.isVolte)
        Semantics(
          label: call.isVonr ? context.l10n.vonrCall : context.l10n.volteCall,
          child: VolteMark(color: Colors.white70, nr: call.isVonr, fontSize: 8),
        ),
      if (call.isHd) const _HdCallGlyph(),
      if (call.isWifi) const Icon(Icons.wifi_calling_rounded, size: 17, color: Colors.white70),
      if (widget.sim case final sim?)
        Semantics(
          label: sim.label,
          child: SimBadge(label: widget.simSlot > 0 ? '${widget.simSlot}' : '', color: Colors.white70, height: 18),
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
    label: context.l10n.hdCall,
    child: const ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CallGlyph(Icons.call_rounded, size: 16, color: Colors.white70),
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
/// with a Switch pill and a red End button. Tapping anywhere but End switches to that call.
class HeldCallCard extends StatelessWidget {
  const HeldCallCard({super.key, required this.call, required this.onSwitch, required this.onEnd});
  final CallInfo call;
  final VoidCallback onSwitch;

  /// Hangs up the held call without switching to it first.
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final name = callerName(context.l10n, call);
    return CallBody(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: context.l10n.switchToOnHold(name),
                excludeSemantics: true,
                onTap: onSwitch,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSwitch,
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
                            Text(context.l10n.onHold, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: const ShapeDecoration(color: Color(0x29FFFFFF), shape: StadiumBorder()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_vert_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.switchCall,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
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
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: context.l10n.endHeldCall(name),
              excludeSemantics: true,
              onTap: onEnd,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEnd,
                child: const SizedBox.square(
                  dimension: 40,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(color: endRed, shape: CircleBorder()),
                    child: Icon(Icons.call_end_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
