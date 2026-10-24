import '../../core/contacts/contacts_repository.dart';
import '../recents/call_log.dart' show numberKey;

/// A–Z sections by [DialerContact.sortKey] (letters in order, then "#" for keys not starting
/// with a Latin letter).
List<(String, List<DialerContact>)> sectionContacts(List<DialerContact> contacts) {
  final byLetter = <String, List<DialerContact>>{};
  for (final c in contacts) {
    final key = c.sortKey;
    final first = key.isEmpty ? '#' : key[0].toUpperCase();
    final letter = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
    (byLetter[letter] ??= []).add(c);
  }
  final letters = byLetter.keys.where((l) => l != '#').toList()..sort();
  if (byLetter.containsKey('#')) letters.add('#');
  return [for (final l in letters) (l, byLetter[l]!)];
}

/// Name or any number contains [query] (digits compared without formatting).
List<DialerContact> searchContacts(List<DialerContact> contacts, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return contacts;
  final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
  return [
    for (final c in contacts)
      if (c.name.toLowerCase().contains(q) ||
          (digits.isNotEmpty && c.numbers.any((n) => n.replaceAll(RegExp(r'[^0-9]'), '').contains(digits))))
        c,
  ];
}

/// Merge duplicates: contacts that share a number or the same name (ignoring case and
/// spaces), each group in list order. Contacts alone are left out.
List<List<DialerContact>> duplicateGroups(List<DialerContact> contacts) {
  // Union-find over list indices, joined through shared keys.
  final parent = List.generate(contacts.length, (i) => i);
  int root(int i) => parent[i] == i ? i : parent[i] = root(parent[i]);
  final owner = <String, int>{};
  for (final (i, c) in contacts.indexed) {
    final name = c.name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    for (final key in [
      if (name.isNotEmpty) 'name:$name',
      for (final n in c.numbers)
        if (numberKey(n) case final k when k.isNotEmpty) 'number:$k',
    ]) {
      final other = owner[key];
      if (other == null) {
        owner[key] = i;
      } else {
        parent[root(i)] = root(other);
      }
    }
  }
  final groups = <int, List<DialerContact>>{};
  for (final (i, c) in contacts.indexed) {
    (groups[root(i)] ??= []).add(c);
  }
  return [
    for (final g in groups.values)
      if (g.length > 1) g,
  ];
}
