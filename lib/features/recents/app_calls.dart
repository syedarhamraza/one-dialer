/// Calls that VoIP apps (WhatsApp...) share with the call log on Android 16.1+.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/place_call.dart';
import '../../l10n/l10n.dart';
import '../../widgets/one_ui_floating_menu.dart';
import 'call_log.dart';

/// "WhatsApp" or "WhatsApp video", where SIM calls show the number.
String appCallLabel(AppLocalizations l10n, CallLogEntry call) =>
    call.isVideo ? l10n.appVideo(call.app ?? '') : call.app ?? '';

/// A one-item menu so a tap never calls by accident; its Call hands the call back to the app.
Future<void> showAppCallBack(
  BuildContext context,
  CallLogEntry call, {
  GlobalKey? anchorKey,
  BuildContext? anchorContext,
}) => OneUIFloatingMenu.show(
  context: context,
  anchorKey: anchorKey,
  anchorContext: anchorContext,
  centered: true,
  fallbackBottom: 120,
  width: 240,
  items: [
    OneUIFloatingMenuItem(
      label: call.isVideo ? context.l10n.videoCallOnApp(call.app ?? '') : context.l10n.callOnApp(call.app ?? ''),
      icon: call.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
      onTap: () => callBackRow(context, call.id),
    ),
  ],
);

/// [child] (an avatar) with [package]'s app icon on its bottom-right corner; just [child] for SIM calls.
class AppBadged extends StatelessWidget {
  const AppBadged({super.key, required this.package, required this.child, this.size = 20});

  final String? package;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final package = this.package;
    if (package == null) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -3,
          bottom: -3,
          child: FutureBuilder<Uint8List?>(
            future: TelecomBridge.instance.appIcon(package),
            builder: (context, snap) {
              final png = snap.data;
              if (png == null) return const SizedBox.shrink();
              // A ring in the page colour cuts the badge out of the avatar, like ColorOS's badges.
              return Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.memory(
                    png,
                    width: size,
                    height: size,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
