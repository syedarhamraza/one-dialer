import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../l10n/l10n.dart';

/// A labelled value (phone, email, website, relation). [label] is a label enum's name
/// (`mobile`) or, for a custom label, the user's own text.
class LabeledValue {
  LabeledValue({this.label = '', this.value = '', this.isPrimary});

  String label;
  String value;

  /// Carried through so editing doesn't reset Android's default number.
  final bool? isPrimary;

  Map<String, Object?> toJson() => {'l': label, 'v': value};
}

class AddressValue {
  AddressValue({
    this.label = 'home',
    this.street = '',
    this.city = '',
    this.region = '',
    this.postcode = '',
    this.country = '',
    this.original,
  });

  String label, street, city, region, postcode, country;

  /// The loaded address, so fields the editor doesn't show (PO box, neighbourhood...) survive.
  final Address? original;

  bool get isEmpty => [street, city, region, postcode, country].every((s) => s.trim().isEmpty);

  Map<String, Object?> toJson() => {'l': label, 's': street, 'c': city, 'r': region, 'p': postcode, 'n': country};
}

class DateValue {
  DateValue({this.label = 'birthday', this.year, required this.month, required this.day});

  String label;
  int? year;
  int month, day;

  Map<String, Object?> toJson() => {'l': label, 'y': year, 'm': month, 'd': day};
}

/// The editor's state for one contact, converted to and from flutter_contacts' [Contact].
/// Pure Dart so it can be unit tested; the screen only reads and writes these fields.
class ContactForm {
  ContactForm();

  String prefix = '', first = '', middle = '', last = '', suffix = '';
  final List<LabeledValue> phones = [];
  final List<LabeledValue> emails = [];
  final List<AddressValue> addresses = [];
  String company = '', jobTitle = '', department = '';
  final List<DateValue> dates = [];
  final List<LabeledValue> websites = [];
  final List<LabeledValue> relations = [];
  String notes = '';
  Set<String> groupIds = {};

  /// New photo bytes; null with [photoRemoved] false means "unchanged".
  Uint8List? newPhoto;
  bool photoRemoved = false;

  factory ContactForm.fromContact(Contact c, {Set<String> groupIds = const {}}) {
    final f = ContactForm();
    final n = c.name;
    f
      ..prefix = n?.prefix ?? ''
      ..first = n?.first ?? ''
      ..middle = n?.middle ?? ''
      ..last = n?.last ?? ''
      ..suffix = n?.suffix ?? '';
    if (n == null && (c.displayName?.isNotEmpty ?? false)) f.fullName = c.displayName!;
    f.phones.addAll([
      for (final p in c.phones) LabeledValue(label: labelText(p.label), value: p.number, isPrimary: p.isPrimary),
    ]);
    f.emails.addAll([
      for (final e in c.emails) LabeledValue(label: labelText(e.label), value: e.address, isPrimary: e.isPrimary),
    ]);
    f.addresses.addAll([
      for (final a in c.addresses)
        AddressValue(
          label: labelText(a.label),
          street: a.street ?? a.formatted ?? '',
          city: a.city ?? '',
          region: a.state ?? '',
          postcode: a.postalCode ?? '',
          country: a.country ?? '',
          original: a,
        ),
    ]);
    final org = c.organizations.firstOrNull;
    f
      ..company = org?.name ?? ''
      ..jobTitle = org?.jobTitle ?? ''
      ..department = org?.departmentName ?? '';
    f.dates.addAll([
      for (final e in c.events) DateValue(label: labelText(e.label), year: e.year, month: e.month, day: e.day),
    ]);
    f.websites.addAll([for (final w in c.websites) LabeledValue(label: labelText(w.label), value: w.url)]);
    f.relations.addAll([for (final r in c.relations) LabeledValue(label: labelText(r.label), value: r.name)]);
    f.notes = c.notes.map((n) => n.note).join('\n');
    f.groupIds = {...groupIds};
    return f;
  }

  /// The name as one line, like Samsung's collapsed Name field.
  String get fullName => [prefix, first, middle, last, suffix].where((s) => s.trim().isNotEmpty).join(' ');

  /// Sets the name from one line: first word is the first name, the rest the last name.
  set fullName(String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    prefix = middle = suffix = '';
    first = words.isEmpty ? '' : words.first;
    last = words.length > 1 ? words.sublist(1).join(' ') : '';
  }

  /// Nothing worth saving (Samsung disables Save then).
  bool get isEmpty =>
      fullName.isEmpty &&
      phones.every((p) => p.value.trim().isEmpty) &&
      emails.every((e) => e.value.trim().isEmpty) &&
      company.trim().isEmpty &&
      newPhoto == null;

  /// Stable fingerprint, to detect unsaved changes.
  String get signature => jsonEncode({
    'n': [prefix, first, middle, last, suffix],
    // The always-there blank phone row isn't a change.
    'p': [
      for (final p in phones)
        if (p.value.trim().isNotEmpty) p.toJson(),
    ],
    'e': emails.map((e) => e.toJson()).toList(),
    'a': addresses.map((e) => e.toJson()).toList(),
    'o': [company, jobTitle, department],
    'd': dates.map((e) => e.toJson()).toList(),
    'w': websites.map((e) => e.toJson()).toList(),
    'r': relations.map((e) => e.toJson()).toList(),
    'x': notes,
    'g': (groupIds.toList()..sort()),
    'ph': newPhoto?.length,
    'pr': photoRemoved,
  });

