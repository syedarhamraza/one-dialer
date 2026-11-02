import 'dart:typed_data';

import 'package:dialer/features/contacts/editor/contact_form.dart';
import 'package:dialer/l10n/app_localizations_en.dart';
import 'package:dialer/l10n/app_localizations_it.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final loaded = Contact(
    id: '7',
    name: const Name(first: 'Wasif', last: 'Khan', nickname: 'Wasi'),
    phones: const [
      Phone(number: '+92 311 1234567', label: Label(PhoneLabel.mobile), isPrimary: true),
      Phone(number: '0300 1', label: Label(PhoneLabel.custom, 'Office line')),
    ],
    emails: const [Email(address: 'w@example.com', label: Label(EmailLabel.work))],
    addresses: const [Address(street: '1 Mall Rd', city: 'Lahore', poBox: '42', label: Label(AddressLabel.home))],
    organizations: const [Organization(name: 'Acme', jobTitle: 'Engineer', officeLocation: 'B2')],
    events: const [Event(year: 1999, month: 4, day: 12, label: Label(EventLabel.birthday))],
    notes: const [Note(note: 'Met at uni')],
  );

  test('round-trips a contact without losing fields the editor does not show', () {
    final out = ContactForm.fromContact(loaded).applyTo(loaded);

    expect(out.name!.first, 'Wasif');
    expect(out.name!.nickname, 'Wasi'); // not in the editor, kept
    expect(out.phones.map((p) => p.number), ['+92 311 1234567', '0300 1']);
    expect(out.phones.first.isPrimary, isTrue);
    expect(out.phones.last.label.label, PhoneLabel.custom);
    expect(out.phones.last.label.customLabel, 'Office line');
    expect(out.addresses.single.poBox, '42'); // not in the editor, kept
    expect(out.organizations.single.officeLocation, 'B2');
    expect(out.events.single.year, 1999);
    expect(out.notes.single.note, 'Met at uni');
  });

  test('drops blank rows and clears emptied fields', () {
    final form = ContactForm.fromContact(loaded)
      ..phones.add(LabeledValue(label: 'mobile', value: '   '))
      ..emails.clear()
      ..company = ''
      ..jobTitle = ''
      ..department = ''
      ..notes = ' ';
    form.last = '';
    final out = form.applyTo(loaded);

    expect(out.phones.length, 2);
    expect(out.emails, isEmpty);
    expect(out.organizations, isEmpty);
    expect(out.notes, isEmpty);
    expect(out.name!.last, isNull);
  });

  test('one-line name splits into first and last', () {
    final form = ContactForm()..fullName = '  Syed Arham  Raza ';
    expect(form.first, 'Syed');
    expect(form.last, 'Arham Raza');
    expect(form.fullName, 'Syed Arham Raza');
  });

  test('labels map to enums, unknown text becomes a custom label', () {
    expect(toLabel(PhoneLabel.values, PhoneLabel.custom, 'workMobile').label, PhoneLabel.workMobile);
    final custom = toLabel(PhoneLabel.values, PhoneLabel.custom, 'Grandma');
    expect(custom.label, PhoneLabel.custom);
    expect(custom.customLabel, 'Grandma');
    expect(labelDisplay(AppLocalizationsEn(), 'workMobile'), 'Work mobile');
    expect(labelDisplay(AppLocalizationsEn(), 'Grandma'), 'Grandma');
    expect(labelDisplay(AppLocalizationsEn(), 'Mobile'), 'Mobile');
    expect(labelDisplay(AppLocalizationsIt(), 'mobile'), 'Cellulare');
    expect(labelDisplay(AppLocalizationsIt(), 'Grandma'), 'Grandma');
  });

  test('signature changes on edits; empty form is empty', () {
    final form = ContactForm.fromContact(loaded);
    final before = form.signature;
    form.phones.first.value = '123';
    expect(form.signature, isNot(before));
    expect(ContactForm().isEmpty, isTrue);
    expect((ContactForm()..newPhoto = Uint8List(1)).isEmpty, isFalse);
  });

  test('photo: new bytes set it, remove clears it', () {
    final withPhoto = (ContactForm()..newPhoto = Uint8List.fromList([1, 2])).applyTo(const Contact());
    expect(withPhoto.photo?.fullSize, [1, 2]);
    final base = const Contact(photo: Photo(fullSize: null));
    final removed = (ContactForm()..photoRemoved = true).applyTo(base);
    expect(removed.photo, isNull);
  });
}
