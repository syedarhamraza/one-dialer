import 'dart:convert';
import 'dart:ui' show FrameTiming;

import 'package:dialer/core/diagnostics/lag_diagnostics.dart';
import 'package:dialer/features/settings/help_feedback_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.syedarhamraza.dialer/diagnostics');
  final calls = <MethodCall>[];
  var pending = true;
  var unavailable = false;
  final event = {'category': 'DartStall', 'engine': 'in_call', 'reportId': 'report-1'};

  setUp(() {
    calls.clear();
    pending = true;
    unavailable = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (unavailable) throw PlatformException(code: 'UNAVAILABLE');
      switch (call.method) {
        case 'register':
          return true;
        case 'claim':
          return pending ? {'id': 'report-1', 'payload': jsonEncode(event)} : null;
        case 'ack':
          pending = false;
          return null;
        case 'report':
          return 'manual-1';
        default:
          return null;
      }
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('disabled collection never registers, uploads, or queues reports', () async {
    final diagnostics = LagDiagnostics(upload: (_) async => fail('must not upload'));
    await diagnostics.start(engine: 'main', enabled: false);
    expect(await diagnostics.reportLag(), isNull);
    expect(calls, isEmpty);
    diagnostics.dispose();
  });

  test('failed upload keeps incident for recovery; replay retains originating engine', () async {
    var failUpload = true;
    final uploads = <Map<String, dynamic>>[];
    final diagnostics = LagDiagnostics(
      upload: (payload) async {
        if (failUpload) throw StateError('offline');
        uploads.add(payload);
      },
    );
    await diagnostics.start(engine: 'main', enabled: true);
    await Future<void>.delayed(Duration.zero);
    expect(pending, true);
    expect(calls.where((c) => c.method == 'ack'), isEmpty);
    expect(calls.any((c) => c.method == 'release'), true);
    failUpload = false;
    await diagnostics.flush();
    expect(pending, false);
    expect(uploads.single['engine'], 'in_call');
    diagnostics.dispose();
  });

  test('missing native channel is harmless and reports unavailable', () async {
    unavailable = true;
    final diagnostics = LagDiagnostics();
    await diagnostics.start(engine: 'main', enabled: true);
    expect(await diagnostics.reportLag(), isNull);
    diagnostics.dispose();
  });

  test('actions contain only fixed names and optional duration', () async {
    pending = false;
    final diagnostics = LagDiagnostics(upload: (_) async {});
    await diagnostics.start(engine: 'main', enabled: true);
    diagnostics.action(DiagnosticAction.contactsLoad, elapsed: const Duration(milliseconds: 12));
    await Future<void>.delayed(Duration.zero);
    final args = calls.singleWhere((c) => c.method == 'action').arguments;
    expect(args, {'name': 'contacts_load', 'elapsedMs': 12});
    diagnostics.dispose();
  });

  test('each category is recorded from its own function, so Crashlytics keeps them apart', () {
    const categories = [
      'SevereFrameDelay',
      'NativeMainStall',
      'DartStall',
      'RenderStall',
      'InputStall',
      'UserReportedLag',
    ];
    final tops = {for (final c in categories) LagDiagnostics.incidentTrace(c).toString().split('\n').first};
    expect(tops.length, categories.length);
    expect(LagDiagnostics.incidentTrace('RenderStall').toString(), contains('_renderStall'));
  });

  test('a tap carries the worst frame drawn in the second after it', () async {
    pending = false;
    var now = 10000000;
    final diagnostics = LagDiagnostics(upload: (_) async {}, monotonicMicros: () => now);
    await diagnostics.start(engine: 'main', enabled: true);
    diagnostics.action(DiagnosticAction.tabContacts);
    diagnostics.action(DiagnosticAction.contactsLoad); // a load is not a tap: no window
    FrameTiming frame(int vsyncUs, int rasterUs) => FrameTiming(
      vsyncStart: vsyncUs,
      buildStart: vsyncUs,
      buildFinish: vsyncUs + 2000,
      rasterStart: vsyncUs + 2000,
      rasterFinish: vsyncUs + 2000 + rasterUs,
      rasterFinishWallTime: vsyncUs + 2000 + rasterUs,
    );
    diagnostics.addTimings([
      frame(now - 5000, 90000), // drawn before the tap
      frame(now + 100000, 53500),
      frame(now + 200000, 4000),
      frame(now + 1200000, 70000), // more than a second later
    ]);
    diagnostics.closeActionWindows();
    await Future<void>.delayed(Duration.zero);
    final args = calls.singleWhere((c) => c.method == 'actionFrames').arguments;
    expect(args, {'name': 'tab_contacts', 'frames': 2, 'buildMaxMs': 2.0, 'rasterMaxMs': 53.5});
    diagnostics.dispose();
  });

  testWidgets('report button explains data and cancel does not submit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: const HelpFeedbackScreen(),
      ),
    );
    await tester.tap(find.text('Report lag'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Phone numbers, contacts and messages are not included.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'report'), isEmpty);
  });

  testWidgets('successful report shows queued ID and offers copying it', (tester) async {
    pending = false;
    await tester.runAsync(() => LagDiagnostics.instance.start(engine: 'main', enabled: true));
    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OneUITheme.darkTheme,
          home: const HelpFeedbackScreen(),
        ),
      );
      await tester.tap(find.text('Report lag'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.text('Report queued'), findsOneWidget);
      expect(find.textContaining('manual-1'), findsOneWidget);
      expect(find.text('Copy ID'), findsOneWidget);
      expect(calls.where((c) => c.method == 'report').length, 1);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    } finally {
      LagDiagnostics.instance.dispose();
    }
  });
}
