import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/place_call.dart';
import 'call_control_panel.dart';
import 'call_background.dart';
import 'call_controls.dart';
import 'call_screen_widgets.dart';
import 'incoming_controls.dart';
import '../../widgets/call_glyph.dart';

export 'call_screen_widgets.dart' show callerName;

/// The call engine owns Telecom state; this screen only coordinates its presentation.
class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  List<SimCard> _sims = const [];

  /// The last snapshot that had a call in it.
  CallSnapshot? _last;

  /// The call already asked "which SIM?", so the menu shows once.
  String? _askedSim;

  /// Telecom holds a call started outside the app (another app, a car kit, a notification) on
  /// dual SIM with no default until the call screen names a SIM. No pick ends it, as Android's own chooser does.
  Future<void> _chooseSim(CallInfo call) async {
    final telecom = TelecomBridge.instance;
    try {
      final sims = _sims.isNotEmpty ? _sims : await telecom.getSims();
      if (!mounted) return;
      final sim = sims.length == 1 ? sims.first : (sims.isEmpty ? null : await pickSim(context, sims));
      await (sim == null ? telecom.hangUp(call.id) : telecom.selectSim(call.id, sim.id));
    } on PlatformException {
      await telecom.hangUp(call.id);
    }
  }

  /// The keypad's open progress, which dims the backdrop behind it.
  final _keypadBlur = ValueNotifier<double>(0);

  @override
  void dispose() {
    _keypadBlur.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSims();
  }

  Future<void> _loadSims() async {
    try {
      final sims = await TelecomBridge.instance.getSims();
      if (mounted) setState(() => _sims = sims);
    } on PlatformException {
      // The call remains usable when phone-account details are unavailable.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    // CallBackdrop paints the whole screen.
    backgroundColor: Colors.transparent,
    body: StreamBuilder<CallSnapshot>(
      stream: TelecomBridge.instance.callState,
      // Already sent to CallerLookup's earlier listener; the broadcast stream won't repeat it.
      initialData: CallerLookup.latest,
      builder: (context, snapshot) {
        // The ended summary goes before the screen closes; keep showing it rather than a second "Call ended".
        if (snapshot.data?.primary != null) _last = snapshot.data;
        final state = _last;
        final call = state?.primary;
        if (snapshot.data != null && snapshot.data!.primary == null) {
          // This engine outlives the call: a menu or sheet left open would cover the next one.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
          });
        }
        if (call != null && call.state == CallState.selectPhoneAccount && _askedSim != call.id) {
          _askedSim = call.id;
          WidgetsBinding.instance.addPostFrameCallback((_) => _chooseSim(call));
        }
        return ListenableBuilder(
          // Contacts load in late (the aurora's tint follows the caller's name), and so do the
          // caller's photo and saved background.
          listenable: Listenable.merge([
            ContactsRepository.instance.contacts,
            CallBackgrounds.instance,
          ]),
          builder: (context, _) {
            final contact = call == null || call.isPrivate || call.isConference
                ? null
                : ContactsRepository.instance.contactFor(call.number ?? '');
            return CallBackdrop(
              shown: call != null,
              dim: _keypadBlur,
              seed: call == null ? null : backdropSeed(call),
              background: call == null ? null : CallBackgrounds.instance.forCall(contact?.id),
              // Connected; an answered call stays frosted on the ended summary rather than sharpening
              // as it closes, while a declined or missed one stays sharp.
              frosted: switch (call?.state) {
                CallState.active || CallState.holding => true,
                CallState.disconnecting || CallState.disconnected => call?.connectTime != null,
                _ => false,
              },
              child: SafeArea(
                child: switch ((state, call)) {
                  (final state?, final call?) => _CallSession(
                    key: ValueKey(call.id),
                    snapshot: state,
                    call: call,
                    sims: _sims,
                    keypadBlur: _keypadBlur,
                  ),
                  _ => const SizedBox.expand(),
                },
              ),
            );
          },
        );
      },
    ),
  );
}

class _CallSession extends StatefulWidget {
  const _CallSession({
    super.key,
    required this.snapshot,
    required this.call,
    required this.sims,
    required this.keypadBlur,
  });
  final CallSnapshot snapshot;
  final CallInfo call;
  final List<SimCard> sims;
  final ValueNotifier<double> keypadBlur;

  @override
  State<_CallSession> createState() => _CallSessionState();
}

class _CallSessionState extends State<_CallSession> with TickerProviderStateMixin {
  bool _keypadOpen = false;
  String _digits = '';

  /// Keypad morph progress, spring-driven so a mid-flight reversal keeps its momentum.
  late final AnimationController _morph = AnimationController(vsync: this)..addListener(_syncDim);

