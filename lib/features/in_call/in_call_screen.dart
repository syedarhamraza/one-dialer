import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import 'incoming_controls.dart';

/// Samsung-style call screen: caller, SIM and HD, live status, the held call (tap to
/// swap), and either incoming swipe controls or the in-call controls and keypad.
class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  final _telecom = TelecomBridge.instance;
  List<SimCard> _sims = const [];
  bool _keypadOpen = false;
  String _dtmf = '';

  @override
  void initState() {
    super.initState();
    // This engine runs separately from the main UI, so it loads its own contacts and SIMs.
    ContactsRepository.instance.start();
    _telecom.getSims().then((s) {
      if (mounted) setState(() => _sims = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<CallSnapshot>(
          stream: _telecom.callState,
          builder: (context, snap) {
            final snapshot = snap.data ?? const CallSnapshot();
            final call = snapshot.primary;
            if (call == null) {
              _keypadOpen = false;
              _dtmf = '';
              return const Center(child: Text('Call ended', style: TextStyle(color: OneUITheme.textSecondary)));
            }
            final held = snapshot.calls.where((c) => c.id != call.id && c.state == CallState.holding).firstOrNull;
            final ringing = call.state == CallState.ringing;
            return ValueListenableBuilder(
              valueListenable: ContactsRepository.instance.contacts,
              builder: (context, _, _) => Column(
                children: [
                  const SizedBox(height: 16),
                  _CallBadges(call: call, sims: _sims),
                  const SizedBox(height: 28),
                  if (!_keypadOpen) ...[
                    _CallerAvatar(call: call),
                    const SizedBox(height: 20),
                  ],
                  _CallerName(call: call),
                  const SizedBox(height: 6),
                  _keypadOpen && _dtmf.isNotEmpty
                      ? Text(_dtmf, style: const TextStyle(fontSize: 22, letterSpacing: 2, color: OneUITheme.textSecondary))
                      : _CallStatus(call: call),
                  if (held != null && !ringing) ...[
                    const SizedBox(height: 16),
                    _HeldCallChip(call: held, onSwap: () => _telecom.unhold(held.id)),
                  ],
                  const Spacer(),
                  if (ringing)
                    IncomingControls(call: call)
                  else if (_keypadOpen)
                    _DtmfKeypad(
                      onDown: (d) {
                        HapticFeedback.lightImpact();
                        setState(() => _dtmf += d);
                        _telecom.playDtmf(call.id, d);
                      },
                      onUp: () => _telecom.stopDtmf(call.id),
                    )
                  else
                    _OngoingControls(
                      call: call,
                      audio: snapshot.audio,
                      callCount: snapshot.calls.length,
                      onKeypad: () => setState(() => _keypadOpen = true),
                    ),
                  if (!ringing) ...[
                    const SizedBox(height: 20),
                    _EndCallRow(
                      showHideKeypad: _keypadOpen,
                      onHideKeypad: () => setState(() => _keypadOpen = false),
                      onEnd: () {
                        HapticFeedback.mediumImpact();
                        _telecom.hangUp(call.id);
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "SIM 1 · HD · Wi-Fi Calling" line above the caller.
class _CallBadges extends StatelessWidget {
  const _CallBadges({required this.call, required this.sims});

  final CallInfo call;
  final List<SimCard> sims;

  @override
  Widget build(BuildContext context) {
    final sim = sims.length > 1 ? sims.where((s) => s.id == call.simId).firstOrNull : null;
    final parts = [?sim?.label, if (call.isHd) 'HD', if (call.isWifi) 'Wi-Fi Calling'];
    if (parts.isEmpty) return const SizedBox(height: 18);
    return Text(
      parts.join('  ·  '),
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
    );
  }
}

class _CallerAvatar extends StatelessWidget {
  const _CallerAvatar({required this.call});

  final CallInfo call;

  @override
  Widget build(BuildContext context) {
    if (call.isPrivate) {
      return Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(color: OneUITheme.surfacePill, shape: BoxShape.circle),
        child: const Icon(Icons.person_rounded, size: 64, color: OneUITheme.textSecondary),
      );
    }
    final contact = ContactsRepository.instance.contactFor(call.number ?? '');
    return LetterAvatar(name: callerName(call), photo: contact?.thumbnail, size: 120);
  }
}

/// Contact name if saved, else the network-provided name, else the number.
String callerName(CallInfo call) {
  if (call.isConference) return 'Conference call';
  if (call.isPrivate) return 'Private number';
  final number = call.number ?? '';
  return ContactsRepository.instance.nameFor(number) ??
      ((call.name?.trim().isNotEmpty ?? false) ? call.name!.trim() : (number.isEmpty ? 'Unknown' : number));
}

class _CallerName extends StatelessWidget {
  const _CallerName({required this.call});

  final CallInfo call;

  @override
  Widget build(BuildContext context) {
    final name = callerName(call);
    final number = call.number ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.6),
          ),
          if (name != number && number.isNotEmpty && !call.isPrivate && !call.isConference)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(number, style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class _CallStatus extends StatefulWidget {
  const _CallStatus({required this.call});

  final CallInfo call;

  @override
  State<_CallStatus> createState() => _CallStatusState();
}

class _CallStatusState extends State<_CallStatus> {
  late final Timer _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final start = call.connectTime;
    final text = switch (call.state) {
      CallState.active when start != null => _format(DateTime.now().difference(start)),
      CallState.active => 'Connected',
      CallState.dialing || CallState.connecting || CallState.newCall || CallState.selectPhoneAccount => 'Calling…',
      CallState.ringing => 'Incoming call',
      CallState.holding => 'On hold',
      CallState.disconnecting || CallState.disconnected => 'Call ended',
      CallState.unknown => '',
    };
    return Text(text, style: const TextStyle(fontSize: 16, color: OneUITheme.textSecondary));
  }

  static String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}

/// "On hold: Name — Swap" pill for the second call.
class _HeldCallChip extends StatelessWidget {
  const _HeldCallChip({required this.call, required this.onSwap});

  final CallInfo call;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OneUITheme.surfacePill,
      borderRadius: OneUITheme.pillBorderRadius,
      child: InkWell(
        borderRadius: OneUITheme.pillBorderRadius,
        onTap: onSwap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_rounded, size: 18, color: OneUITheme.textSecondary),
              const SizedBox(width: 8),
              Text('On hold: ${callerName(call)}', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              const Text('Swap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OneUITheme.accentBlue)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OngoingControls extends StatelessWidget {
  const _OngoingControls({
    required this.call,
    required this.audio,
    required this.callCount,
    required this.onKeypad,
  });

  final CallInfo call;
  final AudioInfo audio;
  final int callCount;
  final VoidCallback onKeypad;

  @override
  Widget build(BuildContext context) {
    final telecom = TelecomBridge.instance;
    final hasBluetooth = audio.supportedRoutes.contains(AudioRoute.bluetooth);
    final onHold = call.state == CallState.holding;
    final (routeIcon, routeLabel) = switch (audio.route) {
      AudioRoute.bluetooth => (Icons.bluetooth_audio_rounded, 'Bluetooth'),
      AudioRoute.wiredHeadset => (Icons.headset_rounded, 'Headset'),
      AudioRoute.speaker => (Icons.volume_up_rounded, 'Speaker'),
      AudioRoute.earpiece => (Icons.volume_up_rounded, 'Speaker'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Toggle(
                icon: routeIcon,
                label: routeLabel,
                active: audio.route != AudioRoute.earpiece,
                onPressed: hasBluetooth
                    ? () => _chooseRoute(context, audio)
                    : () => telecom.setAudioRoute(
                          audio.route == AudioRoute.speaker ? AudioRoute.earpiece : AudioRoute.speaker,
                        ),
              ),
              _Toggle(
                icon: audio.muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                label: 'Mute',
                active: audio.muted,
                onPressed: () => telecom.setMuted(!audio.muted),
              ),
              _Toggle(icon: Icons.dialpad_rounded, label: 'Keypad', active: false, onPressed: onKeypad),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Toggle(icon: Icons.add_call, label: 'Add call', active: false, onPressed: telecom.openDialer),
              _Toggle(
                icon: Icons.pause_rounded,
                label: onHold ? 'Resume' : 'Hold',
                active: onHold,
                onPressed: call.canHold || onHold
                    ? () => onHold ? telecom.unhold(call.id) : telecom.hold(call.id)
                    : null,
              ),
              _Toggle(
                icon: Icons.call_merge_rounded,
                label: 'Merge',
                active: false,
                onPressed: callCount > 1 && call.canMerge ? () => telecom.merge(call.id) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _chooseRoute(BuildContext context, AudioInfo audio) async {
    final route = await showModalBottomSheet<AudioRoute>(
      context: context,
      backgroundColor: OneUITheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(OneUITheme.radiusCard)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Audio output', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final r in audio.supportedRoutes)
              ListTile(
                leading: Icon(switch (r) {
                  AudioRoute.earpiece => Icons.phone_in_talk_rounded,
                  AudioRoute.speaker => Icons.volume_up_rounded,
                  AudioRoute.bluetooth => Icons.bluetooth_audio_rounded,
                  AudioRoute.wiredHeadset => Icons.headset_rounded,
                }),
                title: Text(switch (r) {
                  AudioRoute.earpiece => 'Phone',
                  AudioRoute.speaker => 'Speaker',
                  AudioRoute.bluetooth => 'Bluetooth',
                  AudioRoute.wiredHeadset => 'Wired headset',
                }),
                trailing: r == audio.route ? const Icon(Icons.check_rounded, color: OneUITheme.accentBlue) : null,
                onTap: () => Navigator.of(context).pop(r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (route != null) await TelecomBridge.instance.setAudioRoute(route);
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.label, required this.active, required this.onPressed});

  final IconData icon;
  final String label;
  final bool active;

  /// null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 64,
            child: IconButton(
              tooltip: label,
              isSelected: active,
              iconSize: 28,
              style: IconButton.styleFrom(
                backgroundColor: active ? OneUITheme.textPrimary : OneUITheme.surfacePill,
                foregroundColor: active ? OneUITheme.surfacePitch : OneUITheme.textPrimary,
                disabledBackgroundColor: OneUITheme.surfaceCard,
                disabledForegroundColor: OneUITheme.textTertiary,
              ),
              onPressed: onPressed,
              icon: Icon(icon),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: enabled ? OneUITheme.textSecondary : OneUITheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Touch-tone keypad during a call: the tone plays while the key is held.
class _DtmfKeypad extends StatelessWidget {
  const _DtmfKeypad({required this.onDown, required this.onUp});

  final ValueChanged<String> onDown;
  final VoidCallback onUp;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              children: [
                for (final k in _keys.sublist(row * 3, row * 3 + 3))
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: k,
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => onDown(k),
                        onTapUp: (_) => onUp(),
                        onTapCancel: onUp,
                        child: SizedBox(
                          height: 64,
                          child: Center(child: Text(k, style: const TextStyle(fontSize: 30))),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EndCallRow extends StatelessWidget {
  const _EndCallRow({required this.showHideKeypad, required this.onHideKeypad, required this.onEnd});

  final bool showHideKeypad;
  final VoidCallback onHideKeypad;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        SizedBox.square(
          dimension: 72,
          child: IconButton.filled(
            tooltip: 'End call',
            style: IconButton.styleFrom(backgroundColor: OneUITheme.accentRed),
            iconSize: 32,
            onPressed: onEnd,
            icon: const Icon(Icons.call_end_rounded, color: Colors.white),
          ),
        ),
        Expanded(
          child: showHideKeypad
              ? TextButton(onPressed: onHideKeypad, child: const Text('Hide'))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
