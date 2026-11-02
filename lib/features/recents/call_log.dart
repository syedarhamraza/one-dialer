/// Call log entries (from `CallLogSource.kt`) and Samsung-style grouping for Recents.
library;

import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

enum CallType { incoming, outgoing, missed, voicemail, rejected, blocked, answeredExternally, unknown }

class CallLogEntry {
  const CallLogEntry({
    required this.id,
    required this.number,
    required this.type,
    required this.date,
    this.name,
    this.duration = Duration.zero,
    this.simId,
    this.isPrivate = false,
    this.isNew = false,
    this.app,
    this.appPackage,
    this.isVideo = false,
  });

  factory CallLogEntry.fromMap(Map<Object?, Object?> map) {
    final presentation = map['presentation'] as String?;
    return CallLogEntry(
      id: map['id']! as int,
      number: map['number'] as String? ?? '',
      name: map['name'] as String?,
      type: CallType.values.firstWhere((t) => t.name == map['type'], orElse: () => CallType.unknown),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
      duration: Duration(seconds: map['duration'] as int? ?? 0),
      simId: map['simId'] as String?,
      isPrivate: presentation == 'private' || presentation == 'unknown',
      isNew: map['isNew'] as bool? ?? false,
      app: map['app'] as String?,
      appPackage: map['appPackage'] as String?,
      isVideo: map['video'] as bool? ?? false,
    );
  }

  final int id;
  final String number;

  /// The name Telecom cached when the call was logged; prefer the live contact name.
  final String? name;
  final CallType type;
  final DateTime date;
  final Duration duration;

  /// Matches `SimCard.id`.
  final String? simId;

  /// Caller hid their number (or the network didn't send one).
  final bool isPrivate;
  final bool isNew;

  /// The calling app (WhatsApp...) for a call it shared with the call log; null for SIM calls.
  final String? app;
  final String? appPackage;
  final bool isVideo;

  bool get isMissed => type == CallType.missed;
  bool get isApp => appPackage != null;
}

/// Consecutive calls with the same number, app and kind on the same day, shown as one row
/// with a count, like Samsung. A missed call never merges with answered ones.
class CallGroup {
  CallGroup(this.calls);

  /// Newest first.
  final List<CallLogEntry> calls;

  CallLogEntry get latest => calls.first;
}

final _nonDigits = RegExp(r'[^0-9]');

/// Digits only, last 10: matches "+92 300 1234567" with "03001234567".
/// shortcut: suffix matching, not libphonenumber; upgrade if short codes collide.
String numberKey(String number) {
  final digits = number.replaceAll(_nonDigits, '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Groups newest-first [calls] into days (newest first), each holding [CallGroup]s.
List<(DateTime, List<CallGroup>)> groupByDay(List<CallLogEntry> calls) {
  final days = <(DateTime, List<CallGroup>)>[];
  for (final call in calls) {
    final day = _day(call.date);
    if (days.isEmpty || days.last.$1 != day) days.add((day, []));
    final groups = days.last.$2;
    final last = groups.isEmpty ? null : groups.last.latest;
    final sameRow =
        last != null &&
        !call.isPrivate &&
        !last.isPrivate &&
        numberKey(last.number) == numberKey(call.number) &&
        last.appPackage == call.appPackage &&
        last.isMissed == call.isMissed;
    if (sameRow) {
      groups.last.calls.add(call);
    } else {
      groups.add(CallGroup([call]));
    }
  }
  return days;
}

/// "Today", "Yesterday", a weekday within the last week, else "12 Mar" (plus year if not this year).
String dayLabel(AppLocalizations l10n, DateTime day, DateTime now) {
  final diff = _day(now).difference(_day(day)).inDays;
  if (diff == 0) return l10n.today;
  if (diff == 1) return l10n.yesterday;
  final label = DateFormat(
    diff < 7 ? 'EEEE' : (day.year == now.year ? 'd MMM' : 'd MMM y'),
    l10n.localeName,
  ).format(day);
  return label[0].toUpperCase() + label.substring(1); // Italian weekdays are lowercase
}

/// "9:05 AM" (or "21:05" where the language uses 24-hour time).
String timeLabel(AppLocalizations l10n, DateTime t) =>
    DateFormat.jm(l10n.localeName).format(t).replaceAll(' ', ' '); // intl's narrow space before AM/PM

/// "1 hr 2 min", "3 min 5 sec", "45 sec".
String durationLabel(AppLocalizations l10n, Duration d) {
  if (d.inHours > 0) return l10n.durationHoursMinutes('${d.inHours}', '${d.inMinutes.remainder(60)}');
  if (d.inMinutes > 0) return l10n.durationMinutesSeconds('${d.inMinutes}', '${d.inSeconds.remainder(60)}');
  return l10n.durationSeconds('${d.inSeconds}');
}

/// Samsung's "Filter calls" choices in Recents.
enum CallFilter {
  all,
  missed,
  rejected,
  outgoing,
  incoming;

  /// Whether [call] shows under this filter. Blocked calls show only when not hidden
  /// (they always appear in Block numbers › Blocked calls).
  bool matches(CallLogEntry call, {required bool hideBlocked}) {
    if (call.type == CallType.blocked) return this == CallFilter.all && !hideBlocked;
    return switch (this) {
      CallFilter.all => true,
      CallFilter.missed => call.isMissed,
      CallFilter.rejected => call.type == CallType.rejected,
      CallFilter.outgoing => call.type == CallType.outgoing,
      CallFilter.incoming => call.type == CallType.incoming || call.type == CallType.answeredExternally,
    };
  }
}
