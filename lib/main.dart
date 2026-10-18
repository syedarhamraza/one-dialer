import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/dialer_app.dart';
import 'app/in_call_app.dart';

/// Main UI: dial pad, recents, contacts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _profileServiceAddress();
  // The nav bar uses the glass package's tab bar (motion only), which needs its shaders warmed.
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const DialerApp()));
}

void _profileServiceAddress() {
  if (!kProfileMode) return;
  developer.Service.getInfo()
      .then((info) async {
        if (info.serverUri != null) {
          await File('${Directory.systemTemp.path}/dialer-vm-service.txt').writeAsString(info.serverUri.toString());
        }
      })
      .catchError((Object error) => debugPrint('Could not save profile service address: $error'));
}

/// Runs on the pre-warmed engine started by `InCallEngine.kt` for the call screen.
@pragma('vm:entry-point')
Future<void> inCallMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  _profileServiceAddress();
  // Pre-warms the call screen's glass shaders so its first frame doesn't flash.
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const InCallApp()));
}
