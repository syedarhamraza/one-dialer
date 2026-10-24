import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/contacts/contact_sections.dart';
import 'package:dialer/features/contacts/contacts_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('duplicates share a number or a name, ignoring case and spaces', () {
    final groups = duplicateGroups([
      contact('1', 'Ali Khan', ['0300 1234567']),
      contact('2', 'Sara', ['+92 300 1234567']),
      contact('3', 'ali khan', []),
      contact('4', 'Zed', ['111']),
    ]);
    expect(groups.map((g) => g.map((c) => c.id).toList()), [
      ['1', '2', '3'],
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
