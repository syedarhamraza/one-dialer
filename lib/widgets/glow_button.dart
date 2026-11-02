import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

import '../features/in_call/call_controls.dart';
import 'call_glass.dart';
import 'press_glow.dart';

/// The app's own big button, as the keypad's Call: lit (a shaded [color] body with its glow,
/// light rising from below) or, with [lit] false, the call glass drawn from a cached image.
/// Presses with [PressGlow]'s glow and stretch. While [busy] it shows [busyLabel] and a band of
/// light sweeps across it (still, with reduced motion).
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = answerGreen,
    this.lit = true,
    this.busy = false,
    this.busyLabel,
    this.height = 54,
    this.width,
    this.fontSize = 17,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool lit;
  final bool busy;

  /// Shown (and read) while [busy], e.g. "Checking…".
  final String? busyLabel;
  final double height;

  /// Null hugs the label.
  final double? width;
  final double fontSize;

  static const _pill = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    final ink = Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              widthFactor: 1,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  busy ? busyLabel ?? label : label,
                  key: ValueKey((busy, label)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: lit ? Colors.white : context.palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final body = busy
        ? Stack(
            children: [
              ink,
              const Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(borderRadius: _pill, child: _Sheen()),
                ),
              ),
            ],
          )
        : ink;
    return Semantics(
      button: true,
      enabled: onTap != null && !busy,
      label: busy ? busyLabel ?? label : label,
      excludeSemantics: true,
      child: lit
          ? LitButton(color: color, shape: const StadiumBorder(), child: body)
          : ListenableBuilder(
              listenable: OneUIEffectsController.instance,
              builder: (context, body) {
                final full = OneUIEffectsController.instance.isFull;
                // Below full visual effects: a flat One UI pill with no shadows.
                return PressGlow(
                  shadows: context.palette.isLight && full ? OneUIPalette.lightGlassShadow : null,
                  child: full
                      ? CallBodyArtwork(
                          radius: height / 2,
                          glow: kMainGlassGlow,
                          opacity: mainGlass(context).opacity,
                          edges: mainGlass(context).edges,
                          child: body!,
                        )
                      : DecoratedBox(
                          decoration: ShapeDecoration(
                            color: OneUIEffectsController.instance.oneUIFill(light: context.palette.isLight),
                            shape: const StadiumBorder(),
                          ),
                          child: body,
                        ),
                );
              },
              child: body,
            ),
    );
  }
}

/// A soft band of light sweeping across a busy button, left to right, every 1.4 s.
class _Sheen extends StatefulWidget {
  const _Sheen();

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final band = box.maxWidth * .45;
        return AnimatedBuilder(
          animation: _sweep,
          builder: (context, child) {
            final t = Curves.easeInOutSine.transform(_sweep.value);
            return Transform.translate(offset: Offset(-band + t * (box.maxWidth + band), 0), child: child);
          },
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: band,
              height: double.infinity,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)],
                    stops: [0, .5, 1],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
