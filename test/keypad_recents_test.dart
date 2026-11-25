import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/keypad/keypad_screen.dart';
import 'package:dialer/features/keypad/t9.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var id = 0;
  CallLogEntry call(String number, {String? name, bool private = false, String? app}) => CallLogEntry(
    id: id++,
    number: number,
    name: name,
    type: CallType.incoming,
    date: DateTime(2026, 11, 25),
    isPrivate: private,
    appPackage: app,
  );

  test('unsaved Recents numbers are searchable once each, newest first', () {
    final recents = recentNumbers([
      call('0300 1234567'),
      call('03001234567'), // the same number, written differently
      call('', private: true),
      call('03009999999', app: 'com.whatsapp'),
      call('0300 7654321', name: 'CITY BANK'),
    ]);
    expect(recents.map((r) => r.name), ['0300 1234567', 'CITY BANK']);

    final match = t9Search('1234', recents).single;
    expect(match.number, '0300 1234567');
    expect((match.entry as RecentNumber).call.number, '0300 1234567');
  });

  test('contacts come before unsaved numbers, even ones matched only by number', () {
    final saved = DialerContact(id: '1', name: 'Sara', numbers: const ['0311 5551234'], labels: const ['Mobile']);
    final r = keypadMatches('1234', [saved], [call('0300 1234567')]);
    expect(r.map((m) => m.number), ['0311 5551234', '0300 1234567']);
  });
}
