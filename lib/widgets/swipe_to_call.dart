import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/telecom/telecom_bridge.dart';
import '../theme/one_ui_theme.dart';
import 'place_call.dart';

/// Samsung's list-row swipe: right to call, left to message. The row snaps back.
class SwipeToCallOrMessage extends StatelessWidget {
  const SwipeToCallOrMessage({super.key, required this.number, required this.child, this.simId});

  final String number;

  /// SIM to call on; null uses the contact's SIM or asks (see [placeCall]).
  final String? simId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? ValueKey(number),
      background: const _Background(color: OneUITheme.accentGreen, icon: Icons.call_rounded, alignLeft: true),
      secondaryBackground: const _Background(
        color: OneUITheme.accentBlue,
        icon: Icons.message_rounded,
        alignLeft: false,
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          if (context.mounted) await placeCall(context, number, simId: simId);
        } else {
          await TelecomBridge.instance.sendSms(number);
        }
        return false;
      },
      child: ColoredBox(color: OneUITheme.surfaceCard, child: child),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.color, required this.icon, required this.alignLeft});

  final Color color;
  final IconData icon;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
