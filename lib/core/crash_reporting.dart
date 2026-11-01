import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'diagnostics/lag_diagnostics.dart';

/// Sends uncaught errors to Firebase Crashlytics, usage stats to Firebase Analytics and, in betas, performance data to Firebase
/// Performance Monitoring (beta-only: see docs/beta-only.md). Called by both engines (main and in-call).
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
  const enabled = !kDebugMode || bool.fromEnvironment('TELEMETRY_IN_DEBUG');
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(enabled);
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(enabled);
  // Analytics' own automatic events only (installs, sessions, engagement); the app logs none.
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
  await LagDiagnostics.instance.start(
    engine: engine,
    enabled: enabled,
  );
}
