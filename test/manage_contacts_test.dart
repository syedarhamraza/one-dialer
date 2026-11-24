import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/contacts/contact_sections.dart';
import 'package:dialer/features/contacts/contacts_screen.dart';
import 'package:dialer/features/contacts/manage_contacts_screen.dart' show ManageContactsScreen, importVCards;
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  DialerContact contact(String id, String name, List<String> numbers, {List<String> accounts = const []}) =>
      DialerContact(
        id: id,
        name: name,
        numbers: numbers,
        labels: [for (final _ in numbers) 'Mobile'],
        accounts: accounts,
      );

  test('a vCard whose quoted-printable bytes are not UTF-8 is unreadable, not a crash', () {
    // =C3=28 is an invalid UTF-8 pair (the 1.0.0 "Missing extension byte" import crash).
    const bad =
        'BEGIN:VCARD\r\nVERSION:2.1\r\nN;ENCODING=QUOTED-PRINTABLE:=C3=28st;;;;\r\nTEL:0300 1234567\r\nEND:VCARD\r\n';
    expect(importVCards(bad), isNull);
    const good = 'BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Test\r\nTEL:0300 1234567\r\nEND:VCARD\r\n';
    expect(importVCards(good), hasLength(1));
  });

  test('duplicates share a number, or a name ignoring case and spaces, never both chained', () {
    final contacts = [
      contact('1', 'Ali Khan', ['0300 1234567']),
      contact('2', 'Sara', ['+92 300 1234567', '0311 7654321']),
      contact('3', 'ali  khan', []),
      contact('4', 'Zed', ['111']),
      contact('5', 'Sara B', ['03117654321']),
    ];
    List<List<String>> ids(bool byNumber) => [
      for (final g in duplicateGroups(contacts, byNumber: byNumber)) [for (final c in g) c.id],
    ];
    expect(ids(true), [
      ['1', '2', '5'],
    ]);
    expect(ids(false), [
      ['1', '3'],
    ]);
  });

  test('name format and sort use the structured name, else the display name', () {
    String name(String order, String sortBy) => ContactsRepository.displayNames(
      first: 'Ali',
      last: 'Khan',
      fallback: 'Ali Khan',
      order: order,
      sortBy: sortBy,
    ).$1;
    expect(name('first', 'first'), 'Ali Khan');
    expect(name('last', 'first'), 'Khan Ali');
    expect(
      ContactsRepository.displayNames(
        first: 'Ali',
        last: 'Khan',
        fallback: 'Ali Khan',
        order: 'first',
        sortBy: 'last',
      ).$2,
      'khan ali',
    );
    expect(ContactsRepository.displayNames(fallback: 'Bank', order: 'last', sortBy: 'last'), ('Bank', 'bank'));
  });

  testWidgets('merging by number keeps the picked name and deletes unticked numbers', (tester) async {
    final calls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      calls.add(call);
      return null;
    });
    ContactsRepository.instance.debugSetContacts([
      contact('1', 'Test', ['0300 1234567']),
      contact('2', 'TestPerson', ['+92 300 1234567', '0311 7654321']),
    ]);
    addTearDown(() => ContactsRepository.instance.debugSetContacts([]));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: const ManageContactsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Merge duplicate contacts'), 200);
    await tester.tap(find.text('Merge duplicate contacts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge duplicated numbers'));
    await tester.pumpAndSettle();
    expect(find.text('Contacts with the same number'), findsOneWidget);
    expect(find.text('1 group'), findsOneWidget);
    await tester.tap(find.text('Merge manually'));
    await tester.pumpAndSettle();
    expect(find.text('Manual merging details'), findsOneWidget);
    await tester.tap(find.text('TestPerson'));
    await tester.tap(find.text('0311 7654321'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge').last); // the list's quick Merge is still under it
    await tester.pumpAndSettle();
    expect(find.text('The unticked number will be deleted from the contact.'), findsOneWidget);
    await tester.tap(find.text('Merge').last);
    await tester.pumpAndSettle();
    final merge = calls.singleWhere((c) => c.method == 'mergeContacts');
    expect(merge.arguments, {
      'contactIds': ['1', '2'],
      'nameContactId': '2',
      'removeNumbers': ['0311 7654321'],
    });
  });

  test('copies with the same name and a shared number show as one, from the best account', () {
    final shown = ContactsRepository.collapseCopies([
      contact('1', 'Test', ['0300 1234567'], accounts: ['USIM Account|USIM1']),
      contact('2', 'Test', ['+92 300 1234567', '0311 7654321'], accounts: ['com.google|test@example.com']),
      contact('3', 'test', ['0311 7654321', '0322 1112223'], accounts: ['com.whatsapp|WhatsApp']),
      contact('4', 'Test', ['0333 9998887']), // same name, no shared number: a different person
      contact('5', 'Other', ['0300 1234567']), // shared number, other name: left to Merge duplicates
    ]);
    expect([for (final c in shown) c.id], ['2', '4', '5']);
    final test = shown.first;
    expect(test.numbers, ['+92 300 1234567', '0311 7654321', '0322 1112223']);
    expect(test.accounts, ['com.google|test@example.com', 'USIM Account|USIM1', 'com.whatsapp|WhatsApp']);
  });

  testWidgets('quick merge keeps every number and a real name over a SIM copy', (tester) async {
    final calls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      calls.add(call);
      return null;
    });
    ContactsRepository.instance.debugSetContacts([
      contact('1', '0300 1234567', ['0300 1234567'], accounts: ['USIM Account|USIM1']),
      contact('2', 'Test', ['+92 300 1234567'], accounts: ['com.google|test@example.com']),
    ]);
    addTearDown(() => ContactsRepository.instance.debugSetContacts([]));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: const ManageContactsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Merge duplicate contacts'), 200);
    await tester.tap(find.text('Merge duplicate contacts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge duplicated numbers'));
    await tester.pumpAndSettle();
    expect(find.text('SIM card'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    await tester.tap(find.text('Merge'));
    await tester.pump();
    final merge = calls.singleWhere((c) => c.method == 'mergeContacts');
    expect(merge.arguments, {
      'contactIds': ['1', '2'],
      'nameContactId': '2',
      'removeNumbers': <String>[],
    });
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  group('Contacts tab', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_contacts'),
        (_) async => null,
      );
      ContactsRepository.instance.debugSetContacts([
        contact('1', 'Alice', ['111'], accounts: ['com.google|me@gmail.com']),
        contact('2', 'Bob', ['222']),
        contact('3', 'Carol', []),
      ]);
    });
    tearDown(() {
      ContactsRepository.instance.debugSetContacts([]);
      DialerPrefs.instance.onlyWithNumbers.value = true;
      DialerPrefs.instance.hiddenAccounts.value = const {};
    });

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OneUITheme.darkTheme,
          home: const Scaffold(body: ContactsScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows contacts without numbers only when asked', (tester) async {
      await open(tester);
      expect(find.text('Carol'), findsNothing);
      expect(find.text('2 contacts'), findsOneWidget);
      DialerPrefs.instance.onlyWithNumbers.value = false;
      await tester.pump();
      expect(find.text('Carol'), findsOneWidget);
    });

    testWidgets('hides contacts only in hidden accounts', (tester) async {
      await open(tester);
      DialerPrefs.instance.hiddenAccounts.value = {'com.google|me@gmail.com'};
      await tester.pump();
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
      DialerPrefs.instance.hiddenAccounts.value = {'|'};
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });
  });
}
