import 'package:dialer/app/main_shell.dart';
import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/keypad/keypad_screen.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/recents/call_log_repository.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/one_ui_floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    for (final name in [
      'com.syedarhamraza.dialer/telecom',
      'com.syedarhamraza.dialer/call_state',
      'flutter_contacts',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
  });

  Future<void> open(WidgetTester tester, {bool reduceMotion = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme.copyWith(platform: TargetPlatform.android),
        scrollBehavior: OneUITheme.scrollBehavior,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: const MainShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nav bar stays while typing and the keypad only shows on Calls', (tester) async {
    await open(tester);
    final nav = find.byType(OneUIFloatingNavBar);
    expect(find.text('Calls'), findsWidgets);
    expect(find.text('Contacts'), findsWidgets);
    expect(find.text('Keypad'), findsNothing);
    final navPosition = tester.getBottomLeft(nav);
    final input = tester.widget<KeypadScreen>(find.byType(KeypadScreen)).input;
    input.value = '5';
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(nav), navPosition);
    expect(find.descendant(of: nav, matching: find.text('Contacts')).hitTestable(), findsOneWidget);
    await tester.tap(find.descendant(of: nav, matching: find.text('Contacts')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Call'), findsNothing);
    await tester.tap(find.descendant(of: nav, matching: find.text('Calls')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Call'), findsOneWidget);
    expect(input.value, '5');
  });

  testWidgets('scrolling Calls by hand drops the keypad', (tester) async {
    await open(tester);
    final open_ = tester.widget<KeypadScreen>(find.byType(KeypadScreen)).open;
    expect(open_.value, isTrue);
    await tester.drag(find.text('Calls').first, const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(open_.value, isFalse);
  });

  testWidgets('typing morphs All | Missed into Add to Contacts and back', (tester) async {
    await open(tester);
    final input = tester.widget<KeypadScreen>(find.byType(KeypadScreen)).input;
    expect(find.text('Missed').hitTestable(), findsOneWidget);
    input.value = '5';
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add to Contacts').hitTestable(), findsOneWidget);
    expect(find.text('Missed').hitTestable(), findsNothing);
    input.value = '';
    await tester.pumpAndSettle();
    expect(find.text('Missed').hitTestable(), findsOneWidget);
  });

  testWidgets('selecting morphs the header into the count and Cancel, and back', (tester) async {
    CallLogRepository.instance.calls.value = [
      CallLogEntry(id: 1, number: '03001234567', type: CallType.incoming, date: DateTime.now()),
    ];
    addTearDown(() => CallLogRepository.instance.calls.value = const []);
    await open(tester);
    // Drop the keypad so the row can be long-pressed.
    tester.widget<KeypadScreen>(find.byType(KeypadScreen)).open.value = false;
    await tester.pumpAndSettle();
    await tester.longPress(find.text('03001234567'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cancel').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Search').hitTestable(), findsNothing);
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Missed').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Search').hitTestable(), findsOneWidget);
  });

  testWidgets('tapping a call opens its page or writes it in the keypad, never calls', (tester) async {
    final native = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.syedarhamraza.dialer/telecom'),
      (call) async {
        native.add(call);
        return null;
      },
    );
    CallLogRepository.instance.calls.value = [
      CallLogEntry(id: 1, number: '03001234567', type: CallType.incoming, date: DateTime.now()),
    ];
    addTearDown(() {
      CallLogRepository.instance.calls.value = const [];
      DialerPrefs.instance.recentTap.value = 'details';
    });
    await open(tester);
    final keypad = tester.widget<KeypadScreen>(find.byType(KeypadScreen));
    expect(keypad.open.value, isTrue);
    await tester.tap(find.text('03001234567'));
    await tester.pumpAndSettle();
    expect(keypad.open.value, isFalse);
    expect(find.text('Call logs'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    DialerPrefs.instance.recentTap.value = 'dial';
    await tester.tap(find.text('03001234567'));
    await tester.pumpAndSettle();
    expect(keypad.input.value, '03001234567');
    expect(keypad.open.value, isTrue);
    expect(native.where((c) => c.method == 'placeCall'), isEmpty);
  });

  testWidgets('the menu grows from its button, runs an item, and closes on Back', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Show blocked calls'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
    expect(await DialerPrefs.instance.hideBlockedCalls(), isFalse);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('dragging across the menu picks the row the finger is lifted on', (tester) async {
    await open(tester);
    final before = await DialerPrefs.instance.hideBlockedCalls();
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(find.text('Settings')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.textContaining('blocked calls')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
    expect(await DialerPrefs.instance.hideBlockedCalls(), !before);
  });
}
