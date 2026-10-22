import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/recents/call_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

CallLogEntry call(int id, String number, DateTime date, {CallType type = CallType.incoming, bool private = false}) =>
    CallLogEntry(id: id, number: number, type: type, date: date, isPrivate: private);

void main() {
  final now = DateTime(2026, 10, 17, 12);

  test('consecutive same-number calls on a day merge; missed stays separate', () {
    final days = groupByDay([
      call(5, '+92 300 1234567', DateTime(2026, 10, 17, 11)),
      call(4, '03001234567', DateTime(2026, 10, 17, 10)), // same number, local format
      call(3, '03001234567', DateTime(2026, 10, 17, 9), type: CallType.missed),
      call(2, '0301', DateTime(2026, 10, 16, 9)),
      call(1, '0301', DateTime(2026, 10, 16, 8)),
    ]);

    expect(days.length, 2);
    expect(days[0].$1, DateTime(2026, 10, 17));
    expect([for (final g in days[0].$2) g.calls.map((c) => c.id).toList()], [[5, 4], [3]]);
    expect(days[1].$2.single.calls.length, 2);
  });

  test('private calls never merge', () {
    final days = groupByDay([
      call(2, '', DateTime(2026, 10, 17, 11), private: true),
      call(1, '', DateTime(2026, 10, 17, 10), private: true),
    ]);
    expect(days.single.$2.length, 2);
  });

  test('day labels', () {
    expect(dayLabel(DateTime(2026, 10, 17), now), 'Today');
    expect(dayLabel(DateTime(2026, 10, 16), now), 'Yesterday');
    expect(dayLabel(DateTime(2026, 10, 13), now), 'Tuesday');
    expect(dayLabel(DateTime(2026, 9, 2), now), '2 Sep');
    expect(dayLabel(DateTime(2025, 9, 2), now), '2 Sep 2025');
  });

  test('time and duration labels', () {
    expect(timeLabel(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(timeLabel(DateTime(2026, 1, 1, 13, 30)), '1:30 PM');
    expect(durationLabel(const Duration(seconds: 45)), '45 sec');
    expect(durationLabel(const Duration(minutes: 3, seconds: 5)), '3 min 5 sec');
    expect(durationLabel(const Duration(hours: 1, minutes: 2)), '1 hr 2 min');
  });

  test('numberKey matches international and local formats', () {
    expect(numberKey('+92 300 1234567'), numberKey('0300-1234567'));
  });

  test('call filters', () {
    final now = DateTime(2026, 10, 17, 12);
    final calls = {
      for (final t in [CallType.incoming, CallType.outgoing, CallType.missed, CallType.rejected, CallType.blocked])
        t: call(t.index, '0300', now, type: t),
    };
    List<CallType> shown(CallFilter f, {bool hideBlocked = true}) =>
        [for (final c in calls.values) if (f.matches(c, hideBlocked: hideBlocked)) c.type];

    expect(shown(CallFilter.all), [CallType.incoming, CallType.outgoing, CallType.missed, CallType.rejected]);
    expect(shown(CallFilter.all, hideBlocked: false), contains(CallType.blocked));
    expect(shown(CallFilter.missed), [CallType.missed]);
    expect(shown(CallFilter.rejected), [CallType.rejected]);
    expect(shown(CallFilter.outgoing), [CallType.outgoing]);
    expect(shown(CallFilter.incoming), [CallType.incoming]);
    expect(shown(CallFilter.missed, hideBlocked: false), [CallType.missed]); // blocked only under All
  });

  test('a reload with the same rows is skipped; any changed field is not', () {
    final rows = [call(1, '0300', now), call(2, '0301', now, type: CallType.missed)];
    final same = [call(1, '0300', now), call(2, '0301', now, type: CallType.missed)];
    expect(CallLogRepository.sameCalls(rows, same), isTrue);
    expect(CallLogRepository.sameCalls(rows, [same.first]), isFalse);
    expect(CallLogRepository.sameCalls(rows, [same.first, call(2, '0301', now)]), isFalse);
  });
}
