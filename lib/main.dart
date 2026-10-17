import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/dialer_app.dart';
import 'app/in_call_app.dart';

/// Main UI: dial pad, recents, contacts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-warms the glass shaders used by the nav bar so its first frame doesn't flash.
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      // Benchmarks the device and steps glass quality down on slower GPUs.
      adaptiveQuality: true,
      child: const DialerApp(),
    ),
  );
}

/// Runs on the pre-warmed engine started by `InCallEngine.kt` for the call screen.
@pragma('vm:entry-point')
void inCallMain() => runApp(const InCallApp());
