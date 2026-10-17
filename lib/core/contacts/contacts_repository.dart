import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../features/keypad/t9.dart';
import '../../features/recents/call_log.dart';

/// A device contact with at least one phone number. Usable directly as a T9 entry.
class DialerContact extends T9Entry {
  const DialerContact({
    required String super.id,
    required super.name,
    required super.numbers,
    required this.labels,
    this.thumbnail,
    this.isFavorite = false,
  });

  /// "Mobile", "Home", ... for each of [numbers], same order.
  final List<String> labels;
  final Uint8List? thumbnail;
  final bool isFavorite;

  @override
  String get id => super.id!;
}

/// Device contacts, kept fresh while the app runs.
class ContactsRepository {
  ContactsRepository._();

  static final ContactsRepository instance = ContactsRepository._();

  /// Sorted by name.
  final ValueNotifier<List<DialerContact>> contacts = ValueNotifier(const []);
  StreamSubscription<void>? _changes;
  Map<String, DialerContact> _byNumber = const {};

  /// False until READ_CONTACTS is granted.
  final ValueNotifier<bool> hasAccess = ValueNotifier(true);

  /// The saved contact for [number], matched by [numberKey].
  DialerContact? contactFor(String number) {
    final key = numberKey(number);
    return key.isEmpty ? null : _byNumber[key];
  }

  /// The saved contact name for [number].
  String? nameFor(String number) => contactFor(number)?.name;

  /// Loads contacts if READ_CONTACTS is granted (the dialer role grants it), then
  /// reloads on every change to the contacts database.
  Future<void> start() async {
    hasAccess.value = await FlutterContacts.permissions.has(PermissionType.read);
    if (!hasAccess.value) return;
    _changes ??= FlutterContacts.onDatabaseChange.listen((_) => _load());
    await _load();
  }

  Future<void> _load() async {
    final all = await FlutterContacts.getAll(
      properties: {ContactProperty.phone, ContactProperty.photoThumbnail, ContactProperty.favorite},
    );
    final entries = [
      for (final c in all)
        if (_uniquePhones(c.phones) case final phones when phones.isNotEmpty && c.id != null)
          DialerContact(
            id: c.id!,
            name: (c.displayName?.trim().isNotEmpty ?? false) ? c.displayName!.trim() : phones.first.number,
            numbers: [for (final p in phones) p.number],
            labels: [for (final p in phones) _label(p.label)],
            thumbnail: c.photo?.thumbnail,
            isFavorite: c.android?.isFavorite ?? false,
          ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _byNumber = {
      for (final e in entries)
        for (final n in e.numbers) numberKey(n): e,
    };
    contacts.value = entries;
  }

  /// Linked accounts (Google, WhatsApp, ...) each carry a copy of the same number; keep one.
  static List<Phone> _uniquePhones(List<Phone> phones) {
    final seen = <String>{};
    return [
      for (final p in phones)
        if (seen.add(numberKey(p.number))) p,
    ];
  }

  static String _label(Label<PhoneLabel> label) {
    final custom = label.customLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final name = label.label.name;
    return name == 'custom' ? 'Phone' : '${name[0].toUpperCase()}${name.substring(1)}';
  }

  /// Asks for contacts access; opens app settings if it was denied for good. Returns whether granted.
  Future<bool> requestAccess() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    if (status == PermissionStatus.permanentlyDenied) await FlutterContacts.permissions.openSettings();
    await start();
    return hasAccess.value;
  }

  /// Stars or unstars a contact (Android's favourites).
  Future<void> setFavorite(String id, bool favorite) async {
    // Fetch only the favourite flag, so update() can't touch anything else.
    final contact = await FlutterContacts.get(id, properties: {ContactProperty.favorite});
    if (contact == null) return;
    await FlutterContacts.update(contact.copyWith(android: AndroidData(isFavorite: favorite)));
  }
}
