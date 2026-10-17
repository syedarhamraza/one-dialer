import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import 'call_control_panel.dart';
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
    body: CallBackdrop(
      child: SafeArea(
        child: StreamBuilder<CallSnapshot>(
          stream: TelecomBridge.instance.callState,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.expand();
            final state = snapshot.data!;
            final call = state.primary;
            if (call == null) {
              return const Center(
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
              );
            }
            return ValueListenableBuilder(
              valueListenable: ContactsRepository.instance.contacts,
              builder: (context, _, _) =>
                  _CallSession(key: ValueKey(call.id), snapshot: state, call: call, sims: _sims),
            );
          },
        ),
      ),
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

class _CallSessionState extends State<_CallSession> with SingleTickerProviderStateMixin {
  bool _keypadOpen = false;
  String _digits = '';
  late final AnimationController _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  Widget _scrollArea(Widget child) => CustomScrollView(
    physics: const OneUIScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  void _toggleKeypad() {
    if (_keypadOpen) TelecomBridge.instance.stopDtmf(widget.call.id);
    setState(() => _keypadOpen = !_keypadOpen);
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = _keypadOpen ? 1 : 0;
    } else if (_keypadOpen) {
      _morph.forward();
    } else {
      _morph.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _morph.isAnimating) _morph.value = _keypadOpen ? 1 : 0;
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final ringing = call.state == CallState.ringing;
    final ended = call.state == CallState.disconnected || call.state == CallState.disconnecting;
    final held = widget.snapshot.calls.where((c) => c.id != call.id && c.state == CallState.holding).firstOrNull;
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
            final controls = ringing
                ? IncomingControls(call: call, isCurrent: () => mounted && widget.call.state == CallState.ringing)
                : CallControlPanel(
                    call: call,
                    audio: widget.snapshot.audio,
                    callCount: widget.snapshot.calls.length,
                    width: landscape ? (constraints.maxWidth - 56) / 2 : constraints.maxWidth - 32,
                    compact: compact,
                    landscape: landscape,
                    progress: progress,
                    animating: _morph.isAnimating,
                    keypadOpen: _keypadOpen,
                    digits: _digits,
                    onDigit: (digit) => setState(() => _digits += digit),
                    onToggle: _toggleKeypad,
                  );
            final header = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CallHeader(call: call, sims: widget.sims, compact: compact, keypadProgress: progress),
                if (held != null && !ringing && !ended) ...[
                  const SizedBox(height: 16),
                  HeldCallChip(call: held, onSwap: () => TelecomBridge.instance.unhold(held.id)),
                ],
              ],
            );
            if (ended) {
              return Center(
                child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: header),
              );
            }
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
                      child: ringing
                          ? _scrollArea(Column(mainAxisAlignment: MainAxisAlignment.center, children: [controls]))
                          : controls,
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
                          SizedBox(height: compact ? 4 : (constraints.maxHeight * 0.055).clamp(24.0, 48.0)),
                          header,
                          const SizedBox(height: 28),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  controls,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
