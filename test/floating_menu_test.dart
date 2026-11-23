import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/one_ui_floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  // A button mid-screen, where a long menu fits neither above nor below.
  Future<GlobalKey> open(WidgetTester tester, double buttonTop, {double? left = 20, double? right}) async {
    tester.view.physicalSize = const Size(420, 933);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 40, bottom: 30);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: buttonTop,
                left: left,
                right: right,
                child: Builder(
                  builder: (context) => TextButton(
                    key: key,
                    onPressed: () => OneUIFloatingMenu.show(
                      context: context,
                      anchorKey: key,
                      items: [for (var i = 0; i < 9; i++) OneUIFloatingMenuItem(label: 'Item $i', onTap: () {})],
                    ),
                    child: const Text('Label'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Label'));
    await tester.pumpAndSettle();
    return key;
  }

  for (final buttonTop in [400.0, 470.0]) {
    testWidgets('a long menu stays clear of the system bars (button at $buttonTop)', (tester) async {
      await open(tester, buttonTop);
      expect(tester.getRect(find.text('Item 0')).top, greaterThan(40 + 16));
      expect(tester.getRect(find.text('Item 8')).bottom, lessThan(933 - 30 - 16));
    });
  }

  testWidgets('a menu from a high button opens below it', (tester) async {
    final key = await open(tester, 120);
    final button = tester.getRect(find.byKey(key));
    expect(tester.getRect(find.text('Item 0')).top, greaterThan(button.bottom));
  });

  // ColorOS lines the menu up with the button's outer edge (the Speaker and More menus).
  Rect menuRect(WidgetTester tester) =>
      tester.getRect(find.ancestor(of: find.text('Item 0'), matching: find.byType(ClipRSuperellipse)).first);

  testWidgets('a menu from a left button lines up with its left edge', (tester) async {
    final key = await open(tester, 120, left: 40);
    expect(menuRect(tester).left, closeTo(tester.getRect(find.byKey(key)).left, .5));
  });

  testWidgets('a menu from a right button lines up with its right edge', (tester) async {
    final key = await open(tester, 120, left: null, right: 40);
    expect(menuRect(tester).right, closeTo(tester.getRect(find.byKey(key)).right, .5));
  });
}
