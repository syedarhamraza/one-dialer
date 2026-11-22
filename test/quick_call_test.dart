import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/recents/call_log_repository.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/widgets/place_call.dart';
import 'package:dialer/widgets/swipe_action.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('quick calling is off by default and a tap can be set to call', () async {
    final prefs = DialerPrefs.instance;
    await prefs.loadChoices();
    expect((prefs.rowCallButton.value, prefs.swipeToCall.value), (false, false));

    await SharedPreferencesAsync().setString('recent_tap', 'call');
    await prefs.setSwipeToCall(true);
    prefs.swipeToCall.value = false;
    await prefs.loadChoices();
    expect((prefs.recentTap.value, prefs.swipeToCall.value), ('call', true));
  });

  test('the swipe and call button styles default to pill and tint and ignore unknown ones', () async {
    final prefs = DialerPrefs.instance;
    await prefs.loadChoices();
    expect((prefs.swipeStyle.value, prefs.callButtonStyle.value), ('pill', 'tint'));

    // A style from an earlier test build (Colour wash) falls back to Glass button.
    await SharedPreferencesAsync().setString('swipe_style', 'wash');
    await prefs.setCallButtonStyle('lit');
    prefs.callButtonStyle.value = 'tint';
    await prefs.loadChoices();
    expect((prefs.swipeStyle.value, prefs.callButtonStyle.value), ('pill', 'lit'));
    prefs.callButtonStyle.value = 'tint';
  });

  for (final style in DialerPrefs.swipeStyles) {
    testWidgets('a $style swipe past a third of the row calls (right) or messages (left); a short one does nothing', (
      tester,
    ) async {
      DialerPrefs.instance.swipeStyle.value = style;
      addTearDown(() => DialerPrefs.instance.swipeStyle.value = 'pill');
      final done = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SwipeAction(
              onCall: () => done.add('call'),
              onMessage: () => done.add('message'),
              child: const SizedBox(height: 60, width: double.infinity, child: Text('row')),
            ),
          ),
        ),
      );
      final width = tester.getSize(find.byType(SwipeAction)).width;
      await tester.drag(find.text('row'), Offset(width * 0.2, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.text('row'), Offset(width * 0.5, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.text('row'), Offset(-width * 0.5, 0));
      await tester.pumpAndSettle();
      expect(done, ['call', 'message']);
      expect(tester.takeException(), isNull);
    });
  }

  group('recent SIM', () {
    final repo = CallLogRepository.instance;
    final native = <MethodCall>[];
    CallLogEntry call(int id, String number, String? sim) =>
        CallLogEntry(id: id, number: number, type: CallType.outgoing, date: DateTime(2026, 11, 22), simId: sim);

    setUp(() {
      native.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.syedarhamraza.dialer/telecom'),
        (c) async {
          native.add(c);
          if (c.method == 'getSims') {
            return [
              {'id': 'sim1', 'label': 'Personal', 'isDefault': false},
              {'id': 'sim2', 'label': 'Work', 'isDefault': false},
            ];
          }
          return null;
        },
      );
    });
    tearDown(() {
      repo.calls.value = const [];
      DialerPrefs.instance.simChoice.value = 'buttons';
    });

    test("is the SIM the number last used, else the newest call's, else none", () {
      repo.calls.value = [
        call(3, '0300 7654321', 'sim1'),
        call(2, '+92 300 1234567', 'sim2'),
        call(1, '03001234567', 'sim1'),
      ];
      expect(repo.recentSim('03001234567'), 'sim2');
      expect(repo.recentSim('0311 0000000'), 'sim1');
      repo.calls.value = [call(1, '03001234567', null)];
      expect(repo.recentSim('03001234567'), isNull);
    });

    testWidgets('swipe to call uses it without the SIM menu, and so does Use the recent SIM', (tester) async {
      repo.calls.value = [call(1, '03001234567', 'sim2')];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: Text('page')),
        ),
      );
      final context = tester.element(find.text('page'));
      Object? simOf(Iterable<MethodCall> calls) => calls.lastWhere((c) => c.method == 'placeCall').arguments['simId'];

      await tester.runAsync(() => placeCall(context, '03001234567', recentSim: true));
      expect(simOf(native), 'sim2');

      native.clear();
      DialerPrefs.instance.simChoice.value = 'recent';
      await tester.runAsync(() => placeCall(context, '03001234567'));
      expect(simOf(native), 'sim2');
      expect(find.text('Personal'), findsNothing); // no SIM menu
    });

    testWidgets('a SIM no longer in the phone is never used', (tester) async {
      repo.calls.value = [call(1, '03001234567', 'gone')];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: Text('page')),
        ),
      );
      final context = tester.element(find.text('page'));
      // Falls through to the SIM menu (two SIMs, no default); nothing is placed until a pick.
      unawaited(placeCall(context, '03001234567', recentSim: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('Personal'), findsOneWidget);
      expect(native.where((c) => c.method == 'placeCall'), isEmpty);
    });
  });

  test('Use the recent SIM survives a restart', () async {
    final prefs = DialerPrefs.instance;
    await prefs.setSimChoice('recent');
    prefs.simChoice.value = 'buttons';
    await prefs.loadChoices();
    expect(prefs.simChoice.value, 'recent');
    prefs.simChoice.value = 'buttons';
  });

  test('a saved Pill or Glass call button, both removed, falls back to Soft tint', () async {
    final prefs = DialerPrefs.instance;
    for (final gone in ['pill', 'glass']) {
      await prefs.setCallButtonStyle(gone); // as an earlier beta saved it
      await prefs.loadChoices();
      expect(prefs.callButtonStyle.value, 'tint');
    }
  });
}
