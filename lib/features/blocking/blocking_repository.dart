import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../recents/call_log.dart';

/// Android's system block list (Telecom rejects these numbers before they ring) plus our
/// "private/unknown", "not in contacts" and prefix rules and the allowlist, applied by
/// `DialerScreeningService.kt`.
class BlockingRepository {
  BlockingRepository._();

  static final BlockingRepository instance = BlockingRepository._();

  /// Blocked numbers as stored; empty when not the default dialer.
  final ValueNotifier<List<String>> numbers = ValueNotifier(const []);
  final ValueNotifier<({bool blockHidden, bool blockNonContacts})> rules = ValueNotifier((
    blockHidden: false,
    blockNonContacts: false,
  ));

  /// Block by prefix: callers whose number starts with one of these ("0300", "+92300").
  final ValueNotifier<List<String>> prefixes = ValueNotifier(const []);

  /// The allowlist: numbers the rules and prefixes never block.
  final ValueNotifier<List<String>> allowed = ValueNotifier(const []);

  /// Whether anything needs the call-screening role (a rule or a prefix).
  bool get needsScreening => rules.value.blockHidden || rules.value.blockNonContacts || prefixes.value.isNotEmpty;

  /// False when the rules are saved but another app took the call-screening role.
  final ValueNotifier<bool> hasScreeningRole = ValueNotifier(true);

  final _api = FlutterContacts.blockedNumbers;

  Future<void> load() async {
    final raw = await TelecomBridge.instance.getBlocking();
    rules.value = (blockHidden: raw['blockHidden'] == true, blockNonContacts: raw['blockNonContacts'] == true);
    prefixes.value = [for (final p in raw['prefixes'] as List? ?? const []) p as String];
    allowed.value = [for (final n in raw['allowed'] as List? ?? const []) n as String];
    hasScreeningRole.value = await TelecomBridge.instance.hasScreeningRole();
    // isAvailable() only checks the phone user, not our role: reading the list needs the
    // default dialer role, which the user can hand to another app at any time.
    if (!await TelecomBridge.instance.isDefaultDialer() || !await _api.isAvailable()) return;
    try {
      numbers.value = [for (final p in await _api.getAll()) p.number];
    } on PlatformException {
      // Lost the role between the check and the read: keep the last list.
    }
  }

  /// Called for every call on each Calls rebuild: comparing against every blocked number's
  /// regex key there froze long lists for seconds (ANRs on vivo), so keys are built once.
  bool isBlocked(String number) {
    final key = numberKey(number);
    if (key.isEmpty) return false;
    if (!identical(_keysFor, numbers.value)) {
      _keysFor = numbers.value;
      _keys = {for (final n in numbers.value) numberKey(n)}..remove('');
    }
    return _keys.contains(key);
  }

  List<String>? _keysFor;
  Set<String> _keys = const {};

  /// Blocks several numbers with one reload at the end, not one per number; they leave the
  /// allowlist.
  Future<void> blockAll(Iterable<String> numbers) async {
    final list = numbers.toList();
    try {
      for (final n in list) {
        await _api.block(n);
      }
    } finally {
      await _removeAllowed(list);
      await load();
    }
  }

  Future<void> setBlocked(String number, bool blocked) => blocked ? blockAll([number]) : unblockAll([number]);

  /// Unblocks every stored form of these numbers (one may be saved as local and +E.164).
  Future<void> unblockAll(Iterable<String> numbers) async {
    final keys = {for (final n in numbers) numberKey(n)}..remove('');
    try {
      await _api.unblockAll([
        for (final n in this.numbers.value)
          if (keys.contains(numberKey(n))) n,
      ]);
    } finally {
      await load();
    }
  }

  /// Adds numbers to the allowlist, taking them off the system block list (Telecom rejects
  /// those before our allowlist is asked).
  Future<void> allowAll(Iterable<String> numbers) async {
    final add = [
      for (final n in numbers)
        if (numberKey(n).isNotEmpty) n.trim(),
    ];
    if (add.isEmpty) return;
    final keys = {for (final n in allowed.value) numberKey(n)};
    await _save(allowed: [...allowed.value, ...add.where((n) => keys.add(numberKey(n)))]);
    if (add.any(isBlocked)) await unblockAll(add);
  }

  Future<void> removeAllowed(Iterable<String> numbers) async {
    await _removeAllowed(numbers);
  }

  Future<void> _removeAllowed(Iterable<String> numbers) async {
    final keys = {for (final n in numbers) numberKey(n)};
    if (!allowed.value.any((n) => keys.contains(numberKey(n)))) return;
    await _save(
      allowed: [
        for (final n in allowed.value)
          if (!keys.contains(numberKey(n))) n,
      ],
    );
  }

  /// Blocks callers whose number starts with [prefix]. Like the rules, it first asks for the
  /// call-screening role; returns false (and saves nothing) if the user declines.
  Future<bool> addPrefix(String prefix) async {
    if (!await _ensureScreeningRole()) return false;
    if (!prefixes.value.contains(prefix)) await _save(prefixes: [...prefixes.value, prefix]..sort());
    return true;
  }

  Future<void> removePrefixes(Iterable<String> remove) async {
    final drop = remove.toSet();
    await _save(
      prefixes: [
        for (final p in prefixes.value)
          if (!drop.contains(p)) p,
      ],
    );
  }

  /// Saves the rules. Turning one on first asks for the call-screening role; returns false
  /// (and saves nothing) if the user declines.
  Future<bool> setRules({required bool blockHidden, required bool blockNonContacts}) async {
    if ((blockHidden || blockNonContacts) && !await _ensureScreeningRole()) return false;
    await _save(blockHidden: blockHidden, blockNonContacts: blockNonContacts);
    return true;
  }

  /// "Blocking paused": asks for the call-screening role again.
  Future<void> restoreScreening() async {
    await _ensureScreeningRole();
    hasScreeningRole.value = await TelecomBridge.instance.hasScreeningRole();
  }

  Future<bool> _ensureScreeningRole() async {
    final bridge = TelecomBridge.instance;
    return await bridge.hasScreeningRole() || await bridge.requestScreeningRole();
  }

  /// Writes everything the screening service reads, changing only what's passed.
  Future<void> _save({bool? blockHidden, bool? blockNonContacts, List<String>? prefixes, List<String>? allowed}) async {
    final bridge = TelecomBridge.instance;
    final hidden = blockHidden ?? rules.value.blockHidden;
    final nonContacts = blockNonContacts ?? rules.value.blockNonContacts;
    final p = prefixes ?? this.prefixes.value;
    final a = allowed ?? this.allowed.value;
    await bridge.setBlocking(blockHidden: hidden, blockNonContacts: nonContacts, prefixes: p, allowed: a);
    rules.value = (blockHidden: hidden, blockNonContacts: nonContacts);
    this.prefixes.value = p;
    this.allowed.value = a;
    hasScreeningRole.value = await bridge.hasScreeningRole();
  }
}
