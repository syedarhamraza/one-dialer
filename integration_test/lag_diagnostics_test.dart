
import 'package:dialer/core/diagnostics/lag_diagnostics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Explicit development run only; never included by lib/main.dart.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real diagnostics channel captures and queues incidents', (tester) async {
    expect(kReleaseMode, false);
    expect(const bool.fromEnvironment('LAG_DIAGNOSTICS_TEST_HOOKS'), true);
    await Firebase.initializeApp();
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    final incidents = <Map<String, dynamic>>[];
    final monitor = LagDiagnostics(
      upload: (payload) async {
        incidents.add(payload);
        await LagDiagnostics.uploadToFirebase(payload);
      },
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Diagnostics test'))),
      ),
    );
    await tester.runAsync(() async {
      await monitor.start(engine: 'main', enabled: true);
      await Future<void>.delayed(const Duration(seconds: 7));
      monitor.action(DiagnosticAction.keypad);
      await monitor.simulate('frame');
      await Future<void>.delayed(const Duration(seconds: 2));
      final manual = await monitor.reportLag();
      expect(manual, isNotNull);
      expect(await monitor.reportLag(), isNull);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (kDebugMode) {
        await monitor.simulate('native');
        await Future<void>.delayed(const Duration(seconds: 7));
      }
      await monitor.simulate('dart');
      await Future<void>.delayed(const Duration(seconds: 7));
      await monitor.flush();
      expect(incidents.any((p) => p['category'] == 'SevereFrameDelay'), true);
      expect(incidents.any((p) => p['category'] == 'UserReportedLag'), true);
      if (kDebugMode) {
        expect(incidents.any((p) => p['category'] == 'NativeMainStall' && (p['mainStack'] as String).isNotEmpty), true);
      }
      expect(incidents.any((p) => p['category'] == 'DartStall' || p['category'] == 'NativeMainStall'), true);
      expect(incidents.every((p) => p['engine'] == 'main'), true);
      binding.reportData = {
        'reports': incidents.map((p) => {'id': p['reportId'], 'category': p['category']}).toList(),
      };
      monitor.dispose();
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
