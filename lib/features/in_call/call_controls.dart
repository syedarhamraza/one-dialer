import 'package:flutter/material.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';

const callControlFill = Color(0xFF344850);

/// Shared flat circle for actions and the persistent bottom row.
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
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(
        dimension: size,
        child: IconButton(
          tooltip: label,
          isSelected: active,
          iconSize: 27,
          style: IconButton.styleFrom(
            backgroundColor: active ? Colors.white : callControlFill,
            foregroundColor: active ? const Color(0xFF183139) : Colors.white,
            disabledBackgroundColor: callControlFill,
            disabledForegroundColor: Colors.white38,
            shape: const CircleBorder(),
            side: BorderSide.none,
            elevation: 0,
          ),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 40,
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, height: 1.1, color: onPressed != null ? Colors.white : Colors.white38),
        ),
      ),
    ],
  );
}

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