  /// Feeds the backdrop's keypad dim. A snap during a build (reduced motion turned on mid-close)
  /// waits for the frame to end, since the backdrop can't rebuild mid-build.
  void _syncDim() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.keypadBlur.value = _morph.value.clamp(0.0, 1.0);
      });
    } else {
      widget.keypadBlur.value = _morph.value.clamp(0.0, 1.0);
    }
  }

  /// Plays once when the call's controls first appear (opened, or just answered).
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  void _enter() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_oneButton && _ball != null && !_fly.isAnimating) {
      // The 1-button controls wait for the green ball to start becoming End (ColorOS 17).
      return;
    } else if (_entrance.value == 0 && !_entrance.isAnimating) {
      // Just answered by swipe: the controls fade in quickly as the ball flies (ColorOS).
      _entrance.animateTo(1, duration: _ball != null && !_oneButton ? const Duration(milliseconds: 150) : null);
    }
  }

  /// The glass package's smooth spring: no overshoot, so the panel never over-opens.
  static final _spring = GlassSpring.smooth(duration: const Duration(milliseconds: 700));

  /// Snaps the last 1% so the keypad accepts touches quickly instead of waiting out the tail.
  static const _settled = Tolerance(distance: .01, velocity: .1);

  Widget _scrollArea(Widget child) => CustomScrollView(
    physics: const ClampingScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  /// Where the released Answer ball sits (global), while it waits for Telecom and then flies
  /// into the End pill: green turning red, circle stretching to a stadium, as on ColorOS 17.
  Rect? _ball;
  Timer? _ballTimeout;

  /// How far (global px) the released ball glides on up to the top of its travel, as on ColorOS.
  double _lift = 0;

  /// The 1-button ball: answered downward, it springs up into End from just under it instead of
  /// flying across (ColorOS 17).
  bool _oneButton = false;
  late final AnimationController _rise = AnimationController(vsync: this, duration: const Duration(milliseconds: 170));

  /// The flight, linear: [_flyingBall] eases each part on its own timeline.
  late final AnimationController _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _land();
    });
  final _endKey = GlobalKey();
  final _stackKey = GlobalKey();

  void _answered(Rect ball, double lift) {
    TelecomBridge.instance.answer(widget.call.id);
    if (MediaQuery.disableAnimationsOf(context) || ball.isEmpty) return;
    setState(() {
      _ball = ball;
      _lift = lift;
      _oneButton = DialerPrefs.instance.answerStyle.value == 'one';
    });
    // The ball takes its time to spring into End, longest for the 1-button swiped up, from furthest away.
    _fly.duration = Duration(
      milliseconds: !_oneButton ? 1000 : (DialerPrefs.instance.answerDirection.value == 'up' ? 1100 : 900),
    );
    _springIn = GlassSpringCurve(GlassSpring.bouncy(duration: _fly.duration! * .6), _fly.duration!);
    // The 2-button ball drops ahead of sliding across, so it curves in from above instead of a straight line.
    _springDrop = _oneButton
        ? _springIn
        : GlassSpringCurve(GlassSpring.bouncy(duration: _fly.duration! * .35), _fly.duration!);
    _rise.forward(from: 0);
    // If Telecom never connects, don't leave the ball hanging.
    _ballTimeout = Timer(const Duration(seconds: 4), _land);
  }

  void _land() {
    _ballTimeout?.cancel();
    if (mounted && _ball != null) setState(() => _ball = null);
    // Controls held back for the 1-button flight still have to show if it never ran.
    if (mounted && widget.call.state != CallState.ringing) _enter();
  }

  /// Starts the flight once the connected controls (and the End pill) are laid out.
  void _launchBall() {
    if (_ball == null || _fly.isAnimating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Let the ball settle in its spot before it flies.
      if (_rise.isAnimating) await _rise.forward().orCancel.catchError((_) {});
      if (mounted && _ball != null && !_fly.isAnimating) {
        _fly.forward(from: 0);
        _enter();
      }
    });
  }

  /// Whether [box] and every box above it are laid out: `getTransformTo` reads each one's size, and
  /// `DesignWidth`'s FittedBox may not have laid out its child yet when this builds.
  static bool _laidOut(RenderBox? box) {
    for (RenderObject? o = box; o != null; o = o.parent) {
      if (o is RenderBox && !o.hasSize) return false;
    }
    return box != null;
  }

  Rect? _localRect(Rect global) {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (!_laidOut(stack)) return null;
    // A full inverse, not just a shift: on narrow phones `DesignWidth` scales the whole screen.
    return MatrixUtils.transformRect(stack!.getTransformTo(null)..invert(), global);
  }

  // The ball springs into End on the glass package's bouncy spring over the whole flight: a soft,
  // unhurried overshoot past the pill's size and place, then settling. It stays green for the first
  // ~120 ms, then crossfades to red (the handset tipping over meanwhile).
  Curve _springIn = Curves.linear;
  Curve _springDrop = Curves.linear;
  static const _turn = Interval(.14, .43, curve: Curves.easeInOut);

  Widget _flyingBall() {
    final from = _localRect(_ball!.shift(Offset(0, -_lift * Curves.easeOutCubic.transform(_rise.value))));
    final endBox = _endKey.currentContext?.findRenderObject() as RenderBox?;
    final to = !_laidOut(endBox)
        ? null
        : _localRect(MatrixUtils.transformRect(endBox!.getTransformTo(null), Offset.zero & endBox.size));
    if (from == null) return const SizedBox.shrink();
    final t = to == null ? 0.0 : _fly.value;
    final Rect rect;
    if (to == null) {
      rect = from;
    } else {
      final move = _springIn.transform(t);
      rect = Rect.fromCenter(
        center: Offset(
          lerpDouble(from.center.dx, to.center.dx, move)!,
          lerpDouble(from.center.dy, to.center.dy, _springDrop.transform(t))!,
        ),
        width: lerpDouble(from.width, to.width, move)!,
        height: lerpDouble(from.height, to.height, move)!,
      );
    }
    // Green crossfades to End's red (not a colour tween): half way both layers are half see-through,
    // the muddy amber of ColorOS's morph. It lands as the pill itself.
    final red = _turn.transform(t);
    // The same shared finish as the End pill, so the hand-off on landing is invisible.
    final shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(rect.shortestSide / 2));
    final iconSize = lerpDouble(from.shortestSide * .52, 46, red)!;
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Container(
          key: const ValueKey('answer-flight'),
          foregroundDecoration: callGlassGlow(context, shape),
          alignment: Alignment.center,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - red,
                child: DecoratedBox(decoration: glassBody(answerGreen, shape, flat: callFlat(context))),
              ),
              Opacity(
                opacity: red,
                child: DecoratedBox(decoration: glassBody(endRed, shape, flat: callFlat(context))),
              ),
              // Our hang-up glyph is the handset turned 135°, so the handset simply tips over (growing to
              // CallGlyph's hang-up size) and lands already as End's icon.
              Transform.rotate(
                angle: 3 * math.pi / 4 * red,
                child: CallGlyph(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: iconSize * lerpDouble(1, CallGlyph.tipGrowth, red)!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleKeypad() {
    if (_keypadOpen) TelecomBridge.instance.stopDtmf(widget.call.id);
    setState(() => _keypadOpen = !_keypadOpen);
    final target = _keypadOpen ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = target;
    } else if (!_keypadOpen) {
      // Collapse alongside the reversed key cascade, without a separate fade-and-wait phase.
      _morph.animateTo(0, duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
    } else {
      _springTo(target);
    }
  }

  void _springTo(double target) => _morph.animateWith(
    SpringSimulation(_spring, _morph.value, target, _morph.velocity, tolerance: _settled, snapToEnd: true),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _morph.value = _keypadOpen ? 1 : 0;
    if (widget.call.state != CallState.ringing) _enter();
  }

  @override
  void didUpdateWidget(_CallSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.call.state != CallState.ringing) _enter();
    final state = widget.call.state;
    if (state == CallState.disconnected || state == CallState.disconnecting) {
      _land();
    } else if (state != CallState.ringing) {
      _launchBall();
    }
  }

  @override
  void dispose() {
    _ballTimeout?.cancel();
    _fly.dispose();
    _rise.dispose();
    _morph.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final ringing = call.state == CallState.ringing;
    final ended = call.state == CallState.disconnected || call.state == CallState.disconnecting;
    final held = widget.snapshot.calls.where((c) => c.id != call.id && c.state == CallState.holding).firstOrNull;
    final switchDuration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 350);
    return PopScope(
      // Back can't dismiss a ringing call (as on AOSP): answer, decline, or the volume key to silence.
      canPop: !_keypadOpen && !ringing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _keypadOpen) _toggleKeypad();
      },
      child: Stack(
        key: _stackKey,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _morph,
              builder: (context, _) => LayoutBuilder(
                builder: (context, constraints) {
                  final landscape = constraints.maxWidth > constraints.maxHeight;
                  final compact = landscape || constraints.maxHeight < 700;
                  final progress = Curves.easeInOutCubic.transform(_morph.value);
                  final Widget controls = ended
                      ? const SizedBox(key: ValueKey('ended'), width: double.infinity)
                      : ringing
                      ? IncomingControls(
                          // Per call: the cached engine keeps this screen, so the next call's ball
                          // would otherwise start where the last one was released.
                          key: ValueKey('incoming-${call.id}'),
                          call: call,
                          compact: compact,
                          isCurrent: () => mounted && widget.call.state == CallState.ringing,
                          onAnswer: _answered,
                          answerHidden: _ball != null,
                        )
                      : CallControlPanel(
                          key: const ValueKey('connected'),
                          call: call,
                          audio: widget.snapshot.audio,
                          recorder: widget.snapshot.recording,
                          callCount: widget.snapshot.calls.length,
                          width: landscape ? (constraints.maxWidth - 56) / 2 : constraints.maxWidth - 32,
                          compact: compact,
                          landscape: landscape,
                          progress: _morph.value,
                          animating: _morph.isAnimating,
                          keypadOpen: _keypadOpen,
                          onDigit: (digit) => setState(() => _digits += digit),
                          onToggle: _toggleKeypad,
                          entrance: _entrance,
                          endKey: _endKey,
                          hideEnd: _ball != null,
                        );
                  final animatedControls = AnimatedSwitcher(
                    duration: switchDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) =>
                        Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
                    // Incoming, connected and ended crossfade in place.
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: controls,
                  );
                  final heldCard = held != null && !ringing && !ended;
                  final header = _FadeIn(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The held card slides the caller down as it comes in, and back up as it goes.
                        AnimatedSize(
                          duration: switchDuration,
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: switchDuration,
                            child: heldCard
                                ? Padding(
                                    key: ValueKey(held.id),
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: HeldCallCard(
                                      call: held,
                                      onSwitch: () => TelecomBridge.instance.unhold(held.id),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ),
                        CallHeader(
                          call: call,
                          sims: widget.sims,
                          compact: compact,
                          keypadProgress: progress,
                          recording: widget.snapshot.recording?.recording ?? false,
                        ),
                      ],
                    ),
                  );
                  // As on ColorOS, what's typed shows right above the keys.
                  final typed = _TypedDigits(digits: _digits, progress: progress, compact: compact);
                  if (landscape) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _scrollArea(
                              Column(mainAxisAlignment: MainAxisAlignment.center, children: [header, typed]),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: ringing || ended
                                ? _scrollArea(
                                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [animatedControls]),
                                  )
                                : animatedControls,
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        Expanded(
                          child: _scrollArea(
                            Column(
                              children: [
                                // ColorOS 17 keeps the caller at the top, left-aligned.
                                SizedBox(height: compact ? 12 : 36),
                                header,
                                const SizedBox(height: 16),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                        if (!ringing && !ended) typed,
                        animatedControls,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_ball != null)
            AnimatedBuilder(animation: Listenable.merge([_rise, _fly]), builder: (context, _) => _flyingBall()),
        ],
      ),
    );
  }
}

