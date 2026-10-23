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

  /// ColorOS 17's header tint: dark enough under the status bar icons, gone by the bottom.
  static const LinearGradient topGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC000000), Color(0x8C000000), Color(0x33000000), Colors.transparent],
    stops: [0.0, 0.4, 0.75, 1.0],
  );

  /// Fades the blur out (shaders/progressive_blur.frag). A ShaderMask can't: around a
  /// BackdropFilter it cuts the blur off from the backdrop.
  static final Future<FragmentShader?> _fade = ImageFilter.isShaderFilterSupported
      ? FragmentProgram.fromAsset('shaders/progressive_blur.frag')
            .then<FragmentShader?>((program) => program.fragmentShader(), onError: (_) => null)
      : Future.value(null);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final isEnabled = isVisible;
        if (!isEnabled) return const SizedBox.shrink();

        final topPadding = MediaQuery.of(context).padding.top;
        // Covers the round Back button row (8 + 48) and fades out 24 below it.
        final scrimHeight = height ?? topPadding + 80.0;

        return IgnorePointer(
          child: SizedBox(
            height: scrimHeight,
            width: double.infinity,
            child: FutureBuilder(
              future: _fade,
              builder: (context, fade) {
                // A light blur everywhere; the shader adds up to sigma 12 more toward the top.
                final blur = ImageFilter.blur(sigmaX: 7, sigmaY: 7, tileMode: TileMode.mirror);
                // Physical pixels per layout unit (the app is laid out at DesignWidth and scaled).
                final pixels = View.of(context).physicalSize.width / MediaQuery.sizeOf(context).width;
                fade.data
                  ?..setFloat(2, scrimHeight * pixels)
                  ..setFloat(3, 12 * pixels);
                return Stack(
                  children: [
                    // Until the shader loads (or without Impeller) only the tint shows.
                    if (fade.data case final shader?)
                      Positioned.fill(
                        child: ClipRect(
                          child: BackdropFilter.grouped(
                            filter: ImageFilter.compose(outer: ImageFilter.shader(shader), inner: blur),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    const Positioned.fill(
                      child: DecoratedBox(decoration: BoxDecoration(gradient: topGradient)),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
