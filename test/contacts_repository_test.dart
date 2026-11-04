import 'package:dialer/core/contacts/contacts_repository.dart';
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
}
