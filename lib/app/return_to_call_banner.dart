import 'package:flutter/material.dart';

import '../core/telecom/call_info.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/in_call/call_screen_widgets.dart';
import '../theme/one_ui_theme.dart';
import '../features/in_call/call_controls.dart';
import '../widgets/press_glow.dart';

/// Green pill under the status bar while a call is ongoing; tapping it brings the
/// in-call screen back. Ringing calls have their own full-screen notification.
class ReturnToCallBanner extends StatelessWidget {
  const ReturnToCallBanner({super.key});

  static const _ongoing = {CallState.active, CallState.holding, CallState.dialing, CallState.connecting};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallSnapshot>(
      stream: TelecomBridge.instance.callState,
      builder: (context, snapshot) {
        final calls = (snapshot.data?.calls ?? const <CallInfo>[]).where((c) => _ongoing.contains(c.state));
        final call = calls.where((c) => c.state == CallState.active).firstOrNull ?? calls.firstOrNull;
        return AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, alignment: Alignment.topCenter, child: child),
          ),
          child: call == null ? const SizedBox.shrink() : _Pill(key: const ValueKey('call'), call: call),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.call});
  final CallInfo call;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 8, left: 16, right: 16),
      child: Center(
        child: Semantics(
          button: true,
          label: 'Return to call',
          excludeSemantics: true,
          // Lit and pressed like the keypad's Call button.
          child: PressGlow(
            glowColor: OneUITheme.accentGreen,
            child: Container(
              decoration: solidBody(OneUITheme.accentGreen, const StadiumBorder()),
              foregroundDecoration: solidGlow(const StadiumBorder()),
              child: Material(
                color: Colors.transparent,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: TelecomBridge.instance.showInCallScreen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            callerName(call),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // CallStatus tints its text for the dark call screen; force white on green.
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          child: CallStatus(call: call),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
