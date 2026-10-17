import 'package:flutter/material.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';

class CallActionGrid extends StatelessWidget {
  const CallActionGrid({
    super.key,
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
      AudioRoute.speaker || AudioRoute.earpiece => (Icons.volume_up_rounded, 'Speaker'),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CallAction(
                icon: routeIcon,
                label: routeLabel,
                active: audio.route != AudioRoute.earpiece,
                onPressed: hasBluetooth
                    ? () => _chooseRoute(context, audio)
                    : () => telecom.setAudioRoute(
                        audio.route == AudioRoute.speaker ? AudioRoute.earpiece : AudioRoute.speaker,
                      ),
              ),
            ),
            Expanded(
              child: _CallAction(
                icon: audio.muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                label: 'Mute',
                active: audio.muted,
                onPressed: () => telecom.setMuted(!audio.muted),
              ),
            ),
            Expanded(
              child: _CallAction(icon: Icons.dialpad_rounded, label: 'Keypad', onPressed: onKeypad),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CallAction(icon: Icons.add_call, label: 'Add call', onPressed: telecom.openDialer),
            ),
            Expanded(
              child: _CallAction(
                icon: Icons.pause_rounded,
                label: onHold ? 'Resume' : 'Hold',
                active: onHold,
                onPressed: call.canHold || onHold
                    ? () => onHold ? telecom.unhold(call.id) : telecom.hold(call.id)
                    : null,
              ),
            ),
            Expanded(
              child: _CallAction(
                icon: Icons.call_merge_rounded,
                label: 'Merge',
                onPressed: callCount > 1 && call.canMerge ? () => telecom.merge(call.id) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _chooseRoute(BuildContext context, AudioInfo audio) async {
    final route = await OneUIFloatingModal.show<AudioRoute>(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Audio output', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            for (final route in audio.supportedRoutes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(switch (route) {
                  AudioRoute.earpiece => Icons.phone_in_talk_rounded,
                  AudioRoute.speaker => Icons.volume_up_rounded,
                  AudioRoute.bluetooth => Icons.bluetooth_audio_rounded,
                  AudioRoute.wiredHeadset => Icons.headset_rounded,
                }),
                title: Text(switch (route) {
                  AudioRoute.earpiece => 'Phone',
                  AudioRoute.speaker => 'Speaker',
                  AudioRoute.bluetooth => 'Bluetooth',
                  AudioRoute.wiredHeadset => 'Wired headset',
                }),
                trailing: route == audio.route ? const Icon(Icons.check_rounded, color: Color(0xFFB5E8D1)) : null,
                onTap: () => Navigator.of(context).pop(route),
              ),
          ],
        ),
      ),
    );
    if (route != null && context.mounted) await TelecomBridge.instance.setAudioRoute(route);
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({required this.icon, required this.label, this.active = false, required this.onPressed});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(
        dimension: 60,
        child: IconButton(
          tooltip: label,
          isSelected: active,
          iconSize: 27,
          style: IconButton.styleFrom(
            backgroundColor: active ? Colors.white : Colors.transparent,
            foregroundColor: active ? const Color(0xFF183139) : Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white38,
            side: BorderSide.none,
            elevation: 0,
          ),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: onPressed != null ? Colors.white : Colors.white38),
        ),
      ),
    ],
  );
}

/// Keeps tones tied to the call that received the key-down, including cancellation.
class CallDtmfKeypad extends StatefulWidget {
  const CallDtmfKeypad({super.key, required this.callId, required this.onDigit});
  final String callId;
  final ValueChanged<String> onDigit;

  @override
  State<CallDtmfKeypad> createState() => _CallDtmfKeypadState();
}

class _CallDtmfKeypadState extends State<CallDtmfKeypad> {
  String? _tone;
  static const _keys = [
    ('1', ''),
    ('2', 'ABC'),
    ('3', 'DEF'),
    ('4', 'GHI'),
    ('5', 'JKL'),
    ('6', 'MNO'),
    ('7', 'PQRS'),
    ('8', 'TUV'),
    ('9', 'WXYZ'),
    ('*', ''),
    ('0', '+'),
    ('#', ''),
  ];

  void _down(String digit) {
    _up();
    _tone = digit;
    widget.onDigit(digit);
    TelecomBridge.instance.playDtmf(widget.callId, digit);
  }

  void _up() {
    if (_tone == null) return;
    _tone = null;
    TelecomBridge.instance.stopDtmf(widget.callId);
  }

  @override
  void dispose() {
    _up();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var row = 0; row < 4; row++)
        Row(
          children: [
            for (final (digit, letters) in _keys.sublist(row * 3, row * 3 + 3))
              Expanded(
                child: Semantics(
                  button: true,
                  label: digit,
                  excludeSemantics: true,
                  onTap: () {
                    _down(digit);
                    _up();
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _down(digit),
                    onTapUp: (_) => _up(),
                    onTapCancel: _up,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(digit, style: const TextStyle(fontSize: 30, height: 1.1, color: Colors.white)),
                          Text(
                            letters.isEmpty ? ' ' : letters,
                            style: const TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}

class EndCallBar extends StatelessWidget {
  const EndCallBar({super.key, required this.onEnd, this.onHideKeypad});
  final VoidCallback onEnd;
  final VoidCallback? onHideKeypad;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: 16,
      bottom:
          MediaQuery.sizeOf(context).height > MediaQuery.sizeOf(context).width &&
              MediaQuery.sizeOf(context).height >= 700
          ? (MediaQuery.sizeOf(context).height * 0.07).clamp(28.0, 64.0)
          : 16,
    ),
    child: Row(
      children: [
        const Spacer(),
        SizedBox.square(
          dimension: 76,
          child: IconButton.filled(
            tooltip: 'End call',
            iconSize: 34,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFEE5265), foregroundColor: Colors.white),
            onPressed: onEnd,
            icon: const Icon(Icons.call_end_rounded),
          ),
        ),
        Expanded(
          child: onHideKeypad == null
              ? const SizedBox()
              : Center(
                  child: IconButton(
                    tooltip: 'Hide keypad',
                    onPressed: onHideKeypad,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
                  ),
                ),
        ),
      ],
    ),
  );
}
