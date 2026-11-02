import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/one_ui_floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  // A button mid-screen, where a long menu fits neither above nor below.
  Future<GlobalKey> open(WidgetTester tester, double buttonTop) async {
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
                left: 20,
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
}
