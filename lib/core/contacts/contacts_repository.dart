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
    this.primaryIndex = -1,
  });

  /// "Mobile", "Home", ... for each of [numbers], same order.
  final List<String> labels;

  /// Only with `start(preloadPhotos: true)` (the call screen); elsewhere use
  /// [ContactsRepository.thumbnail], which loads a photo when its row first shows.
  final Uint8List? thumbnail;
  final bool isFavorite;

  /// Index in [numbers] of Android's default number for this contact, or -1 if none is set.
  final int primaryIndex;

  /// The number to call without asking: the default, or the only number. Null means ask.
  String? get callNumber => primaryIndex >= 0 ? numbers[primaryIndex] : (numbers.length == 1 ? numbers.single : null);

  @override
  String get id => super.id!;
}

/// Device contacts, kept fresh while the app runs.
class ContactsRepository {
  ContactsRepository._();

  static final ContactsRepository instance = ContactsRepository._();

  /// Sorted by name. Notifies only when a listed contact changed (Android fires database
  /// changes after every call, and each one rebuilt Recents, Contacts and the keypad results).
  final ValueNotifier<List<DialerContact>> contacts = ValueNotifier(const []);

  /// Bumps on every reload of the contacts database, for screens that show fields [contacts]
  /// doesn't hold (emails, addresses, notes).
  final ValueNotifier<int> revision = ValueNotifier(0);
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
  /// reloads on every change to the contacts database. [preloadPhotos] also reads every
  /// thumbnail up front, for the call screen, whose layout depends on there being a photo.
  Future<void> start({bool preloadPhotos = false}) async {
    if (_changes != null) return; // already loaded and following changes
    _preloadPhotos = preloadPhotos;
    hasAccess.value = await FlutterContacts.permissions.has(PermissionType.read);
    if (!hasAccess.value) return;
    // Android fires bursts of changes (e.g. after every call); reload once they settle.
    _changes = FlutterContacts.onDatabaseChange.listen((_) {
      _reload?.cancel();
      _reload = Timer(const Duration(milliseconds: 400), _load);
    });
    await _load();
  }

  Timer? _reload;
  var _preloadPhotos = false;

  final _thumbnails = <String, Uint8List?>{};
  final _thumbnailLoads = <String, Future<Uint8List?>>{};

  /// A contact's thumbnail if it has already been loaded, for a first frame without a flash.
  Uint8List? cachedThumbnail(String id) => _thumbnails[id];

  /// A contact's 96 px thumbnail, loaded on first use and cached. A reload refetches it on
  /// next use (the old one shows meanwhile), so a changed photo turns up.
  Future<Uint8List?> thumbnail(String id) => _thumbnailLoads[id] ??= () async {
    try {
      final photo = (await FlutterContacts.get(id, properties: {ContactProperty.photoThumbnail}))?.photo?.thumbnail;
      return _thumbnails[id] = photo;
    } on Object {
      return _thumbnails[id];
    }
  }();

  final _fullPhotos = <String, Future<Uint8List?>>{};

  /// The full-resolution photo for large avatars; the 96 px thumbnail turns soft when scaled
  /// up. Cached per contact until the contacts database changes.
  Future<Uint8List?> fullPhoto(String id) => _fullPhotos[id] ??= () async {
    try {
      return (await FlutterContacts.get(id, properties: {ContactProperty.photoFullRes}))?.photo?.fullSize;
    } on Object {
      return null; // The thumbnail stays.
    }
  }();

  Future<void> _load() async {
    _fullPhotos.clear();
    _thumbnailLoads.clear();
    final all = await FlutterContacts.getAll(
      properties: {
        ContactProperty.phone,
        ContactProperty.favorite,
        if (_preloadPhotos) ContactProperty.photoThumbnail,
      },
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
            primaryIndex: phones.indexWhere((p) => p.isPrimary ?? false),
          ),
    ];
    // Lowercased once per contact, not twice per comparison.
    final keyed = [for (final e in entries) (e.name.toLowerCase(), e)]..sort((a, b) => a.$1.compareTo(b.$1));
    final sorted = [for (final (_, e) in keyed) e];
    if (!sameContacts(sorted, contacts.value)) _publish(sorted);
    revision.value++;
  }

  /// Whether [a] and [b] list the same contacts, field for field (thumbnails by content).
  @visibleForTesting
  static bool sameContacts(List<DialerContact> a, List<DialerContact> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.id != y.id ||
          x.name != y.name ||
          x.isFavorite != y.isFavorite ||
          x.primaryIndex != y.primaryIndex ||
          !listEquals(x.numbers, y.numbers) ||
          !listEquals(x.labels, y.labels) ||
          !listEquals(x.thumbnail, y.thumbnail)) {
        return false;
      }
    }
    return true;
  }

  /// Shows [entries] (sorted by name) without reading the device, e.g. demo data for store screenshots.
  @visibleForTesting
  void debugSetContacts(List<DialerContact> entries) => _publish(entries);

  void _publish(List<DialerContact> entries) {
    // Several contacts can share a number (duplicates across accounts); prefer one with a photo,
    // else the first by name, so the call screen shows the photo when any copy has one.
    final byNumber = <String, DialerContact>{};
    for (final e in entries) {
      for (final n in e.numbers) {
        final key = numberKey(n);
        final current = byNumber[key];
        if (current == null || (current.thumbnail == null && e.thumbnail != null)) byNumber[key] = e;
      }
    }
    _byNumber = byNumber;
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

  /// Makes [number] the contact's default number (Samsung's "Set as default").
  Future<void> setDefaultNumber(String id, String number) async {
    // Fetch only the phones, so update() can't touch anything else.
    final contact = await FlutterContacts.get(id, properties: {ContactProperty.phone});
    if (contact == null) return;
    final key = numberKey(number);
    await FlutterContacts.update(
      contact.copyWith(
        phones: [
          for (final p in contact.phones)
            Phone(
              number: p.number,
              normalizedNumber: p.normalizedNumber,
              label: p.label,
              isPrimary: numberKey(p.number) == key,
            ),
        ],
      ),
    );
  }

  Future<void> delete(List<String> ids) => FlutterContacts.deleteAll(ids);

  /// Stars or unstars a contact (Android's favourites).
  Future<void> setFavorite(String id, bool favorite) async {
    // Fetch only the favourite flag, so update() can't touch anything else.
    final contact = await FlutterContacts.get(id, properties: {ContactProperty.favorite});
    if (contact == null) return;
    await FlutterContacts.update(contact.copyWith(android: AndroidData(isFavorite: favorite)));
  }
}
