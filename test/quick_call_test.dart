import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/widgets/swipe_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('quick calling is off by default and a tap can be set to call', () async {
    final prefs = DialerPrefs.instance;
    await prefs.loadChoices();
    expect((prefs.rowCallButton.value, prefs.swipeToCall.value, prefs.doubleTapCall.value), (false, false, false));

    await SharedPreferencesAsync().setString('recent_tap', 'call');
    await prefs.setSwipeToCall(true);
    prefs.swipeToCall.value = false;
    await prefs.loadChoices();
    expect((prefs.recentTap.value, prefs.swipeToCall.value), ('call', true));
  });

  testWidgets('a swipe past a third of the row calls (right) or messages (left); a short one does nothing', (
    tester,
  ) async {
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
  });
}
