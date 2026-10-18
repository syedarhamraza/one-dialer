import 'package:dialer/widgets/one_ui_collapsible_header.dart';
import 'package:dialer/widgets/one_ui_floating_action_bar.dart';
import 'package:dialer/widgets/one_ui_floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('actions inside glass-pressed pills still get their taps', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Recents',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => tapped.add('back'),
                  actions: [
                    OneUIHeaderAction(icon: Icons.search, tooltip: 'Search', onTap: () => tapped.add('search')),
                    OneUIHeaderAction(icon: Icons.more_vert, tooltip: 'More', onTap: () => tapped.add('more')),
                  ],
                ),
              ),
              const SliverFillRemaining(),
            ],
          ),
          bottomNavigationBar: OneUIFloatingActionBar(
            items: [OneUIFloatingActionBarItem(icon: Icons.delete, label: 'Delete', onTap: () => tapped.add('delete'))],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.tap(find.byIcon(Icons.search));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(tapped, ['back', 'search', 'more', 'delete']);
  });

  testWidgets('nav bar tabs still get their taps inside the glass press', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OneUIFloatingNavBar(
            currentIndex: 0,
            onTap: (index) => tapped = index,
            items: const [
              OneUINavItem(activeIcon: Icons.dialpad, inactiveIcon: Icons.dialpad, label: 'Keypad'),
              OneUINavItem(activeIcon: Icons.history, inactiveIcon: Icons.history, label: 'Recents'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Recents'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });
}
