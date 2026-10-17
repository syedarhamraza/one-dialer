import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/search/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 17, 12);
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

  test('calls filter by query, call time and type', () {
    CallLogEntry call(int id, String number, DateTime date, CallType type) =>
        CallLogEntry(id: id, number: number, type: type, date: date);
    final calls = [
      call(1, '03111234567', DateTime(2026, 10, 17, 9), CallType.missed),
      call(2, '03001111111', DateTime(2026, 10, 16, 9), CallType.outgoing),
      call(3, '03111234567', DateTime(2026, 9, 1), CallType.incoming),
    ];
    List<int> ids(String q, {CallTime? time, CallFilter? type}) => [
      for (final c in searchCalls(
        calls,
        q,
        time: time,
        type: type,
        nameFor: (n) => n == '03111234567' ? 'Wasif' : null,
        now: now,
      ))
        c.id,
    ];

    expect(ids('was'), [1, 3]);
    expect(ids('', time: CallTime.yesterday), [2]);
    expect(ids('', time: CallTime.week), [1, 2]);
    expect(ids('was', time: CallTime.month, type: CallFilter.missed), [1]);
    expect(ids('0300'), [2]);
  });
}
