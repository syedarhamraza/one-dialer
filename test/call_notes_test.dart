import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/recents/call_details_screen.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('notes round-trip per number, oldest first, and blank removes', () async {
    final prefs = DialerPrefs.instance;
    final first = DateTime(2026, 10, 17, 9);
    final second = DateTime(2026, 10, 17, 18);
    await prefs.setCallNote('+92 300 1234567', second, ' Call back Friday ');
    await prefs.setCallNote('03001234567', first, 'Invoice');
    await prefs.setCallNote('03009999999', first, 'Someone else');
    expect(await prefs.callNotes('0300 1234567'), [(first, 'Invoice'), (second, 'Call back Friday')]);
    await prefs.setCallNote('03001234567', first, '  ');
    expect(await prefs.callNotes('03001234567'), [(second, 'Call back Friday')]);
  });

  test('note times are indexed by number key, private numbers included, for Recents marks', () async {
    final prefs = DialerPrefs.instance;
    final at = DateTime(2026, 10, 17, 9);
    await prefs.setCallNote('+44 20 7183 8750', at, 'Invoice');
    await prefs.setCallNote('', at, 'Hidden caller');
    final times = await prefs.noteTimes();
    expect(times['private'], [at]);
    expect(times[numberKey('020 7183 8750')], [at]);
  });

  test('a note goes to the logged call it was taken during', () {
    CallLogEntry entry(int id, DateTime date, int seconds) => CallLogEntry(
      id: id,
      number: '03001234567',
      type: CallType.outgoing,
      date: date,
      duration: Duration(seconds: seconds),
    );
    final morning = entry(1, DateTime(2026, 10, 17, 9), 300);
    final evening = entry(2, DateTime(2026, 10, 17, 18), 60);
    final history = [evening, morning]; // Newest first, like Recents.
    final notes = [
      (DateTime(2026, 10, 17, 9, 3), 'During the morning call'),
      (DateTime(2026, 10, 17, 18, 0, 30), 'During the evening call'),
      (DateTime(2026, 10, 17, 12), 'Belongs to no logged call'),
    ];
    expect(notesFor(morning, history, notes), ['During the morning call']);
    expect(notesFor(evening, history, notes), ['During the evening call']);
  });
}