/// The DTMF digits typed on the keypad: one centred line that opens above the keys with the
/// keypad, its latest digits kept in view.
class _TypedDigits extends StatelessWidget {
  const _TypedDigits({required this.digits, required this.progress, required this.compact});
  final String digits;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final open = digits.isEmpty ? 0.0 : progress.clamp(0.0, 1.0);
    if (open == 0) return const SizedBox.shrink();
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: open,
        child: Opacity(
          opacity: const Interval(.5, 1).transform(open),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LayoutBuilder(
              builder: (context, box) {
                final (text, style) = _fit(digits, box.maxWidth, MediaQuery.textScalerOf(context));
                return Text(
                  text,
                  key: const ValueKey('typed-digits'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// As on ColorOS: the digits shrink to fit as they're typed, then the earliest give way to
  /// an ellipsis so the latest stay in view.
  (String, TextStyle) _fit(String digits, double width, TextScaler scaler) {
    final last = _last;
    if (last != null && last.$1 == digits && last.$2 == width && last.$3 == scaler && last.$4 == compact) {
      return last.$5;
    }
    final fit = _measure(digits, width, scaler);
    _last = (digits, width, scaler, compact, fit);
    return fit;
  }

  // Rebuilt every frame of the keypad's morph; the measuring only reruns when something changes.
  static (String, double, TextScaler, bool, (String, TextStyle))? _last;

  (String, TextStyle) _measure(String digits, double width, TextScaler scaler) {
    TextStyle style(double size) => TextStyle(
      fontSize: size,
      height: 1.15,
      letterSpacing: size / 16,
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    bool fits(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final fit = painter.width <= width;
      painter.dispose();
      return fit;
    }

    final full = compact ? 26.0 : 32.0;
    for (final size in [full, full * .85, full * .72]) {
      if (fits(digits, style(size))) return (digits, style(size));
    }
    final small = style(full * .72);
    var keep = digits.length - 1;
    while (keep > 1 && !fits('…${digits.substring(digits.length - keep)}', small)) {
      keep--;
    }
    return ('…${digits.substring(digits.length - keep)}', small);
  }
}

/// Fades its child in once, when the call screen first shows it.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450),
    curve: Curves.easeOut,
    child: child,
    builder: (context, t, child) => Opacity(opacity: t, child: child),
  );
}
