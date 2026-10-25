import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/glow_button.dart';
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
    await Permission.bluetoothConnect.request(); // names the watch and earbuds in a call's audio menu
    if (mounted) setState(() => _asking = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Stack(
        children: [
          // ColorOS 17's glass ribbon (as on Software update) up top, fading into black above the text.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: MediaQuery.sizeOf(context).height * .55,
            child: const CosArtwork(fadeToBlack: .45),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const OneUIScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Needed to make and answer calls, show your call history and contacts, and block numbers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: OneUITheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 40),
                      GlowButton(
                        label: 'Set as default',
                        busy: _asking,
                        busyLabel: 'Setting up…',
                        width: double.infinity,
                        height: 56,
                        onTap: _asking ? null : _becomeDefault,
                      ),
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
        ],
      ),
    );
  }
}

/// The launcher icon itself (the adaptive icon's layers, cropped to its visible middle 72 of
/// 108 dp) in a ColorOS squircle.
class _AppIcon extends StatelessWidget {
  const _AppIcon();

  static const _res = 'android/app/src/main/res/drawable-nodpi';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: answerGreen.withValues(alpha: .35), blurRadius: 40)],
      ),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox.square(
          dimension: 104,
          child: Transform.scale(
            scale: 1.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('$_res/ic_launcher_background.png'),
                Image.asset('$_res/ic_launcher_foreground.png'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
