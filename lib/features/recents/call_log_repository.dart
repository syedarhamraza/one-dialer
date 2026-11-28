import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/diagnostics/lag_diagnostics.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import 'call_log.dart';
import '../../l10n/l10n.dart';

/// The system call log, reloaded whenever Android reports a change.
class CallLogRepository {
  CallLogRepository._();

  static final CallLogRepository instance = CallLogRepository._();

  final ValueNotifier<List<CallLogEntry>> calls = ValueNotifier(const []);

  /// False when call-log access is missing (not the default dialer).
  final ValueNotifier<bool> hasAccess = ValueNotifier(true);

  /// False until the first read answers, so Recents doesn't flash "No recent calls" on a cold start.
  final ValueNotifier<bool> loaded = ValueNotifier(false);

  Future<void> start() async {
    // Once loaded with access, the call-log observer keeps it current.
    if (TelecomBridge.instance.onCallLogChanged != null && hasAccess.value) return;
    // A call ending fires a burst of changes; reload once they settle.
    TelecomBridge.instance.onCallLogChanged = () {
      _reload?.cancel();
      _reload = Timer(const Duration(milliseconds: 300), _load);
    };
    final read = _load(); // asked first: the cache must never hold up the real read
    if (!loaded.value) await _showCached();
    await read;
  }

  /// The last read, kept so a cold start shows Recents at once while the provider (seconds on a
  /// cold boot) answers, as AOSP Dialer's AnnotatedCallLog does. In the cache folder: never backed up.
  Future<File> _cacheFile() async => File('${(await getApplicationCacheDirectory()).path}/call_log.json');

  Future<void> _showCached() async {
    final revision = _revision;
    try {
      final rows = (jsonDecode(await (await _cacheFile()).readAsString()) as List).cast<Map<Object?, Object?>>();
      if (revision != _revision || loaded.value) return; // the real read already answered
      _saved = rows.map(CallLogEntry.fromMap).toList();
      calls.value = _saved.where((c) => !_pendingDeletes.contains(c.id)).toList();
      loaded.value = true;
    } catch (_) {
      // No cache yet, or unreadable: wait for the real read.
    }
  }

  /// What the cache file holds.
  List<CallLogEntry> _saved = const [];

  Future<void> _saveCache(List<Map<Object?, Object?>>? rows) async {
    try {
      final file = await _cacheFile();
      rows == null ? await file.delete() : await file.writeAsString(jsonEncode(rows));
    } catch (_) {
      // Best effort: the next read writes it again.
    }
  }

  Timer? _reload;
  final _pendingDeletes = <int>{};
  int _revision = 0;

  Future<void> _load() async {
    final diagnosticTimer = Stopwatch()..start();
    LagDiagnostics.instance.action(DiagnosticAction.callLogLoad);
    final revision = ++_revision;
    try {
      final rows = await TelecomBridge.instance.getCallLog();
      if (revision != _revision) return;
      final loaded = rows.map(CallLogEntry.fromMap).where((c) => !_pendingDeletes.contains(c.id)).toList();
      // Unchanged rows (a change elsewhere in the log) rebuild nothing.
      if (!sameCalls(loaded, calls.value)) calls.value = loaded;
      // Against the saved copy, not [calls]: a deletion already took its rows out of [calls].
      if (!sameCalls(loaded, _saved)) {
        _saved = loaded;
        _saveCache(rows).ignore();
      }
      hasAccess.value = true;
      this.loaded.value = true;
    } on PlatformException catch (e) {
      if (revision != _revision) return;
      if (e.code != 'NO_PERMISSION') rethrow;
      calls.value = const [];
      _saved = const [];
      _saveCache(null).ignore(); // no access, so keep no copy either
      hasAccess.value = false;
      loaded.value = true;
    } finally {
      LagDiagnostics.instance.action(DiagnosticAction.callLogLoad, elapsed: diagnosticTimer.elapsed);
    }
  }

