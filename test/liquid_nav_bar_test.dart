import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/call_glass.dart';
import 'package:dialer/widgets/liquid_body.dart';
import 'package:dialer/widgets/one_ui_floating_nav_bar.dart';
import 'package:dialer/widgets/one_ui_glass_surface.dart';
import 'package:dialer/widgets/rise_route.dart';
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
    DialerPrefs.instance.navGlass.value = 'premium';
    DialerPrefs.instance.liquidScope.value = 'all';
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

  testWidgets('liquid style puts the floating chrome on the same glass, only at full effects', (tester) async {
    Future<void> chrome() => tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: const Scaffold(
          body: Column(
            children: [
              SizedBox(width: 48, height: 48, child: CallGlass(child: Text('pill'))),
              OneUIGlassSurface(child: Text('bar')),
            ],
          ),
        ),
      ),
    );

    DialerPrefs.instance.navStyle.value = 'liquid';
    await chrome();
    expect(find.descendant(of: find.byType(GlassContainer), matching: find.text('bar')), findsOneWidget);
    expect(find.descendant(of: find.byType(CallGlass), matching: find.byType(GlassContainer)), findsOneWidget);

    DialerPrefs.instance.visualEffects.value = 'reduced';
    await tester.pump();
    expect(find.byType(GlassContainer), findsNothing);
  });

  testWidgets("a pushed page's liquid pills share one glass backdrop group", (tester) async {
    DialerPrefs.instance.navStyle.value = 'liquid';
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: nav, theme: OneUITheme.darkTheme, home: const SizedBox()));
    nav.currentState!.push(
      RisePageRoute<void>(
        builder: (_) => const Scaffold(
          body: Row(
            children: [
              SizedBox(width: 48, height: 48, child: CallGlass(child: Text('a'))),
              SizedBox(width: 48, height: 48, child: CallGlass(child: Text('b'))),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Grouping only pays off without a save layer (Opacity, ShaderMask, ...) between them and it.
    for (final label in ['a', 'b']) {
      expect(find.ancestor(of: find.text(label), matching: find.byType(GlassBackdropGroup)), findsOneWidget);
    }
    expect(find.byType(GlassContainer), findsNWidgets(2));
  });

  testWidgets('Automatic glass effect adds the adaptive scope without rebuilding the app', (tester) async {
    DialerPrefs.instance.navStyle.value = 'liquid';
    final field = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidQualityScope(child: TextField(controller: field)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'kept');
    final state = tester.state(find.byType(EditableText));

    DialerPrefs.instance.navGlass.value = 'auto';
    await tester.pump();
    expect(find.byType(GlassAdaptiveScope), findsOneWidget);
    expect(tester.state(find.byType(EditableText)), same(state));

    DialerPrefs.instance.navGlass.value = 'premium';
    await tester.pump();
    expect(find.byType(GlassAdaptiveScope), findsNothing);
    expect(tester.state(find.byType(EditableText)), same(state));
    expect(find.text('kept'), findsOneWidget);
  });

  testWidgets('Liquid glass on picks the surfaces: nav bar only, then the buttons but not modals', (tester) async {
    DialerPrefs.instance.navStyle.value = 'liquid';
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(width: 48, height: 48, child: CallGlass(child: Text('pill'))),
              const OneUIGlassSurface(elevation: OneUIGlassElevation.modal, child: Text('modal')),
              Expanded(
                child: OneUIFloatingNavBar(currentIndex: 0, onTap: (_) {}, items: items),
              ),
            ],
          ),
        ),
      ),
    );
    Finder liquid(String text) => find.ancestor(of: find.text(text), matching: find.byType(GlassContainer));
    final pill = find.descendant(of: find.byType(CallGlass), matching: find.byType(GlassContainer));

    DialerPrefs.instance.liquidScope.value = 'navbar';
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(pill, findsNothing);
    expect(liquid('modal'), findsNothing);

    DialerPrefs.instance.liquidScope.value = 'controls';
    await tester.pump(const Duration(seconds: 1));
    expect(pill, findsOneWidget);
    expect(liquid('modal'), findsNothing);

    DialerPrefs.instance.liquidScope.value = 'all';
    await tester.pump(const Duration(seconds: 1));
    expect(liquid('modal'), findsOneWidget);
  });
}
