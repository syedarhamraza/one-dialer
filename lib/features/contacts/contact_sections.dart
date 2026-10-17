import '../../core/contacts/contacts_repository.dart';

/// A–Z sections (letters in order, then "#" for names not starting with a Latin letter).
List<(String, List<DialerContact>)> sectionContacts(List<DialerContact> contacts) {
  final byLetter = <String, List<DialerContact>>{};
  for (final c in contacts) {
    final first = c.name.isEmpty ? '#' : c.name[0].toUpperCase();
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
