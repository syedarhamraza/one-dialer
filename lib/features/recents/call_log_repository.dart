import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/telecom_bridge.dart';
import 'call_log.dart';

/// The system call log, reloaded whenever Android reports a change.
class CallLogRepository {
  CallLogRepository._();

  static final CallLogRepository instance = CallLogRepository._();

  final ValueNotifier<List<CallLogEntry>> calls = ValueNotifier(const []);

  /// False when call-log access is missing (not the default dialer).
  final ValueNotifier<bool> hasAccess = ValueNotifier(true);

  Future<void> start() async {
    // Once loaded with access, the call-log observer keeps it current.
    if (TelecomBridge.instance.onCallLogChanged != null && hasAccess.value) return;
    TelecomBridge.instance.onCallLogChanged = _load;
    await _load();
  }

  Future<void> _load() async {
    try {
      final rows = await TelecomBridge.instance.getCallLog();
      calls.value = rows.map(CallLogEntry.fromMap).toList();
      hasAccess.value = true;
    } on PlatformException catch (e) {
      if (e.code != 'NO_PERMISSION') rethrow;
      calls.value = const [];
      hasAccess.value = false;
    }
  }

  Future<void> delete(Iterable<int> ids) => TelecomBridge.instance.deleteCalls(ids.toList());

  /// Marks missed calls seen (clears their notification) if there are any unseen.
  Future<void> markMissedSeen() async {
    if (calls.value.any((c) => c.isMissed && c.isNew)) await TelecomBridge.instance.markMissedRead();
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
String callerName(CallLogEntry call) {
  if (call.isPrivate || call.number.isEmpty) return 'Private number';
  final cached = call.name?.trim();
  return ContactsRepository.instance.nameFor(call.number) ??
      (cached != null && cached.isNotEmpty ? cached : call.number);
}
