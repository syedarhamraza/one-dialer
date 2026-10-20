import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/press_glow.dart';
import '../in_call/call_controls.dart';

/// Shown while One Dialer isn't the default phone app (first run, or after another app took the
/// role): without it Android grants no calls, call log or contacts, so there's nothing to skip to.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onDone});

  /// Called after the role prompt; the caller re-checks whether it was granted.
  final VoidCallback onDone;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _asking = false;

  Future<void> _becomeDefault() async {
    setState(() => _asking = true);
    await TelecomBridge.instance.requestDefaultDialer();
    // The role grants phone, contacts and call log; notifications still need asking.
    await Permission.notification.request();
    if (mounted) setState(() => _asking = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const OneUIScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 1 : 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.scale(scale: .9 + .1 * t, child: child),
                    ),
                    child: const _AppIcon(),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Set One Dialer as your default phone app',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Needed to make and answer calls, show your call history and contacts, and block numbers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: OneUITheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 40),
                  _SetButton(asking: _asking, onTap: _asking ? null : _becomeDefault),
                  const SizedBox(height: 24),
                  // Prominent disclosure (Google Play): what each permission is used for.
                  const Text(
                    'One Dialer uses Phone to make and manage calls on your SIMs, Call history for Recents '
                    'and missed calls, Contacts for names, photos and search, and Notifications for incoming, '
                    'ongoing and missed calls. Your calls, call history and contacts never leave your phone. '
                    'Crash reports (no personal data) help fix bugs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: OneUITheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's green phone icon, lit like the call screen's Answer button.
class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28)));
    return Container(
      width: 96,
      height: 96,
      decoration: solidBody(answerGreen, shape, glow: .45, blur: 40),
      foregroundDecoration: solidGlow(shape),
      child: const Icon(Icons.call_rounded, color: Colors.white, size: 76),
    );
  }
}

/// The keypad's lit green pill (`_Pill` in `keypad_screen.dart`), full width.
class _SetButton extends StatelessWidget {
  const _SetButton({required this.asking, required this.onTap});

  final bool asking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Set as default',
      enabled: onTap != null,
      excludeSemantics: true,
      child: PressGlow(
        glowColor: answerGreen,
        child: Container(
          decoration: solidBody(answerGreen, const StadiumBorder(), glow: 0),
          foregroundDecoration: solidGlow(const StadiumBorder()),
          child: Material(
            color: Colors.transparent,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.white.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.15),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: Center(
                  child: asking
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Set as default',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
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
