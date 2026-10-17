import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

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
  const _CallSession({super.key, required this.snapshot, required this.call, required this.sims});
  final CallSnapshot snapshot;
  final CallInfo call;
  final List<SimCard> sims;

  @override
  State<_CallSession> createState() => _CallSessionState();
}

class _CallSessionState extends State<_CallSession> with TickerProviderStateMixin {
  bool _keypadOpen = false;
  String _digits = '';
  String? _routeToast;
  Timer? _toastTimer;

  /// Keypad morph progress, spring-driven so a mid-flight reversal keeps its momentum.
  late final AnimationController _morph = AnimationController(vsync: this);

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

  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 1);

  /// Snaps the last 1% so the keypad accepts touches quickly instead of waiting out the tail.
  static const _settled = Tolerance(distance: .01, velocity: .1);

  Widget _scrollArea(Widget child) => CustomScrollView(
    physics: const OneUIScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  void _toggleKeypad() {
    if (_keypadOpen) TelecomBridge.instance.stopDtmf(widget.call.id);
    setState(() => _keypadOpen = !_keypadOpen);
    final target = _keypadOpen ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = target;
    } else {
      _morph.animateWith(
        SpringSimulation(_spring, _morph.value, target, _morph.velocity, tolerance: _settled, snapToEnd: true),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _morph.isAnimating) _morph.value = _keypadOpen ? 1 : 0;
    if (widget.call.state != CallState.ringing) _enter();
  }

  @override
  void didUpdateWidget(_CallSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.call.state != CallState.ringing) _enter();
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
    final switchDuration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 300);
    return PopScope(
      canPop: !_keypadOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _keypadOpen) _toggleKeypad();
      },
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
                  );
            final animatedControls = AnimatedSwitcher(
              duration: switchDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .08), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: controls,
            );
            final header = Column(
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
                          ? _scrollArea(Column(mainAxisAlignment: MainAxisAlignment.end, children: [animatedControls]))
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
                          SizedBox(height: compact ? 4 : 16),
                          // Slightly above centre in the space the controls leave.
                          const Spacer(flex: 2),
                          header,
                          const SizedBox(height: 16),
                          const Spacer(flex: 3),
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
    );
  }
}
