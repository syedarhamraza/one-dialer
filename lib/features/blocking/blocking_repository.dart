import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../recents/call_log.dart';

/// Android's system block list (Telecom rejects these numbers before they ring) plus our
/// "private/unknown" and "not in contacts" rules, applied by `DialerScreeningService.kt`.
class BlockingRepository {
  BlockingRepository._();

  static final BlockingRepository instance = BlockingRepository._();

  /// Blocked numbers as stored; empty when not the default dialer.
  final ValueNotifier<List<String>> numbers = ValueNotifier(const []);
  final ValueNotifier<({bool blockHidden, bool blockNonContacts})> rules =
      ValueNotifier((blockHidden: false, blockNonContacts: false));

  /// False when the rules are saved but another app took the call-screening role.
  final ValueNotifier<bool> hasScreeningRole = ValueNotifier(true);

  final _api = FlutterContacts.blockedNumbers;

  Future<void> load() async {
    final raw = await TelecomBridge.instance.getBlocking();
    rules.value = (blockHidden: raw['blockHidden'] == true, blockNonContacts: raw['blockNonContacts'] == true);
    hasScreeningRole.value = await TelecomBridge.instance.hasScreeningRole();
    if (!await _api.isAvailable()) return;
    numbers.value = [for (final p in await _api.getAll()) p.number];
  }

  bool isBlocked(String number) {
    final key = numberKey(number);
    return key.isNotEmpty && numbers.value.any((n) => numberKey(n) == key);
  }

  Future<void> setBlocked(String number, bool blocked) async {
    if (blocked) {
      await _api.block(number);
    } else {
      // Unblock every stored form of this number (it may be saved as local and +E.164).
      final key = numberKey(number);
      await _api.unblockAll([for (final n in numbers.value) if (numberKey(n) == key) n]);
    }
    await load();
  }

  /// Saves the rules. Turning one on first asks for the call-screening role; returns false
  /// (and saves nothing) if the user declines.
  Future<bool> setRules({required bool blockHidden, required bool blockNonContacts}) async {
    final bridge = TelecomBridge.instance;
    if ((blockHidden || blockNonContacts) && !await bridge.hasScreeningRole() && !await bridge.requestScreeningRole()) {
      return false;
    }
    await bridge.setBlocking(blockHidden: blockHidden, blockNonContacts: blockNonContacts);
    hasScreeningRole.value = await bridge.hasScreeningRole();
    rules.value = (blockHidden: blockHidden, blockNonContacts: blockNonContacts);
    return true;
  }
}
