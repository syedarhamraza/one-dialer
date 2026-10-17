import 'package:flutter/material.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';

/// Glassy circle body for call actions and keypad keys: a soft top-lit gradient with a hairline
/// highlight, translucent so the caller's backdrop shows through. Painted, never blurred.
BoxDecoration callControlBody({bool pressed = false}) => BoxDecoration(
  shape: BoxShape.circle,
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: pressed ? const [Color(0x5CFFFFFF), Color(0x47FFFFFF)] : const [Color(0x2EFFFFFF), Color(0x1AFFFFFF)],
  ),
  border: Border.all(color: const Color(0x1AFFFFFF), width: .5),
);

/// An unavailable action: just an outline, so it reads as "not yet" rather than broken.
const _outlined = BoxDecoration(
  shape: BoxShape.circle,
  border: Border.fromBorderSide(BorderSide(color: Color(0x2EFFFFFF))),
);

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

/// Shared round action for the call controls and the persistent bottom row. Turning it on
/// grows a white fill out from the icon; unavailable actions show as an outline.
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
    final still = MediaQuery.disableAnimationsOf(context);
    final fast = still ? Duration.zero : const Duration(milliseconds: 180);
    final enabled = onPressed != null;
    final foreground = active ? const Color(0xFF111418) : (enabled ? Colors.white : const Color(0x73FFFFFF));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PressScale(
          enabled: enabled,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedContainer(duration: fast, decoration: enabled ? callControlBody() : _outlined),
                AnimatedScale(
                  scale: active ? 1 : 0,
                  duration: still ? Duration.zero : const Duration(milliseconds: 220),
                  curve: active ? Curves.easeOutBack : Curves.easeInCubic,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xEBFFFFFF),
                      boxShadow: [BoxShadow(color: Color(0x40FFFFFF), blurRadius: 18)],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: label,
                  isSelected: active,
                  iconSize: size * .36,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: const CircleBorder(),
                    side: BorderSide.none,
                    elevation: 0,
                  ),
                  onPressed: onPressed,
                  icon: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: foreground),
                    duration: fast,
                    builder: (context, color, _) => AnimatedSwitcher(
                      duration: fast,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: Tween(begin: .6, end: 1.0).animate(animation), child: child),
                      ),
                      child: Icon(icon, key: ValueKey(icon), color: color),
                    ),
                  ),
                ),
              ],
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
              style: TextStyle(fontSize: 12, height: 1.1, color: enabled ? Colors.white : const Color(0x73FFFFFF)),
            ),
          ),
        ),
      ],
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
