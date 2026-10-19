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

/// Lays the call screen out at the width it was designed on (a vivo at 420 dp) and scales it
/// down on narrower screens, so a 360 dp phone shows the same proportions, only smaller.
/// Wider screens lay out normally.
class DesignWidth extends StatelessWidget {
  const DesignWidth({super.key, required this.child});

  static const width = 420.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.size.width / width;
    // Landscape is wider than 420 dp, so it never scales.
    if (scale >= 1) return child;
    return FittedBox(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
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
