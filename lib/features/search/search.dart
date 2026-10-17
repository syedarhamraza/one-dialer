import '../../core/contacts/contacts_repository.dart';
import '../recents/call_log.dart';

/// Search page "Call time" chips.
enum CallTime {
  yesterday('Yesterday'),
  week('Past 7 days'),
  month('Past 30 days');

  const CallTime(this.label);
  final String label;

  bool matches(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      CallTime.yesterday => !date.isBefore(today.subtract(const Duration(days: 1))) && date.isBefore(today),
      CallTime.week => date.isAfter(now.subtract(const Duration(days: 7))),
      CallTime.month => date.isAfter(now.subtract(const Duration(days: 30))),
    };
  }
}

/// A contact found by name or number; [number] is the one to show (the matching one when
/// the query was digits), [nameRange] the part of the name to highlight.
typedef ContactHit = ({DialerContact contact, String number, (int, int)? nameRange, (int, int)? numberRange});

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Case-insensitive substring range of [query] in [text], or null.
(int, int)? matchRange(String text, String query) {
  if (query.isEmpty) return null;
  final i = text.toLowerCase().indexOf(query.toLowerCase());
  return i < 0 ? null : (i, i + query.length);
}

/// Digit-only match inside a formatted number ("+92 336 80…"), as a range of [number].
(int, int)? numberRange(String number, String query) {
  final q = _digits(query);
  if (q.isEmpty || q.length != query.replaceAll(RegExp(r'[\s()+\-]'), '').length) return null;
  final i = _digits(number).indexOf(q);
  if (i < 0) return null;
  // Map digit positions back to positions in the formatted number.
  final positions = [
    for (var j = 0; j < number.length; j++)
      if (RegExp(r'\d').hasMatch(number[j])) j,
  ];
  return (positions[i], positions[i + q.length - 1] + 1);
}

List<ContactHit> searchContacts(List<DialerContact> contacts, String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final hits = <ContactHit>[];
  for (final c in contacts) {
    if (matchRange(c.name, q) case final range?) {
      hits.add((contact: c, number: c.callNumber ?? c.numbers.firstOrNull ?? '', nameRange: range, numberRange: null));
      continue;
    }
    for (final n in c.numbers) {
      if (numberRange(n, q) case final range?) {
        hits.add((contact: c, number: n, nameRange: null, numberRange: range));
        break;
      }
    }
  }
  return hits;
}

/// The call log's cached name (empty for unsaved numbers), else the contact's current name.
String? callName(CallLogEntry call, String? Function(String number) nameFor) =>
    (call.name?.isNotEmpty ?? false) ? call.name : nameFor(call.number);

/// Calls matching the query (by name or number) and the chosen filters, newest first.
List<CallLogEntry> searchCalls(
  List<CallLogEntry> calls,
  String query, {
  CallTime? time,
  CallFilter? type,
  required String? Function(String number) nameFor,
  required DateTime now,
}) {
  final q = query.trim();
  return [
    for (final c in calls)
      if ((type ?? CallFilter.all).matches(c, hideBlocked: true) &&
          (time == null || time.matches(c.date, now)) &&
          (q.isEmpty ||
              matchRange(callName(c, nameFor) ?? '', q) != null ||
              (!c.isPrivate && numberRange(c.number, q) != null)))
        c,
  ];
}
