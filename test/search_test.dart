import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/search/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wasif = DialerContact(id: '1', name: 'Wasif', numbers: ['+92 311 1234567'], labels: ['Mobile']);
  const ali = DialerContact(
    id: '2',
    name: 'Wasid Ali',
    numbers: ['0300 1111111', '0345 2222222'],
    labels: ['Mobile', 'Work'],
  );

  test('contacts match by name (case-insensitive) or by digits in any number', () {
    final byName = searchContacts([wasif, ali], 'WAS');
    expect(byName.map((h) => h.contact.name), ['Wasif', 'Wasid Ali']);
    expect(byName.first.nameRange, (0, 3));

    final byDigits = searchContacts([wasif, ali], '2222');
    expect(byDigits.single.number, '0345 2222222');
    expect(byDigits.single.numberRange, (5, 9));
  });

  test('digit match skips formatting characters', () {
    expect(numberRange('+92 311 1234567', '3111'), (4, 9));
    expect(numberRange('+92 311 1234567', 'abc'), isNull);
  });

  test('a new contacts list is searched afresh, not from the previous prepared names', () {
    final first = [wasif];
    expect(searchContacts(first, 'was').length, 1);
    final second = [ali];
    expect(searchContacts(second, 'wasif'), isEmpty);
    expect(searchContacts(second, 'wasid').single.contact.id, '2');
  });
}
