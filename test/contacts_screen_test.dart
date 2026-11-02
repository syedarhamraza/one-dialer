import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/contacts/contacts_screen.dart';
import 'package:dialer/features/contacts/contacts_widgets.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

class _Pushes extends NavigatorObserver {
  final routes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => routes.add(route);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['flutter_contacts', 'com.syedarhamraza.dialer/telecom']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
    ContactsRepository.instance.contacts.value = [
      for (final letter in 'ABCDEFGHIJKLMNOP'.split(''))
        for (var i = 0; i < 4; i++)
          DialerContact(
            id: '$letter$i',
            name: '${letter}name $i',
            numbers: ['0300${letter.codeUnitAt(0)}$i'],
            labels: const ['Mobile'],
            isFavorite: letter == 'B' && i == 0,
          ),
    ];
  });
  tearDown(() => ContactsRepository.instance.contacts.value = []);

  Future<_Pushes> open(WidgetTester tester) async {
    final pushes = _Pushes();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        navigatorObservers: [pushes],
        home: const Scaffold(body: ContactsScreen()),
      ),
    );
    await tester.pump();
    pushes.routes.clear(); // the home route
    return pushes;
  }

  testWidgets('favourites sit under a star and tapping a row opens the contact', (tester) async {
    final pushes = await open(tester);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('64 contacts'), findsOneWidget);
    // The favourite is listed under the star, above the A section (and again under B).
    expect(find.text('Bname 0'), findsWidgets);
    expect(tester.getTopLeft(find.text('Bname 0').first).dy, lessThan(tester.getTopLeft(find.text('Aname 0')).dy));

    await tester.tap(find.text('Aname 1'));
    expect(pushes.routes, hasLength(1), reason: 'tap opens the details page');
  });

  testWidgets('the letter index jumps to a section', (tester) async {
    await open(tester);
    expect(find.text('Mname 0'), findsNothing, reason: 'far down the list at first');
    await tester.tap(find.descendant(of: find.byType(FastScroller), matching: find.text('M')));
    await tester.pump();
    expect(find.text('Mname 0'), findsOneWidget);
  });
}
