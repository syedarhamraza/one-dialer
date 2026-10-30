import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'diagnostics/lag_diagnostics.dart';

/// Sends uncaught errors to Firebase Crashlytics. Called by both engines (main and in-call).
///
/// Debug builds send nothing unless built with `--dart-define=TELEMETRY_IN_DEBUG=true`
/// (for checking the setup). Without `android/app/google-services.json` it does nothing.
Future<void> initCrashReporting({String engine = 'main'}) async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Crash reporting off: $error');
    return;
  }
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode || const bool.fromEnvironment('TELEMETRY_IN_DEBUG'));
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
  await LagDiagnostics.instance.start(
    engine: engine,
    enabled: !kDebugMode || const bool.fromEnvironment('TELEMETRY_IN_DEBUG'),
  );
}