  /// Applies the form onto [base] (the fully loaded contact when editing, `Contact()` when
  /// creating). Blank rows are dropped; properties the editor doesn't show are kept.
  Contact applyTo(Contact base) {
    String t(String s) => s.trim();
    String? orNull(String s) => t(s).isEmpty ? null : t(s);
    final orgs = [...base.organizations];
    final hasWork = [company, jobTitle, department].any((s) => t(s).isNotEmpty);
    if (orgs.isNotEmpty) {
      orgs[0] = Organization(
        name: orNull(company),
        jobTitle: orNull(jobTitle),
        departmentName: orNull(department),
        phoneticName: orgs[0].phoneticName,
        jobDescription: orgs[0].jobDescription,
        symbol: orgs[0].symbol,
        officeLocation: orgs[0].officeLocation,
      );
      if (!hasWork && orgs.length == 1) orgs.clear();
    } else if (hasWork) {
      orgs.add(Organization(name: orNull(company), jobTitle: orNull(jobTitle), departmentName: orNull(department)));
    }

    return base.copyWith(
      // A new Name (copyWith can't clear a part); keeps the parts the editor doesn't show.
      name: Name(
        prefix: orNull(prefix),
        first: orNull(first),
        middle: orNull(middle),
        last: orNull(last),
        suffix: orNull(suffix),
        nickname: base.name?.nickname,
        phoneticFirst: base.name?.phoneticFirst,
        phoneticMiddle: base.name?.phoneticMiddle,
        phoneticLast: base.name?.phoneticLast,
        previousFamilyName: base.name?.previousFamilyName,
      ),
      phones: [
        for (final p in phones)
          if (t(p.value).isNotEmpty)
            Phone(
              number: t(p.value),
              label: toLabel(PhoneLabel.values, PhoneLabel.custom, p.label),
              isPrimary: p.isPrimary,
            ),
      ],
      emails: [
        for (final e in emails)
          if (t(e.value).isNotEmpty)
            Email(
              address: t(e.value),
              label: toLabel(EmailLabel.values, EmailLabel.custom, e.label),
              isPrimary: e.isPrimary,
            ),
      ],
      addresses: [
        for (final a in addresses)
          if (!a.isEmpty)
            Address(
              street: orNull(a.street),
              city: orNull(a.city),
              state: orNull(a.region),
              postalCode: orNull(a.postcode),
              country: orNull(a.country),
              poBox: a.original?.poBox,
              neighborhood: a.original?.neighborhood,
              subLocality: a.original?.subLocality,
              subAdministrativeArea: a.original?.subAdministrativeArea,
              isoCountryCode: a.original?.isoCountryCode,
              label: toLabel(AddressLabel.values, AddressLabel.custom, a.label),
            ),
      ],
      organizations: orgs,
      events: [
        for (final d in dates)
          Event(
            year: d.year,
            month: d.month,
            day: d.day,
            label: toLabel(EventLabel.values, EventLabel.custom, d.label),
          ),
      ],
      websites: [
        for (final w in websites)
          if (t(w.value).isNotEmpty)
            Website(url: t(w.value), label: toLabel(WebsiteLabel.values, WebsiteLabel.custom, w.label)),
      ],
      relations: [
        for (final r in relations)
          if (t(r.value).isNotEmpty)
            Relation(name: t(r.value), label: toLabel(RelationLabel.values, RelationLabel.custom, r.label)),
      ],
      notes: t(notes).isEmpty ? const [] : [Note(note: t(notes))],
      photo: newPhoto == null ? null : Photo(fullSize: newPhoto),
      clearPhoto: photoRemoved && newPhoto == null,
    );
  }
}

/// A label's text for the form: the enum name, or the custom text.
String labelText<T extends Enum>(Label<T> label) =>
    label.label.name == 'custom' ? (label.customLabel ?? '') : label.label.name;

/// The form's label text back to a [Label]: a known enum name, else a custom label.
Label<T> toLabel<T extends Enum>(List<T> values, T custom, String text) {
  for (final v in values) {
    if (v.name == text && v != custom) return Label(v);
  }
  return Label(custom, text.trim().isEmpty ? 'Other' : text.trim());
}

/// A label in the app's language ("mobile" → "Mobile"/"Cellulare"); custom labels as typed,
/// and enum names without a translation spaced out ("workMms" → "Work mms").
String labelDisplay(AppLocalizations l10n, String label) {
  if (label.isEmpty) return l10n.contactLabel('other');
  final known = l10n.contactLabel(label[0].toLowerCase() + label.substring(1));
  if (label.toLowerCase() == 'other' || known != l10n.contactLabel('other')) return known;
  final spaced = label.replaceAllMapped(RegExp(r'(?<=[a-z])([A-Z])'), (m) => ' ${m[1]!.toLowerCase()}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}
