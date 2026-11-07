import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../features/keypad/t9.dart';
import '../../features/recents/call_log.dart';
import '../prefs/dialer_prefs.dart';
import '../telecom/telecom_bridge.dart';
import '../diagnostics/lag_diagnostics.dart';

/// A device contact. Usable directly as a T9 entry; only [ContactsRepository.allContacts]
/// holds contacts without numbers.
class DialerContact extends T9Entry {
  const DialerContact({
    required String super.id,
    required super.name,
    required super.numbers,
    required this.labels,
    this.isFavorite = false,
    this.primaryIndex = -1,
    this._sortKey,
    this.accounts = const [],
  });

  /// "Mobile", "Home", ... for each of [numbers], same order.
  final List<String> labels;

  final bool isFavorite;

  /// Index in [numbers] of Android's default number for this contact, or -1 if none is set.
  final int primaryIndex;

  final String? _sortKey;

  /// What the A–Z list sorts and buckets by (Manage contacts › Sort by), lowercased.
  String get sortKey => _sortKey ?? name.toLowerCase();

  /// The accounts holding a copy, as `type|name`; empty for a contact only on the phone.
  final List<String> accounts;

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

  /// [contacts] plus those without a number, for Manage contacts' "Only display contacts
  /// with numbers" turned off and for Merge duplicates.
  final ValueNotifier<List<DialerContact>> allContacts = ValueNotifier(const []);

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
  /// reloads on every change to the contacts database. Photos load per contact through
  /// [thumbnail]: reading them all here froze the call screen for seconds on each reload.
  Future<void> start() async {
    if (_changes != null) return; // already loaded and following changes
    hasAccess.value = await FlutterContacts.permissions.has(PermissionType.read);
    if (!hasAccess.value) return;
    // Android fires bursts of changes (e.g. after every call); reload once they settle.
    _changes = FlutterContacts.onDatabaseChange.listen((_) => reload());
    // Names and order follow Manage contacts.
    Listenable.merge([DialerPrefs.instance.sortBy, DialerPrefs.instance.nameOrder]).addListener(reload);
    await _load();
  }

  /// Reloads once a burst of changes settles.
  void reload() {
    if (ignoreChanges) return;
    _reload?.cancel();
    _reload = Timer(const Duration(milliseconds: 400), _load);
  }

  Timer? _reload;

  /// Set by the cached in-call engine: it keeps its first load. flutter_contacts encodes the whole
  /// list on Android's main thread, which froze the app for seconds after every call (Android
  /// rewrites contacts then). Telecom still names a contact saved since (CallInfo.name).
  bool ignoreChanges = false;

  final _thumbnails = <String, Uint8List?>{};
  final _thumbnailLoads = <String, Future<Uint8List?>>{};

  /// A contact's thumbnail if it has already been loaded, for a first frame without a flash.
  Uint8List? cachedThumbnail(String id) => _thumbnails[id];

  /// A contact's 96 px thumbnail, loaded on first use and cached. A reload refetches it on
  /// next use (the old one shows meanwhile), so a changed photo turns up.
  Future<Uint8List?> thumbnail(String id) => _thumbnailLoads[id] ??= () async {
    try {
      final photo = (await FlutterContacts.get(id, properties: {ContactProperty.photoThumbnail}))?.photo?.thumbnail;
      return _thumbnails[id] = samePhoto(_thumbnails[id], photo);
    } on Object {
      return _thumbnails[id];
    }
  }();

