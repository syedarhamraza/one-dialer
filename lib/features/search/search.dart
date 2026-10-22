import '../../core/contacts/contacts_repository.dart';

/// A contact found by name or number; [number] is the one to show (the matching one when
/// the query was digits), [nameRange] the part of the name to highlight.
typedef ContactHit = ({DialerContact contact, String number, (int, int)? nameRange, (int, int)? numberRange});

final _nonDigit = RegExp(r'\D');
final _digit = RegExp(r'\d');
final _numberPunctuation = RegExp(r'[\s()+\-]');

String _digits(String s) => s.replaceAll(_nonDigit, '');

/// Names lowercased and numbers reduced to digits once per list, not on every keystroke.
/// The list is an immutable snapshot from the repository, so identity says whether it's stale.
class _Index {
  _Index(this.source, this.names, this.numbers);

  final List<DialerContact> source;
  final List<String> names;
  final List<List<String>> numbers;
}

_Index? _contactIndex;

/// Case-insensitive substring range of [query] in [text], or null.
(int, int)? matchRange(String text, String query) {
  if (query.isEmpty) return null;
  final i = text.toLowerCase().indexOf(query.toLowerCase());
  return i < 0 ? null : (i, i + query.length);
}

/// Digit-only match inside a formatted number ("+92 336 80…"), as a range of [number].
(int, int)? numberRange(String number, String query) {
  final q = _digits(query);
  if (q.isEmpty || q.length != query.replaceAll(_numberPunctuation, '').length) return null;
  final i = _digits(number).indexOf(q);
  if (i < 0) return null;
  // Map digit positions back to positions in the formatted number.
  final positions = [
    for (var j = 0; j < number.length; j++)
      if (_digit.hasMatch(number[j])) j,
  ];
  return (positions[i], positions[i + q.length - 1] + 1);
}

/// The query's digits when it's a number search ("0336 80", "+92-336"), else null.
String? _digitQuery(String q) {
  final d = _digits(q);
  return d.isEmpty || d.length != q.replaceAll(_numberPunctuation, '').length ? null : d;
}

List<ContactHit> searchContacts(List<DialerContact> contacts, String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final index = identical(_contactIndex?.source, contacts)
      ? _contactIndex!
      : _contactIndex = _Index(
          contacts,

          [for (final c in contacts) c.name.toLowerCase()],
          [
            for (final c in contacts) [for (final n in c.numbers) _digits(n)],
          ],
        );
  final lower = q.toLowerCase();
  final digits = _digitQuery(q);
  final hits = <ContactHit>[];
  for (var i = 0; i < contacts.length; i++) {
    final c = contacts[i];
    final at = index.names[i].indexOf(lower);
    if (at >= 0) {
      final range = (at, at + q.length);
      hits.add((contact: c, number: c.callNumber ?? c.numbers.firstOrNull ?? '', nameRange: range, numberRange: null));
      continue;
    }
    if (digits == null) continue;
    final numbers = index.numbers[i];
    for (var k = 0; k < numbers.length; k++) {
      // Positions in the formatted number only for a hit.
      if (numbers[k].contains(digits)) {
        final n = c.numbers[k];
        hits.add((contact: c, number: n, nameRange: null, numberRange: numberRange(n, q)));
        break;
      }
    }
  }
  return hits;
}
