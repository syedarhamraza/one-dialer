/// Samsung-style T9 search over contacts: typed keypad digits match a name from the
/// start of any word (continuing across later words), the name's initials, or any
/// part of a phone number.
library;

class T9Entry {
  const T9Entry({required this.name, required this.numbers, this.id});

  final String? id;
  final String name;
  final List<String> numbers;
}

class T9Match {
  const T9Match({required this.entry, required this.number, this.nameRange, this.numberRange});

  final T9Entry entry;

  /// The number to call for this result.
  final String number;

  /// `[start, end)` of matched characters in [T9Entry.name], for highlighting.
  final (int, int)? nameRange;

  /// `[start, end)` of matched characters in [number].
  final (int, int)? numberRange;
}

const _keys = {
  'a': '2',
  'b': '2',
  'c': '2',
  'd': '3',
  'e': '3',
  'f': '3',
  'g': '4',
  'h': '4',
  'i': '4',
  'j': '5',
  'k': '5',
  'l': '5',
  'm': '6',
  'n': '6',
  'o': '6',
  'p': '7',
  'q': '7',
  'r': '7',
  's': '7',
  't': '8',
  'u': '8',
  'v': '8',
  'w': '9',
  'x': '9',
  'y': '9',
  'z': '9',
};

// Built once: these run per character of every contact on each keypad digit.
final _digit = RegExp(r'[0-9]');
final _allDigits = RegExp(r'^[0-9]+$');
final _dialChar = RegExp(r'[0-9+*#]');

String? _digitOf(String ch) {
  final c = ch.toLowerCase();
  if (_keys[c] case final d?) return d;
  return _digit.hasMatch(c) ? c : null;
}

/// Returns matches for [query] (keypad digits, may include `*`, `#`, `+`), best first:
/// names matched at the first word, then names matched later or by initials, then numbers.
List<T9Match> t9Search(String query, Iterable<T9Entry> entries, {int limit = 50}) {
  if (query.isEmpty) return const [];
  final digitsOnly = _allDigits.hasMatch(query);
  final first = <T9Match>[];
  final other = <T9Match>[];
  final byNumber = <T9Match>[];

  for (final entry in entries) {
    if (entry.numbers.isEmpty) continue;
    final nameMatch = digitsOnly ? _matchName(query, entry.name) : null;
    if (nameMatch != null) {
      (nameMatch.$1 == 0 ? first : other).add(T9Match(entry: entry, number: entry.numbers.first, nameRange: nameMatch));
      continue;
    }
    for (final number in entry.numbers) {
      final range = _matchNumber(query, number);
      if (range != null) {
        byNumber.add(T9Match(entry: entry, number: number, numberRange: range));
        break;
      }
    }
  }
  return [...first, ...other, ...byNumber].take(limit).toList();
}

/// Name characters that carry a digit, with their index in the original name and
/// whether they start a word.
List<(int, String, bool)> _letters(String name) {
  final out = <(int, String, bool)>[];
  var wordStart = true;
  for (var i = 0; i < name.length; i++) {
    final d = _digitOf(name[i]);
    if (d == null) {
      wordStart = true;
      continue;
    }
    out.add((i, d, wordStart));
    wordStart = false;
  }
  return out;
}

(int, int)? _matchName(String query, String name) {
  final letters = _letters(name);
  // From the start of any word, continuing through the rest of the name.
  for (var s = 0; s < letters.length; s++) {
    if (!letters[s].$3 || s + query.length > letters.length) continue;
    var ok = true;
    for (var k = 0; k < query.length && ok; k++) {
      ok = letters[s + k].$2 == query[k];
    }
    if (ok) return (letters[s].$1, letters[s + query.length - 1].$1 + 1);
  }
  // Initials: "53" finds "John Doe". Highlight covers first to last matched initial.
  final initials = letters.where((l) => l.$3).toList();
  if (query.length > 1 && query.length <= initials.length) {
    for (var s = 0; s + query.length <= initials.length; s++) {
      var ok = true;
      for (var k = 0; k < query.length && ok; k++) {
        ok = initials[s + k].$2 == query[k];
      }
      if (ok) return (initials[s].$1, initials[s + query.length - 1].$1 + 1);
    }
  }
  return null;
}

/// Matches [query] inside [number], ignoring spaces, dashes and brackets in the number.
(int, int)? _matchNumber(String query, String number) {
  final kept = <int>[]; // index in number of each kept char
  final buf = StringBuffer();
  for (var i = 0; i < number.length; i++) {
    if (_dialChar.hasMatch(number[i])) {
      kept.add(i);
      buf.write(number[i]);
    }
  }
  final digits = buf.toString();
  var at = digits.indexOf(query);
  var length = query.length;
  // Typed national form against a saved international one: "0370…" finds "+92 370…",
  // the leading 0 standing in for a 1–3 digit country code.
  if (at < 0 && query.length >= 4 && query.startsWith('0') && digits.startsWith('+')) {
    final rest = query.substring(1);
    // A short saved number ("+92") can't hold a longer code; startsWith throws past its end.
    for (var code = 1; code <= 3 && at < 0 && 1 + code <= digits.length; code++) {
      if (digits.startsWith(rest, 1 + code)) {
        at = 1 + code;
        length = rest.length;
      }
    }
  }
  if (at < 0) return null;
  return (kept[at], kept[at + length - 1] + 1);
}
