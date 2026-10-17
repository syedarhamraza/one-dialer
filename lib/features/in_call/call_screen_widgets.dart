import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../widgets/letter_avatar.dart';

/// A static call backdrop: depth without a full-screen blur or an idle animation.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202638), Color(0xFF244A50), Color(0xFF12262F)],
          ),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.9, -0.8),
            radius: 1.2,
            colors: [Color(0x665E5078), Colors.transparent],
          ),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x10000000), Color(0x88070F17)],
          ),
        ),
      ),
      child,
    ],
  );
}

String callerName(CallInfo call) {
  if (call.isConference) return 'Conference call';
  if (call.isPrivate) return 'Private number';
  final number = call.number ?? '';
  return ContactsRepository.instance.nameFor(number) ??
      ((call.name?.trim().isNotEmpty ?? false) ? call.name!.trim() : (number.isEmpty ? 'Unknown' : number));
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
    final sim = sims.where((s) => s.id == call.simId).firstOrNull;
    final contact = call.isPrivate || call.isConference ? null : ContactsRepository.instance.contactFor(number);
    final avatarSize = (compact ? 80.0 : 112.0) * (1 - keypadProgress) + 64 * keypadProgress;
    double spacing(double regular, double small) =>
        (compact ? small : regular) * (1 - keypadProgress) + small * keypadProgress;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _Badge(icon: Icons.sim_card_outlined, label: sim?.label ?? 'Phone call'),
            if (call.isHd) const _Badge(label: 'HD'),
            if (call.isWifi) const _Badge(icon: Icons.wifi_rounded, label: 'Wi-Fi Calling'),
          ],
        ),
        SizedBox(height: spacing(28, 12)),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: call.isPrivate || call.isConference
              ? CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  child: Icon(
                    call.isConference ? Icons.groups_rounded : Icons.person_rounded,
                    size: avatarSize * 0.48,
                    color: Colors.white70,
                  ),
                )
              : LetterAvatar(name: name, photo: contact?.thumbnail, size: avatarSize),
        ),
        SizedBox(height: spacing(22, 12)),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: spacing(34, 28),
            height: 1.15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            color: Colors.white,
          ),
        ),
        if (name != number && number.isNotEmpty && !call.isPrivate && !call.isConference) ...[
          const SizedBox(height: 8),
          Text(
            number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
        const SizedBox(height: 12),
        CallStatus(call: call),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: Colors.white70), const SizedBox(width: 6)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
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

class _CallStatusState extends State<CallStatus> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(CallStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.state != widget.call.state || oldWidget.call.connectTime != widget.call.connectTime) {
      _syncTicker();
    }
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = widget.call.state == CallState.active && widget.call.connectTime != null
        ? Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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
      CallState.disconnecting || CallState.disconnected => 'Call ended',
      CallState.unknown => 'Phone call',
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: call.state == CallState.active ? const Color(0xFFB5E8D1) : Colors.white70,
        fontFeatures: const [FontFeature.tabularFigures()],
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
    color: Colors.white.withValues(alpha: 0.10),
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
