import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/keypad/speed_dial_screen.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/letter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('long-press asks before clearing a slot', (tester) async {
    await DialerPrefs.instance.setSpeedDial('2', ('Sam', '0300 1234567'));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: const SpeedDialScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(LetterAvatar));
    await tester.pumpAndSettle();
    expect(find.text('Edit speed dial'), findsOneWidget);
    expect(await DialerPrefs.instance.speedDial('2'), isNotNull, reason: 'nothing cleared until picked');

    await tester.tap(find.text('Clear number'));
    await tester.pumpAndSettle();
    expect(await DialerPrefs.instance.speedDial('2'), isNull);
  });
}
