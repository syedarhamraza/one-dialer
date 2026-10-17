import 'package:flutter/material.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';

/// Translucent so the caller's backdrop shows through.
const callControlFill = Color(0x24FFFFFF);
const callControlActive = Color(0xEBFFFFFF);

/// Shrinks slightly under the finger, like stock dialer buttons.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true, this.scale = .92});
  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _set(true) : null,
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Shared round action for the call controls and the persistent bottom row.
class CallAction extends StatelessWidget {
  const CallAction({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    required this.onPressed,
    this.size = 60,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fast = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180);
    return AnimatedOpacity(
      opacity: onPressed == null ? .4 : 1,
      duration: fast,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PressScale(
            enabled: onPressed != null,
            child: SizedBox.square(
              dimension: size,
              child: IconButton(
                tooltip: label,
                isSelected: active,
                iconSize: size * .36,
                style: IconButton.styleFrom(
                  backgroundColor: active ? callControlActive : callControlFill,
                  foregroundColor: active ? const Color(0xFF111418) : Colors.white,
                  disabledBackgroundColor: callControlFill,
                  disabledForegroundColor: Colors.white,
                  shape: const CircleBorder(),
                  side: BorderSide.none,
                  elevation: 0,
                  animationDuration: fast,
                ),
                onPressed: onPressed,
                icon: AnimatedSwitcher(
                  duration: fast,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: Tween(begin: .6, end: 1.0).animate(animation), child: child),
                  ),
                  child: Icon(icon, key: ValueKey(icon)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: AnimatedSwitcher(
              duration: fast,
              child: Text(
                label,
                key: ValueKey(label),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.1, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String audioRouteLabel(AudioRoute route) => switch (route) {
  AudioRoute.earpiece => 'Phone',
  AudioRoute.speaker => 'Speaker',
  AudioRoute.bluetooth => 'Bluetooth',
  AudioRoute.wiredHeadset => 'Wired headset',
};

Future<void> chooseCallAudioRoute(BuildContext context, AudioInfo audio) async {
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
              title: Text(audioRouteLabel(route)),
              trailing: route == audio.route ? const Icon(Icons.check_rounded, color: Color(0xFFB5E8D1)) : null,
              onTap: () => Navigator.of(context).pop(route),
            ),
        ],
      ),
    ),
  );
  if (route != null && context.mounted) await TelecomBridge.instance.setAudioRoute(route);
}
