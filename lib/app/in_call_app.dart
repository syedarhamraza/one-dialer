import 'package:flutter/material.dart';

import '../features/in_call/in_call_screen.dart';
import '../theme/one_ui_theme.dart';

class InCallApp extends StatelessWidget {
  const InCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: OneUITheme.darkTheme,
      scrollBehavior: OneUITheme.scrollBehavior,
      builder: (context, child) => DesignWidth(child: child!),
      home: const InCallScreen(),
    );
  }
}

/// Lays the call screen out at the width it was designed on (a vivo at 420 dp) and scales it to
/// the screen, so every phone shows the same proportions: a 360 dp phone smaller, a 448 dp one
/// larger. Scaling up stops at [maxScale], so tablets and open foldables get sensible sizes and
/// more room instead of giant buttons; landscape never scales.
class DesignWidth extends StatelessWidget {
  const DesignWidth({super.key, required this.child});

  static const width = 420.0;
  static const maxScale = 1.15;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width > media.size.height) return child;
    final scale = (media.size.width / width).clamp(0.0, maxScale);
    if (scale == 1) return child;
    return FittedBox(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: media.size.width / scale,
        height: media.size.height / scale,
        child: MediaQuery(
          data: media.copyWith(
            size: media.size / scale,
            padding: media.padding / scale,
            viewPadding: media.viewPadding / scale,
            viewInsets: media.viewInsets / scale,
            systemGestureInsets: media.systemGestureInsets / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}
