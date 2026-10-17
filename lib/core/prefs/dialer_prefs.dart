import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small app settings: speed dial slots and per-contact default SIM.
class DialerPrefs {
  DialerPrefs._();

  static final DialerPrefs instance = DialerPrefs._();

  final _prefs = SharedPreferencesAsync();

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

  /// Contacts › "View favorites as list" (Samsung shows tiles by default).
  Future<bool> favoritesAsList() async => await _prefs.getBool('favorites_as_list') ?? false;

  Future<void> setFavoritesAsList(bool value) async {
    await _prefs.setBool('favorites_as_list', value);
    changes.value++;
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
}