  /// [fresh], or [old] when the bytes are the same: MemoryImage compares bytes by identity, so a
  /// new copy of an unchanged photo would decode it again in every visible row after a reload.
  @visibleForTesting
  static Uint8List? samePhoto(Uint8List? old, Uint8List? fresh) =>
      old != null && fresh != null && listEquals(old, fresh) ? old : fresh;

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
    final diagnosticTimer = Stopwatch()..start();
    LagDiagnostics.instance.action(DiagnosticAction.contactsLoad);
    try {
      _fullPhotos.clear();
      _thumbnailLoads.clear();
      final prefs = DialerPrefs.instance;
      final entries = entriesFrom(
        await TelecomBridge.instance.getContacts(),
        order: prefs.nameOrder.value,
        sortBy: prefs.sortBy.value,
      );
      entries.sort((a, b) => a.sortKey.compareTo(b.sortKey));
      final numbered = [
        for (final e in entries)
          if (e.numbers.isNotEmpty) e,
      ];
      if (!sameContacts(entries, allContacts.value)) allContacts.value = entries;
      if (!sameContacts(numbered, contacts.value)) _publish(numbered);
      revision.value++;
    } finally {
      LagDiagnostics.instance.action(DiagnosticAction.contactsLoad, elapsed: diagnosticTimer.elapsed);
    }
  }

  /// [DialerContact]s from `ContactsSource.kt`'s rows, unsorted.
  @visibleForTesting
  static List<DialerContact> entriesFrom(List<List<Object?>> rows, {required String order, required String sortBy}) {
    final entries = <DialerContact>[];
    for (final r in rows) {
      final phones = _uniquePhones([
        for (final p in (r[6] as List).cast<List<Object?>>())
          Phone(
            number: p[0] as String,
            label: Label(PhoneLabel.values.asNameMap()[p[1]] ?? PhoneLabel.custom, p[2] as String?),
            isPrimary: p[3] == true,
          ),
      ]);
      final display = (r[1] as String?)?.trim() ?? '';
      final fallback = display.isNotEmpty ? display : (phones.isEmpty ? '' : phones.first.number);
      if (fallback.isEmpty) continue;
      final (name, sortKey) = displayNames(
        first: r[2] as String?,
        middle: r[3] as String?,
        last: r[4] as String?,
        fallback: fallback,
        order: order,
        sortBy: sortBy,
      );
      entries.add(
        DialerContact(
          id: r[0] as String,
          name: name,
          sortKey: sortKey,
          numbers: [for (final p in phones) p.number],
          labels: [for (final p in phones) _label(p.label)],
          isFavorite: r[5] == true,
          primaryIndex: phones.indexWhere((p) => p.isPrimary ?? false),
          accounts: (r[7] as List).cast<String>(),
        ),
      );
    }
    return entries;
  }

  /// The name to show in [order] (`first` or `last` first) and the sort key by [sortBy],
  /// from Android's structured name. The display name stays when the structured one is
  /// empty or already in the order asked for.
  @visibleForTesting
  static (String, String) displayNames({
    String? first,
    String? middle,
    String? last,
    required String fallback,
    required String order,
    required String sortBy,
  }) {
    String join(List<String?> parts) => [
      for (final p in parts)
        if (p?.trim() case final t? when t.isNotEmpty) t,
    ].join(' ');
    final lastFirst = join([last, first, middle]);
    if (join([first, middle, last]).isEmpty) return (fallback, fallback.toLowerCase());
    return (order == 'last' ? lastFirst : fallback, (sortBy == 'last' ? lastFirst : fallback).toLowerCase());
  }

  /// Whether [a] and [b] list the same contacts, field for field.
  @visibleForTesting
  static bool sameContacts(List<DialerContact> a, List<DialerContact> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.id != y.id ||
          x.name != y.name ||
          x.sortKey != y.sortKey ||
          !listEquals(x.accounts, y.accounts) ||
          x.isFavorite != y.isFavorite ||
          x.primaryIndex != y.primaryIndex ||
          !listEquals(x.numbers, y.numbers) ||
          !listEquals(x.labels, y.labels)) {
        return false;
      }
    }
    return true;
  }

  /// Shows [entries] (sorted by name) without reading the device, e.g. demo data for store screenshots.
  @visibleForTesting
  void debugSetContacts(List<DialerContact> entries) {
    allContacts.value = entries;
    _publish([
      for (final e in entries)
        if (e.numbers.isNotEmpty) e,
    ]);
  }

  void _publish(List<DialerContact> entries) {
    // Several contacts can share a number (duplicates across accounts); the first by name wins.
    final byNumber = <String, DialerContact>{};
    for (final e in entries) {
      for (final n in e.numbers) {
        byNumber.putIfAbsent(numberKey(n), () => e);
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
    return name == 'custom' ? 'phone' : name; // shown through labelDisplay
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
