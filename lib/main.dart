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
import 'features/in_call/call_screen_widgets.dart';
import 'features/updates/presentation/update_controller.dart';

/// Main UI: dial pad, recents, contacts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _profileServiceAddress();
  await initCrashReporting();
  // Not awaited: rows use the defaults until the saved choices arrive a moment later.
  DialerPrefs.instance.loadChoices();
  await DialerPrefs.instance.loadAppearance();
  DialerPrefs.instance.navStyle.addListener(_warmLiquidGlass);
  _warmLiquidGlass();
  await DialerPrefs.instance.loadLanguage();
  AppLifecycleListener(onResume: DialerPrefs.instance.loadLanguage);
  // The bundled Roboto (the glass version numeral) under About › Open source licences.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Roboto'], await rootBundle.loadString('assets/fonts/Roboto-LICENSE.txt'));
  });
  runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const DialerApp()));
  // Play's update API needs a foreground activity, so ask after the first frame.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => UpdateController.instance.loadPreferences().then((_) => UpdateController.instance.autoCheck()),
  );
}

/// The glass package's shaders, loaded once and only when Settings › Nav bar style is Liquid glass
/// (the one place the main app draws the package's glass). Its frame monitor stays off: our lag
/// diagnostics already watch frames, and its warnings would reach Crashlytics.
void _warmLiquidGlass() {
  if (DialerPrefs.instance.navStyle.value != 'liquid') return;
  DialerPrefs.instance.navStyle.removeListener(_warmLiquidGlass);
  unawaited(LiquidGlassWidgets.initialize(enablePerformanceMonitor: false));
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
  unawaited(DialerPrefs.instance.loadLanguage());
  CallerLookup.start();
  AppLifecycleListener(
    onResume: () {
      DialerPrefs.instance.loadCallEffects();
      DialerPrefs.instance.loadLanguage();
    },
  );
  // No LiquidGlassWidgets.initialize(): it preloads the package's glass shaders,
  // and the call screen draws none (its glass is our own; the package only supplies the press).
  runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const InCallApp()));
}
