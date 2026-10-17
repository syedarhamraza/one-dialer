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

  double opacity(WidgetTester tester, Finder target) {
    final transition = find.ancestor(of: target, matching: find.byType(FadeTransition)).first;
    return tester.widget<FadeTransition>(transition).opacity.value;
  }

  testWidgets('navigation and Delete fade both ways without moving the controls', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await open(tester);
      final nav = find.byType(OneUIFloatingNavBar);
      final delete = find.byIcon(Icons.backspace_rounded);
      final navPosition = tester.getBottomLeft(nav);
      final callPosition = tester.getCenter(find.bySemanticsLabel('Call'));
      final input = tester.widget<KeypadScreen>(find.byType(KeypadScreen)).input;
      input.value = '5';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getBottomLeft(nav), navPosition);
      expect(opacity(tester, nav), allOf(greaterThan(0), lessThan(1)));
      expect(opacity(tester, delete), allOf(greaterThan(0), lessThan(1)));
      expect(tester.getCenter(find.bySemanticsLabel('Call')), callPosition);
      await tester.pumpAndSettle();
      expect(opacity(tester, nav), 0);
      expect(opacity(tester, delete), 1);
      input.value = '';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(tester, nav), allOf(greaterThan(0), lessThan(1)));
      expect(opacity(tester, delete), allOf(greaterThan(0), lessThan(1)));
      expect(tester.getBottomLeft(nav), navPosition);
      await tester.pumpAndSettle();
      expect(opacity(tester, nav), 1);
      expect(opacity(tester, delete), 0);
      expect(
        tester.getSemantics(find.byType(MainShell)).toStringDeep(),
        isNot(contains('Delete, long-press to clear')),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reduced motion skips both fades', (tester) async {
    await open(tester, reduceMotion: true);
    final input = tester.widget<KeypadScreen>(find.byType(KeypadScreen)).input;
    input.value = '5';
    await tester.pump();
    await tester.pump();
    expect(opacity(tester, find.byType(OneUIFloatingNavBar)), 0);
    expect(opacity(tester, find.byIcon(Icons.backspace_rounded)), 1);
  });
}
