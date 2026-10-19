import 'package:dialer/app/main_shell.dart';
import 'package:dialer/features/keypad/keypad_screen.dart';
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
    for (final name in ['com.syedarhamraza.dialer/telecom', 'com.syedarhamraza.dialer/call_state', 'flutter_contacts']) {
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
}
