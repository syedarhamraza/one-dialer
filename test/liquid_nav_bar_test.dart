import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/one_ui_floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  const items = [
    OneUINavItem(activeIcon: Icons.call, inactiveIcon: Icons.call_outlined, label: 'Calls'),
    OneUINavItem(activeIcon: Icons.people, inactiveIcon: Icons.people_outline, label: 'Contacts'),
  ];

  Future<void> pump(WidgetTester tester, {Widget? docked}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: OneUIFloatingNavBar(currentIndex: 0, onTap: (_) {}, items: items, dockedContent: docked),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  tearDown(() {
    DialerPrefs.instance.navStyle.value = 'frosted';
    DialerPrefs.instance.visualEffects.value = 'full';
  });

  testWidgets('liquid style draws the glass tab bar, and docked actions on the same glass', (tester) async {
    DialerPrefs.instance.navStyle.value = 'liquid';
    await pump(tester);
    expect(find.byType(GlassTabBar), findsOneWidget);

    await pump(tester, docked: const Text('Delete'));
    expect(find.descendant(of: find.byType(GlassContainer), matching: find.text('Delete')), findsOneWidget);
    expect(find.byType(GlassTabBar), findsNothing);
  });

  testWidgets('reduced effects keep the frosted bar', (tester) async {
    DialerPrefs.instance.navStyle.value = 'liquid';
    DialerPrefs.instance.visualEffects.value = 'reduced';
    await pump(tester);
    expect(find.byType(GlassTabBar), findsNothing);
    expect(find.text('Calls'), findsOneWidget);
  });
}
