import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/dialer_app.dart';
import 'app/in_call_app.dart';
import 'core/crash_reporting.dart';
import 'core/prefs/dialer_prefs.dart';
import 'features/updates/presentation/update_controller.dart';

/// Main UI: dial pad, recents, contacts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _profileServiceAddress();
  await initCrashReporting();
  // Not awaited: rows use the defaults until the saved choices arrive a moment later.
  DialerPrefs.instance.loadChoices();
  await DialerPrefs.instance.loadAppearance();
  // The bundled Roboto (the glass version numeral) under About › Open source licences.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Roboto'], await rootBundle.loadString('assets/fonts/Roboto-LICENSE.txt'));
  });
  runApp(const DialerApp());
  // Play's update API needs a foreground activity, so ask after the first frame.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => UpdateController.instance.loadPreferences().then((_) => UpdateController.instance.autoCheck()),
  );
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
  // Not awaited: the ringing screen's first frame mustn't wait on Firebase's round trips.
  unawaited(initCrashReporting(engine: 'in_call'));
  // Settings › Call screen effects, never awaited: a ringing call must not wait on storage. It
  // can change while this engine is cached, so it's read again whenever the call screen resumes.
  unawaited(DialerPrefs.instance.loadCallEffects());
  AppLifecycleListener(onResume: DialerPrefs.instance.loadCallEffects);
  // Pre-warms the call screen's glass shaders so its first frame doesn't flash.
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const InCallApp()));
}
