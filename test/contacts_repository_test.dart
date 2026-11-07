import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

DialerContact contact({
  String id = '1',
  String name = 'Ann',
  List<String> numbers = const ['0300 1234567'],
  bool isFavorite = false,
}) => DialerContact(
  id: id,
  name: name,
  numbers: numbers,
  labels: [for (final _ in numbers) 'Mobile'],
  isFavorite: isFavorite,
);

Matcher sameInstance(Object expected) => predicate((Object? actual) => identical(actual, expected));

void main() {
  final same = ContactsRepository.sameContacts;

  test('a reload with the same contacts counts as unchanged', () {
    expect(same([contact()], [contact()]), isTrue);
  });

  test('any listed field changing counts as a change', () {
    final base = [contact()];
    expect(same([contact(name: 'Anna')], base), isFalse);
    expect(
      same([
        contact(numbers: const ['0300 7654321']),
      ], base),
      isFalse,
    );
    expect(same([contact(isFavorite: true)], base), isFalse);
    expect(same([contact(), contact(id: '2')], base), isFalse);
    expect(same([contact(id: '2')], base), isFalse);
  });

  test('an unchanged photo keeps its bytes, so it is not decoded again', () {
    final old = Uint8List.fromList([1, 2, 3]);
    expect(ContactsRepository.samePhoto(old, Uint8List.fromList([1, 2, 3])), sameInstance(old));
    final changed = Uint8List.fromList([1, 2, 4]);
    expect(ContactsRepository.samePhoto(old, changed), sameInstance(changed));
    expect(ContactsRepository.samePhoto(old, null), isNull);
    expect(ContactsRepository.samePhoto(null, changed), sameInstance(changed));
  });

  testWidgets('the call screen keeps its first load when contacts change', (tester) async {
    var loads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/data'), (_) async {
      loads++;
      return const [];
    });
    final repo = ContactsRepository.instance..ignoreChanges = true;
    repo.reload();
    await tester.pump(const Duration(seconds: 1));
    expect(loads, 0);
    repo.ignoreChanges = false;
    repo.reload();
    await tester.pump(const Duration(seconds: 1));
    expect(loads, 1);
  });

  test('native rows become contacts: labels, primary, accounts, duplicate numbers, no numbers', () {
    final entries = ContactsRepository.entriesFrom(
      [
        [
          '7', 'Ann Lee', 'Ann', null, 'Lee', true,
          [
            ['0300 1234567', 'mobile', null, false],
            ['+92 300 1234567', 'mobile', null, false], // the same number from a linked account
            ['042 111', 'custom', 'Shop', true],
            ['042 222', 'custom', null, false],
          ],
          ['com.google|ann@x.com'],
        ],
        ['8', 'Bob', null, null, null, false, <List<Object?>>[], <String>[]],
        ['9', null, null, null, null, false, <List<Object?>>[], <String>[]], // nothing to show
      ],
      order: 'last',
      sortBy: 'first',
    );
    expect(entries.map((e) => e.id), ['7', '8']);
    final ann = entries.first;
    expect(ann.name, 'Lee Ann');
    expect(ann.numbers, ['0300 1234567', '042 111', '042 222']);
    expect(ann.labels, ['mobile', 'Shop', 'phone']);
    expect(ann.primaryIndex, 1);
    expect(ann.isFavorite, isTrue);
    expect(ann.accounts, ['com.google|ann@x.com']);
    expect(entries.last.numbers, isEmpty);
  });
}
