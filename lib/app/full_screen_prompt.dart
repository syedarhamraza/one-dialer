import 'package:flutter/material.dart';

import '../core/telecom/telecom_bridge.dart';
import '../l10n/l10n.dart';
import '../widgets/cos_dialog.dart';

bool _asked = false;

/// Once per app start, while One Dialer is the default phone app but can't show full-screen
/// notifications, asks to allow them: without them incoming calls only land in the notification
/// shade, never popping up (vivo leaves them off for a new default phone app).
Future<void> askForFullScreen(BuildContext context) async {
  if (_asked) return;
  _asked = true;
  final health = await TelecomBridge.instance.getCallHealth();
  if (health['isDefaultDialer'] != true || health['fullScreenAllowed'] != false || !context.mounted) return;
  final allow = await showCosConfirm(
    context,
    title: context.l10n.fullScreenOff,
    message: context.l10n.fullScreenAsk,
    cancelLabel: context.l10n.notNow,
    confirmLabel: context.l10n.allow,
  );
  if (allow) await TelecomBridge.instance.openSystemSettings('fullScreen');
}
