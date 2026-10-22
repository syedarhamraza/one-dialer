import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// Samsung One UI Status Bar Scrim (Edge-to-Edge Progressive Blur & Gradient Scrim).
///
/// Prevents scrolling cards and text from clashing with the white system status bar
/// icons (clock, battery, Wi-Fi).
/// Extends gracefully past the status bar (topPadding + 20px) with a multi-stop OLED
/// gradient and progressive backdrop blur to ensure fluid, seamless dissolution.
class OneUIStatusBarScrim extends StatelessWidget {
  final double? height;
  final bool isVisible;

  const OneUIStatusBarScrim({super.key, this.height, this.isVisible = true});

  static const LinearGradient topGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFA000000), // ~98% OLED black over system clock & battery
      Color(0xEB000000), // ~92% OLED black
      Color(0x9E000000), // ~62% dark feathering at status bar threshold
      Color(0x45000000), // ~27% subtle fade
      Color(0x12000000), // ~7% subtle fade
      Colors.transparent, // 0%
    ],
    stops: [0.0, 0.35, 0.60, 0.78, 0.92, 1.0],
  );

  static const LinearGradient blurMask = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.black, Colors.black, Color(0x80000000), Colors.transparent],
    stops: [0.0, 0.40, 0.75, 1.0],
  );

  /// [topGradient] multiplied by [blurMask], as the ShaderMask drew it.
  static const LinearGradient maskedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFA000000),
      Color(0xEB000000),
      Color(0xDC000000),
      Color(0x71000000),
      Color(0x2A000000),
      Color(0x1E000000),
      Color(0x03000000),
      Colors.transparent,
    ],
    stops: [0.0, 0.35, 0.40, 0.60, 0.75, 0.78, 0.92, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final isEnabled = isVisible;
        if (!isEnabled) return const SizedBox.shrink();

        final topPadding = MediaQuery.of(context).padding.top;
        final scrimHeight = height ?? (topPadding > 0 ? topPadding + 20.0 : 48.0);

        return IgnorePointer(
          child: SizedBox(
            height: scrimHeight,
            width: double.infinity,
            // No ShaderMask (a full-width save layer every frame): the blur covers the top 60%
            // with a hard edge instead of fading out, and the gradient carries the mask's fade.
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: scrimHeight * 0.6,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: maskedGradient)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
