import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/haptics/haptics.dart';
import '../../core/security/app_lock.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/cos_artwork.dart';
import '../setup/setup_screen.dart';

/// Covers the whole app while [AppLock.locked]: pushed on top of every page, so whatever was
/// open is still there after unlocking. Asks right away; Back leaves the app.
///
/// Covering is instant (the app must never show on the way back); unlocking grows the lock
/// screen slightly as it fades into the app.
class LockRoute extends PageRouteBuilder<void> {
  LockRoute()
    : super(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => const LockScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final eased = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(eased), child: child),
          );
        },
      );
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  bool _asking = false;

  /// The fingerprint's halo: breathes in and out, inviting a touch.
  late final _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400), value: .5);

  @override
  void initState() {
    super.initState();
    // After the first frame back in front: a lock pushed while leaving waits until then.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _breathe();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  /// Still while the prompt is up, with reduced motion, or with effects Off.
  void _breathe() {
    final still = _asking || MediaQuery.disableAnimationsOf(context) || OneUIEffectsController.instance.isOff;
    if (still) {
      _breath
        ..stop()
        ..value = .5;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  Future<void> _unlock() async {
    if (_asking || !mounted || !AppLock.instance.locked.value) return;
    setState(() => _asking = true);
    _breathe();
    final ok = await AppLock.instance.unlock(context.l10n.unlockOneDialer);
    if (ok) Haptics.confirm();
    if (!mounted) return;
    setState(() => _asking = false);
    _breathe();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: palette.page,
        body: AnimatedBuilder(
          animation: OneUIEffectsController.instance,
          builder: (context, _) {
            final off = OneUIEffectsController.instance.isOff;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _breathe();
            });
            return Stack(
              children: [
                // The About page's silk, fading into the page below the icon (a cached image, no blur).
                if (!off) const Positioned.fill(child: CosArtwork(fadeToBlack: .5, waveShift: .08, dim: .2)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          const Spacer(flex: 5),
                          const AppIcon(),
                          const SizedBox(height: 28),
                          Text(
                            l10n.appLocked,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.appLockedHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, height: 1.35, color: palette.textSecondary),
                          ),
                          const Spacer(flex: 9),
                        ],
                      ),
                    ),
                  ),
                ),
                // Where phones put the in-display fingerprint sensor: low and centered.
                Align(
                  alignment: const Alignment(0, .72),
                  child: SizedBox.square(
                    dimension: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RepaintBoundary(child: _Halo(breath: _breath)),
                        Semantics(button: true, label: l10n.unlock, child: _fingerprint(context, off)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fingerprint(BuildContext context, bool off) {
    final button = Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Haptics.tap();
          _unlock();
        },
        child: SizedBox.square(
          dimension: 80,
          child: AnimatedOpacity(
            opacity: _asking ? .45 : 1,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.fingerprint_rounded, size: 46, color: OneUITheme.callGreen),
          ),
        ),
      ),
    );
    // Effects Off: a solid circle, like the rest of the app at that level.
    if (off) {
      return DecoratedBox(
        decoration: BoxDecoration(color: context.palette.card, shape: BoxShape.circle),
        child: button,
      );
    }
    return CallGlass(radius: 40, child: button);
  }
}

/// A soft green glow behind the fingerprint, scaling .85 → 1.1 and fading .35 → .1 with
/// [breath]: a gradient, not a blur, so it costs no backdrop read.
class _Halo extends StatelessWidget {
  const _Halo({required this.breath});

  final Animation<double> breath;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: breath,
    builder: (context, child) {
      final t = Curves.easeInOut.transform(breath.value);
      return Transform.scale(
        scale: .85 + .25 * t,
        child: Opacity(opacity: .35 - .25 * t, child: child),
      );
    },
    child: const DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [OneUITheme.callGreen, Color(0x0000C216)], stops: [.35, 1]),
      ),
      child: SizedBox.expand(),
    ),
  );
}
