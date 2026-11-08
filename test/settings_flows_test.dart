import 'package:dialer/features/blocking/blocking_screen.dart';
import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/settings/app_icon_screen.dart';
import 'package:dialer/features/settings/call_recording_screen.dart';
import 'package:dialer/features/settings/dialing_settings_screen.dart';
import 'package:dialer/features/settings/display_settings_screen.dart';
import 'package:dialer/features/settings/glass_settings_screen.dart';
import 'package:dialer/features/settings/quick_replies_screen.dart';
import 'package:dialer/widgets/one_ui_radio.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final telecom = <MethodCall>[];
  Map<String, Object?>? recorder;

  setUp(() {
    telecom.clear();
    recorder = null;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      telecom.add(call);
      return switch (call.method) {
        'getBlocking' => <String, Object?>{},
        'hasScreeningRole' => false,
        'getQuickReplies' => ['Hi'],
        'getLauncherIcon' => 'classic',
        'getRecorder' => recorder,
        'listRecordings' => [
          {'name': '1762600000000_+923001234567.m4a', 'number': '+923001234567', 'startMillis': 1762600000000, 'durationMs': 65000, 'bytes': 1000},
        ],
        'getSims' => [
          {'id': 'a', 'label': 'SIM 1'},
          {'id': 'b', 'label': 'SIM 2'},
        ],
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (_) async => null);
  });

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  // Stops at the input: flutter_contacts' block call checks dart:io Platform.isAndroid, which
  // a desktop test host can't fake.
  testWidgets('Add number opens the menu, and Enter number the floating input', (tester) async {
    await open(tester, const BlockingScreen());
    await tester.tap(find.text('Add number'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from contacts'), findsOneWidget);
    await tester.tap(find.text('Enter number'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from contacts'), findsNothing);
    expect(find.text('Block number'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('call recording waits for the consent notice, then lists recordings', (tester) async {
    recorder = {'trusted': true, 'ready': false, 'accessibilityOn': true, 'micGranted': true, 'consented': false};
    await open(tester, const CallRecordingScreen());
    expect(find.text('Before you record'), findsOneWidget);
    expect(find.text('Record all calls'), findsNothing);
    expect(find.text('+923001234567'), findsNothing);

    recorder = {...recorder!, 'consented': true, 'ready': true};
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(telecom.any((c) => c.method == 'setCallSetting' && c.arguments['key'] == 'recordingConsent'), isTrue);
    expect(find.text('Record all calls'), findsOneWidget);
    expect(find.text('+923001234567'), findsOneWidget);
    await tester.tap(find.text('+923001234567'));
    expect(telecom.last.method, 'openRecording');
  });

  testWidgets('without the recorder app the page offers nothing', (tester) async {
    await open(tester, const CallRecordingScreen());
    expect(find.text('One Dialer Recorder'), findsNothing);
    expect(telecom.any((c) => c.method == 'listRecordings'), isFalse);
  });

  testWidgets('a quick reply is kept to one SMS', (tester) async {
    await open(tester, const QuickRepliesScreen());
    await tester.tap(find.text('Add message'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x' * 200);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = telecom.lastWhere((c) => c.method == 'setQuickReplies').arguments;
    expect('$saved', contains('x' * 160));
    expect('$saved', isNot(contains('x' * 161)));
  });

  testWidgets('the app icon page shows the current style and switches both icons', (tester) async {
    await open(tester, const AppIconScreen());
    bool selected(int i) => tester.widgetList<OneUIRadio>(find.byType(OneUIRadio)).elementAt(i).isSelected;
    expect([selected(0), selected(1)], [false, true]); // classic
    await tester.tap(find.text('Glossy'));
    await tester.pumpAndSettle();
    expect(telecom.last.method, 'setLauncherIcon');
    expect(telecom.last.arguments, {'style': 'default'});
    expect([selected(0), selected(1)], [true, false]);
  });

  testWidgets('Display & effects hides the Glass & blur row below full effects', (tester) async {
    DialerPrefs.instance.visualEffects.value = 'full';
    await open(tester, const DisplaySettingsScreen());
    expect(find.text('Glass & blur'), findsOneWidget);
    expect(find.text('Glow strength'), findsNothing);
    await tester.tap(find.text('Reduce visual effects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Effects off').last);
    await tester.pumpAndSettle();
    expect(DialerPrefs.instance.visualEffects.value, 'off');
    expect(find.text('Glass & blur'), findsNothing);
    DialerPrefs.instance.visualEffects.value = 'full';
  });

  testWidgets('Glass & blur shows glow strength while edge glow is in use, liquid options only for liquid', (
    tester,
  ) async {
    final note = find.textContaining('Liquid glass is experimental');
    DialerPrefs.instance.navStyle.value = 'frosted';
    await open(tester, const GlassSettingsScreen());
    expect(find.text('Glow strength'), findsOneWidget);
    expect(find.text('Liquid glass on'), findsNothing);
    expect(find.text('Glass effect'), findsNothing);
    expect(note, findsOneWidget);

    // Liquid glass on everything: no edge glow left to style.
    DialerPrefs.instance.navStyle.value = 'liquid';
    await tester.pumpAndSettle();
    expect(find.text('Liquid glass on'), findsOneWidget);
    expect(find.text('Glass effect'), findsOneWidget);
    expect(find.text('Glow strength'), findsNothing);
    expect(note, findsOneWidget);

    // Nav bar only: the rest still glows.
    await tester.tap(find.text('Liquid glass on'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nav bar only').last);
    await tester.pumpAndSettle();
    expect(DialerPrefs.instance.liquidScope.value, 'navbar');
    expect(find.text('Glow strength'), findsOneWidget);
    DialerPrefs.instance.navStyle.value = 'frosted';
    DialerPrefs.instance.liquidScope.value = 'all';
  });

  testWidgets('Glass & blur hides glow strength in light mode', (tester) async {
    DialerPrefs.instance.navStyle.value = 'frosted';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.lightTheme,
        home: const GlassSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Glass style'), findsOneWidget);
    expect(find.text('Glow strength'), findsNothing);
  });

  testWidgets('Keypad & recents offers Choose SIM and call on dual SIM', (tester) async {
    await open(tester, const DialingSettingsScreen());
    await tester.tap(find.text('Tap a recent call'));
    await tester.pumpAndSettle();
    expect(find.text('Choose SIM and call'), findsOneWidget);
  });
}
