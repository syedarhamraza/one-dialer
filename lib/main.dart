import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/dialer_app.dart';
import 'app/in_call_app.dart';

/// Main UI: dial pad, recents, contacts.
void main() => runApp(const DialerApp());

/// Runs on the pre-warmed engine started by `InCallEngine.kt` for the call screen.
@pragma('vm:entry-point')
Future<void> inCallMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-warms the call screen's glass shaders so its first frame doesn't flash.
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const InCallApp()));
}
