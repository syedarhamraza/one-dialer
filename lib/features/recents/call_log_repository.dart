import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    await _load();
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
      hasAccess.value = true;
      this.loaded.value = true;
    } on PlatformException catch (e) {
      if (revision != _revision) return;
      if (e.code != 'NO_PERMISSION') rethrow;
      calls.value = const [];
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

  /// The SIM to call [number] on without asking: the one its newest logged call used, else the
  /// newest call's of any number; null when no logged call has a SIM. Call-log `simId`s are the same
  /// `component|accountId` as `getSims()`, but may name a SIM since removed: callers check.
  String? recentSim(String number) {
    final key = numberKey(number);
    String? newest;
    for (final c in calls.value) {
      final sim = c.simId;
      if (sim == null || sim.isEmpty) continue;
      newest ??= sim;
      if (key.isNotEmpty && numberKey(c.number) == key) return sim;
    }
    return newest;
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
