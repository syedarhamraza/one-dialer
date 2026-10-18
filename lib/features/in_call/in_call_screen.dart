import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import 'call_control_panel.dart';
import 'call_controls.dart';
import 'call_screen_widgets.dart';
import 'incoming_controls.dart';

export 'call_screen_widgets.dart' show callerName;

/// The call engine owns Telecom state; this screen only coordinates its presentation.
class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  List<SimCard> _sims = const [];

  /// The keypad's open progress, which blurs the photo poster behind it.
  final _keypadBlur = ValueNotifier<double>(0);

  @override
  void dispose() {
    _keypadBlur.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Caller lookup must not prevent answering if a contacts provider is unavailable.
    ContactsRepository.instance.start().catchError((Object _) {});
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
    backgroundColor: Colors.black,
    body: StreamBuilder<CallSnapshot>(
      stream: TelecomBridge.instance.callState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final call = state?.primary;
        return ValueListenableBuilder(
          valueListenable: ContactsRepository.instance.contacts,
          builder: (context, _, _) {
            final contact = call == null || call.isPrivate || call.isConference
                ? null
                : ContactsRepository.instance.contactFor(call.number ?? '');
            return CallBackdrop(
              photo: contact?.thumbnail,
              contactId: contact?.id,
              blur: _keypadBlur,
              seed: call == null ? null : backdropSeed(call),
              child: SafeArea(
                child: switch ((state, call)) {
                  (null, _) => const SizedBox.expand(),
                  (_, null) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call_end_rounded, size: 44, color: Colors.white54),
                        SizedBox(height: 20),
                        Text(
                          'Call ended',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  (final state?, final call?) => _CallSession(
                    key: ValueKey(call.id),
                    snapshot: state,
                    call: call,
                    sims: _sims,
                    keypadBlur: _keypadBlur,
                  ),
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
  String? _routeToast;
  Timer? _toastTimer;

  /// Keypad morph progress, spring-driven so a mid-flight reversal keeps its momentum.
  late final AnimationController _morph = AnimationController(vsync: this)
    ..addListener(() => widget.keypadBlur.value = _morph.value.clamp(0.0, 1.0));

  /// Plays once when the call's controls first appear (opened, or just answered).
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  void _enter() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.value == 0 && !_entrance.isAnimating) {
      _entrance.forward();
    }
  }

  /// The glass package's smooth spring: no overshoot, so the panel never over-opens.
  static final _spring = GlassSpring.smooth(duration: const Duration(milliseconds: 700));

  /// Snaps the last 1% so the keypad accepts touches quickly instead of waiting out the tail.
  static const _settled = Tolerance(distance: .01, velocity: .1);

  Widget _scrollArea(Widget child) => CustomScrollView(
    physics: const OneUIScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  /// Where the released Answer ball sits (global), while it waits for Telecom and then flies
  /// into the End pill: green turning red, circle stretching to a stadium, as on ColorOS 17.
  Rect? _ball;
  Timer? _ballTimeout;

  /// Runs the glass package's snappy spring, so the ball lands with a slight overshoot.
  late final AnimationController _fly = AnimationController.unbounded(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _land();
    });
  final _endKey = GlobalKey();
  final _stackKey = GlobalKey();

  void _answered(Rect ball) {
    TelecomBridge.instance.answer(widget.call.id);
    if (MediaQuery.disableAnimationsOf(context) || ball.isEmpty) return;
    setState(() => _ball = ball);
    // If Telecom never connects, don't leave the ball hanging.
    _ballTimeout = Timer(const Duration(seconds: 4), _land);
  }

  void _land() {
    _ballTimeout?.cancel();
    if (mounted && _ball != null) setState(() => _ball = null);
  }

  /// Starts the flight once the connected controls (and the End pill) are laid out.
  void _launchBall() {
    if (_ball == null || _fly.isAnimating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ball != null && !_fly.isAnimating) {
        // Fast at first, slowing into place, a touch past it (~2%) and gently back (ColorOS).
        _fly.animateTo(1, duration: const Duration(milliseconds: 700), curve: const Cubic(.25, 1, .4, 1.08));
      }
    });
  }

  Rect? _localRect(Rect global) {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || !stack.hasSize) return null;
    return global.shift(-stack.localToGlobal(Offset.zero));
  }

  Widget _flyingBall() {
    final from = _localRect(_ball!);
    final endBox = _endKey.currentContext?.findRenderObject() as RenderBox?;
    final to = endBox == null || !endBox.hasSize
        ? null
        : _localRect(MatrixUtils.transformRect(endBox.getTransformTo(null), Offset.zero & endBox.size));
    if (from == null) return const SizedBox.shrink();
    final t = to == null ? 0.0 : _fly.value;
    final settled = t.clamp(0.0, 1.0);
    // ColorOS's path curves: the ball drops first, then sweeps across into the pill (a quadratic
    // Bezier bending toward the point below the ball, level with End).
    final Rect rect;
    if (to == null) {
      rect = from;
    } else {
      // Bends only part way toward the corner below the ball, for a gentle arc.
      final bend = Offset.lerp((from.center + to.center) / 2, Offset(from.center.dx, to.center.dy), .25)!;
      final u = 1 - t;
      final centre = from.center * (u * u) + bend * (2 * u * t) + to.center * (t * t);
      rect = Rect.fromCenter(
        center: centre,
        width: lerpDouble(from.width, to.width, t)!,
        height: lerpDouble(from.height, to.height, t)!,
      );
    }
    // The ball wears the End pill's finish the whole way, its colour morphing from Answer's green
    // through orange to End's red, so it lands as the pill itself.
    final color = _ballColor.transform(settled)!;
    // Lands on the End pill's exact top colour (not just a lightened red), so the swap is invisible.
    final top = Color.lerp(Color.lerp(color, Colors.white, .16), const Color(0xFFE5604F), settled * settled)!;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(rect.shortestSide / 2),
      side: const BorderSide(color: Color(0x40FFFFFF), width: .8),
    );
    final iconSize = lerpDouble(from.shortestSide * .46, 41, settled)!;
    // The handset tips over and hands off to the hang-up glyph as it lands.
    final handoff = const Interval(.6, 1).transform(settled);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Container(
          key: const ValueKey('answer-flight'),
          decoration: ShapeDecoration(
            shape: shape,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, color]),
            shadows: [BoxShadow(color: color.withValues(alpha: .3), blurRadius: 22, offset: const Offset(0, 6))],
          ),
          foregroundDecoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(rect.shortestSide / 2)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x40FFFFFF), Color(0x0AFFFFFF), Color(0x00FFFFFF)],
              stops: [0, .45, .55],
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - handoff,
                child: Transform.rotate(
                  angle: 2.36 * settled,
                  child: Icon(Icons.call_rounded, color: Colors.white, size: iconSize),
                ),
              ),
              Opacity(
                opacity: handoff,
                child: Icon(Icons.call_end_rounded, color: Colors.white, size: iconSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _ballColor = TweenSequence<Color?>([
    TweenSequenceItem(
      tween: ColorTween(begin: answerGreen, end: const Color(0xFFF5A04A)),
      weight: 1,
    ),
    TweenSequenceItem(
      // End's red, so the hand-off to the real pill is seamless.
      tween: ColorTween(begin: const Color(0xFFF5A04A), end: const Color(0xFFC93D31)),
      weight: 1,
    ),
  ]);

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
    final route = widget.snapshot.audio.route;
    if (route != oldWidget.snapshot.audio.route) {
      _toastTimer?.cancel();
      setState(() => _routeToast = route == AudioRoute.speaker ? 'Speaker on' : audioRouteLabel(route));
      _toastTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _routeToast = null);
      });
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _ballTimeout?.cancel();
    _fly.dispose();
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
      canPop: !_keypadOpen,
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
                          key: const ValueKey('incoming'),
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
                  final header = _FadeIn(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CallHeader(
                          call: call,
                          sims: widget.sims,
                          compact: compact,
                          keypadProgress: progress,
                          digits: _digits,
                          chip: ringing || ended ? null : _routeToast ?? (widget.snapshot.audio.muted ? 'Muted' : null),
                        ),
                        if (held != null && !ringing && !ended) ...[
                          const SizedBox(height: 16),
                          HeldCallChip(call: held, onSwap: () => TelecomBridge.instance.unhold(held.id)),
                        ],
                      ],
                    ),
                  );
                  if (landscape) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _scrollArea(Column(mainAxisAlignment: MainAxisAlignment.center, children: [header])),
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
                        animatedControls,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_ball != null) AnimatedBuilder(animation: _fly, builder: (context, _) => _flyingBall()),
        ],
      ),
    );
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