  /// Whether [a] and [b] are the same rows, field for field.
  @visibleForTesting
  static bool sameCalls(List<CallLogEntry> a, List<CallLogEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.id != y.id ||
          x.number != y.number ||
          x.name != y.name ||
          x.type != y.type ||
          x.date != y.date ||
          x.duration != y.duration ||
          x.simId != y.simId ||
          x.isPrivate != y.isPrivate ||
          x.isNew != y.isNew ||
          x.app != y.app ||
          x.appPackage != y.appPackage ||
          x.isVideo != y.isVideo ||
          x.isWifi != y.isWifi ||
          x.isHd != y.isHd ||
          x.isVolte != y.isVolte ||
          x.isVonr != y.isVonr) {
        return false;
      }
    }
    return true;
  }

  Future<void> delete(Iterable<int> ids) async {
    final deleting = ids.toSet().difference(_pendingDeletes);
    if (deleting.isEmpty) return;
    final removed = calls.value.where((c) => deleting.contains(c.id)).toList();
    _pendingDeletes.addAll(deleting);
    ++_revision;
    calls.value = calls.value.where((c) => !deleting.contains(c.id)).toList();
    try {
      await TelecomBridge.instance.deleteCalls(deleting.toList());
    } catch (_) {
      _pendingDeletes.removeAll(deleting);
      ++_revision;
      final current = {for (final c in calls.value) c.id: c};
      for (final c in removed) {
        current.putIfAbsent(c.id, () => c);
      }
      calls.value = current.values.toList()..sort((a, b) => b.date.compareTo(a.date));
      rethrow;
    }
    _pendingDeletes.removeAll(deleting);
    ++_revision;
    // A read failure must not turn a successful deletion into a failed deletion.
    try {
      await _load();
    } on PlatformException {
      // The next observer notification retries the read.
    }
  }

  /// Marks missed calls seen (clears their notification). Asks the call log itself rather than
  /// [calls], which can still be loading or predate the missed call when the app opens.
  Future<void> markMissedSeen() async {
    try {
      await TelecomBridge.instance.markMissedRead();
    } on PlatformException {
      // No call log access yet; the next open retries.
    } on MissingPluginException {
      // Widget tests have no native side.
    }
  }

  /// The SIM to call [number] on without asking: the one its newest logged call used; null when
  /// it has none, and the caller asks. Call-log `simId`s are the same `component|accountId` as
  /// `getSims()`, but may name a SIM since removed: callers check.
  String? recentSim(String number) {
    final key = numberKey(number);
    if (key.isEmpty) return null;
    for (final c in calls.value) {
      final sim = c.simId;
      if (sim != null && sim.isNotEmpty && numberKey(c.number) == key) return sim;
    }
    return null;
  }

  /// The most recently dialled number, for the keypad's empty-call-button redial.
  String? get lastDialled {
    for (final c in calls.value) {
      if (c.type == CallType.outgoing && c.number.isNotEmpty) return c.number;
    }
    return null;
  }
}

/// What Recents shows for a call: live contact name, else Telecom's cached name, else the number.
String callerName(AppLocalizations l10n, CallLogEntry call) {
  if (call.isPrivate || call.number.isEmpty) return l10n.privateNumber;
  final cached = call.name?.trim();
  return ContactsRepository.instance.nameFor(call.number) ??
      (cached != null && cached.isNotEmpty ? cached : call.number);
}

/// Who a call is with, for grouping: the saved contact (all their numbers), else the number;
/// only the number while Calls doesn't group by contact ([DialerPrefs.groupByContact]).
String callerKey(CallLogEntry call) {
  if (!DialerPrefs.instance.groupByContact.value) return numberKey(call.number);
  final id = ContactsRepository.instance.contactFor(call.number)?.id;
  return id != null ? 'contact:$id' : numberKey(call.number);
}
