import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/glow_button.dart';
import '../in_call/call_controls.dart';
import '../../l10n/l10n.dart';

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
          // ColorOS 17's glass ribbon (as on Software update) up top, fading into the page above the text.
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
                      Text(
                        context.l10n.setupTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.setupBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: context.palette.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 40),
                      GlowButton(
                        label: context.l10n.setAsDefault,
                        busy: _asking,
                        busyLabel: context.l10n.settingUp,
                        width: double.infinity,
                        height: 56,
                        onTap: _asking ? null : _becomeDefault,
                      ),
                      const SizedBox(height: 24),
                      // Prominent disclosure (Google Play): what each permission is used for.
                      Text(
                        context.l10n.setupDisclosure,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: context.palette.textSecondary, height: 1.4),
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
        // A green glow on black; on white it would be a halo, so a soft shadow instead.
        boxShadow: context.palette.isLight
            ? [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 24, offset: const Offset(0, 8))]
            : [BoxShadow(color: answerGreen.withValues(alpha: .35), blurRadius: 40)],
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
