import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/contacts/contact_sections.dart';
import 'package:dialer/widgets/letter_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

DialerContact c(String name, [String number = '0300 1234567']) =>
    DialerContact(id: name, name: name, numbers: [number], labels: const ['Mobile']);

void main() {
  test('sections are A–Z with non-letters last under #', () {
    final s = sectionContacts([c('ali'), c('Amar'), c('123 Taxi'), c('Zara'), c('عمر')]);
    expect([for (final (l, _) in s) l], ['A', 'Z', '#']);
    expect(s.first.$2.map((x) => x.name), ['ali', 'Amar']);
    expect(s.last.$2.length, 2);
  });

  test('search matches name or unformatted number digits', () {
    final all = [c('Ali', '+92 300 111 2222'), c('Bilal', '0321-5550000')];
    expect(searchContacts(all, 'al').length, 2);
    expect(searchContacts(all, 'bil').single.name, 'Bilal');
    expect(searchContacts(all, '3001112').single.name, 'Ali');
    expect(searchContacts(all, '  '), all);
  });

  test('avatar initials: up to two, letters only', () {
    expect(LetterAvatar.initials('Aamir Zaman'), 'AZ');
    expect(LetterAvatar.initials('Haider Abbas Kazmi'), 'HA');
    expect(LetterAvatar.initials('~Abdullah Shahid~'), 'AS'); // symbols skipped
    expect(LetterAvatar.initials('03001234567'), '');
    expect(LetterAvatar.colorFor('Wasif'), LetterAvatar.colorFor(' wasif '));
  });
}
