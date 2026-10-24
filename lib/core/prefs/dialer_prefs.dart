import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/recents/call_log.dart' show numberKey;

/// Small app settings: speed dial slots and per-contact default SIM.
class DialerPrefs {
  DialerPrefs._();

  static final DialerPrefs instance = DialerPrefs._();

  // Lazy: widgets read the notifiers below without touching storage.
  late final _prefs = SharedPreferencesAsync();

  /// Bumped on every change, so screens can rebuild.
  final ValueNotifier<int> changes = ValueNotifier(0);

  static const speedDialDigits = ['2', '3', '4', '5', '6', '7', '8', '9'];

  /// (name, number) assigned to keypad [digit], if any.
  Future<(String, String)?> speedDial(String digit) async {
    final value = await _prefs.getStringList('speed_dial_$digit');
    return value == null || value.length != 2 ? null : (value[0], value[1]);
  }

  Future<void> setSpeedDial(String digit, (String, String)? entry) async {
    if (entry == null) {
      await _prefs.remove('speed_dial_$digit');
    } else {
      await _prefs.setStringList('speed_dial_$digit', [entry.$1, entry.$2]);
    }
    changes.value++;
  }

  /// Recents › "Hide blocked calls" (on by default; they're always in Block numbers).
  Future<bool> hideBlockedCalls() async => await _prefs.getBool('hide_blocked_calls') ?? true;

  Future<void> setHideBlockedCalls(bool value) async {
    await _prefs.setBool('hide_blocked_calls', value);
    changes.value++;
  }

  /// Search page "Recent searches", newest first.
  Future<List<String>> recentSearches() async => await _prefs.getStringList('recent_searches') ?? const [];

  /// Adds [query] to the front (or removes it with [remove]); keeps the last 10.
  Future<void> updateRecentSearch(String query, {bool remove = false}) async {
    final list = [
      for (final s in await recentSearches())
        if (s != query) s,
    ];
    await _prefs.setStringList('recent_searches', [if (!remove) query, ...list].take(10).toList());
  }

  Future<void> clearRecentSearches() => _prefs.remove('recent_searches');

  /// Notes taken during calls live under `call_note_<number>_<millis>`, where millis is when the
  /// call's first note was saved; Recents matches them to the logged call by time.
  static String _notePrefix(String number) {
    final key = numberKey(number);
    return 'call_note_${key.isEmpty ? 'private' : key}_';
  }

  Future<String?> callNote(String number, DateTime at) =>
      _prefs.getString('${_notePrefix(number)}${at.millisecondsSinceEpoch}');

  /// Saves (or, when blank, removes) the note for the call with [number] begun at [at].
  Future<void> setCallNote(String number, DateTime at, String text) async {
    final key = '${_notePrefix(number)}${at.millisecondsSinceEpoch}';
    if (text.trim().isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, text.trim());
    }
    changes.value++;
  }

  /// Every note for [number] with when it was taken, oldest first.
  Future<List<(DateTime, String)>> callNotes(String number) async {
    final prefix = _notePrefix(number);
    final keys = (await _prefs.getKeys()).where((k) => k.startsWith(prefix)).toSet();
    if (keys.isEmpty) return const [];
    final notes = [
      for (final MapEntry(:key, :value) in (await _prefs.getAll(allowList: keys)).entries)
        if ((value, int.tryParse(key.substring(prefix.length))) case (final String text, final int millis?))
          (DateTime.fromMillisecondsSinceEpoch(millis), text),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return notes;
  }

  /// The SIM id (see `SimCard.id`) calls to this contact should use; null = ask / Android default.
  Future<String?> contactSim(String contactId) => _prefs.getString('contact_sim_$contactId');

  Future<void> setContactSim(String contactId, String? simId) async {
    if (simId == null) {
      await _prefs.remove('contact_sim_$contactId');
    } else {
      await _prefs.setString('contact_sim_$contactId', simId);
    }
    changes.value++;
  }

  /// Settings › "Tap a recent call": `details` (open its page), `dial` (write the number
  /// in the keypad) or `sim` (dual SIM only: pick a SIM and call). Notifiers so rows read
  /// it synchronously; [loadChoices] fills them at startup.
  final recentTap = ValueNotifier('details');

  /// Settings › "Choose SIM for calls" (dual SIM, no default): `buttons` (two Call keys)
  /// or `menu` (ask on every call).
  final simChoice = ValueNotifier('buttons');

  // Manage contacts. Accounts are keyed `type|name` (`|` is the phone itself).
  final showPhotos = ValueNotifier(true);
  final onlyWithNumbers = ValueNotifier(true);

  /// `first` or `last`: which name the A–Z list sorts by.
  final sortBy = ValueNotifier('first');

  /// `first` (First Last) or `last` (Last First).
  final nameOrder = ValueNotifier('first');

  /// Accounts whose contacts the Contacts tab leaves out; empty shows all.
  final hiddenAccounts = ValueNotifier<Set<String>>(const {});

  /// Where new contacts are saved; null leaves it to the editor's default.
  final saveAccount = ValueNotifier<String?>(null);

  Future<void> loadChoices() async {
    showPhotos.value = await _prefs.getBool('contacts_show_photos') ?? true;
    onlyWithNumbers.value = await _prefs.getBool('contacts_only_numbers') ?? true;
    if (await _prefs.getString('contacts_sort') case final v? when v == 'first' || v == 'last') sortBy.value = v;
    if (await _prefs.getString('contacts_name_order') case final v? when v == 'first' || v == 'last') {
      nameOrder.value = v;
    }
    hiddenAccounts.value = {...?await _prefs.getStringList('contacts_hidden_accounts')};
    saveAccount.value = await _prefs.getString('contacts_save_account');
    // Ignores values from earlier test builds that no longer exist.
    final tap = await _prefs.getString('recent_tap');
    if (tap == 'details' || tap == 'dial' || tap == 'sim') recentTap.value = tap!;
    final sim = await _prefs.getString('sim_choice');
    if (sim == 'buttons' || sim == 'menu') simChoice.value = sim!;
  }

  Future<void> setRecentTap(String value) async {
    recentTap.value = value;
    await _prefs.setString('recent_tap', value);
  }

  Future<void> setShowPhotos(bool value) async {
    showPhotos.value = value;
    await _prefs.setBool('contacts_show_photos', value);
  }

  Future<void> setOnlyWithNumbers(bool value) async {
    onlyWithNumbers.value = value;
    await _prefs.setBool('contacts_only_numbers', value);
  }

  Future<void> setSortBy(String value) async {
    sortBy.value = value;
    await _prefs.setString('contacts_sort', value);
  }

  Future<void> setNameOrder(String value) async {
    nameOrder.value = value;
    await _prefs.setString('contacts_name_order', value);
  }

  Future<void> setHiddenAccounts(Set<String> value) async {
    hiddenAccounts.value = value;
    await _prefs.setStringList('contacts_hidden_accounts', value.toList());
  }

  Future<void> setSaveAccount(String value) async {
    saveAccount.value = value;
    await _prefs.setString('contacts_save_account', value);
  }

  Future<void> setSimChoice(String value) async {
    simChoice.value = value;
    await _prefs.setString('sim_choice', value);
  }

  /// Settings › Software update › Auto download (an `AutoUpdateCheck` name); null = never.
  Future<String?> getAutoUpdateCheck() => _prefs.getString('auto_update_check');

  Future<void> setAutoUpdateCheck(String mode) => _prefs.setString('auto_update_check', mode);
}
