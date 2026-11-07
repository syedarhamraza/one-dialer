import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/recents/call_log.dart' show numberKey;
import '../telecom/telecom_bridge.dart';

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

  /// Whether the one-time "Not from Google Play" warning was shown.
  Future<bool> sideloadWarned() async => await _prefs.getBool('sideload_warned') ?? false;

  Future<void> setSideloadWarned() => _prefs.setBool('sideload_warned', true);

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

  /// Every saved note with when it was started, by [numberKey] (`private` for hidden numbers),
  /// for Recents' rows.
  Future<Map<String, List<(DateTime, String)>>> noteIndex() async {
    const prefix = 'call_note_';
    final keys = (await _prefs.getKeys()).where((k) => k.startsWith(prefix)).toSet();
    if (keys.isEmpty) return const {};
    final index = <String, List<(DateTime, String)>>{};
    for (final MapEntry(:key, :value) in (await _prefs.getAll(allowList: keys)).entries) {
      final split = key.lastIndexOf('_');
      final millis = int.tryParse(key.substring(split + 1));
      if (millis == null || split < prefix.length || value is! String) continue;
      (index[key.substring(prefix.length, split)] ??= []).add((DateTime.fromMillisecondsSinceEpoch(millis), value));
    }
    return index;
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
    await loadCallEffects();
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

  /// Settings › "Appearance": `system`, `light` or `dark`.
  final themeMode = ValueNotifier('system');

  /// Settings › "Reduce visual effects": `full`, `reduced` (no wide blurs) or `off` (no
  /// blurs); read through `OneUIEffectsController`.
  final visualEffects = ValueNotifier('full');

  /// Settings › "Dark mode edge glow", with full effects: `classic`, `soft` or `bold`; read
  /// through `OneUIEffectsController.glassStyle`.
  final glassDark = ValueNotifier('soft');

  /// Settings › "Glass style", with full effects: `frosted` (our call glass) or `liquid` (the
  /// glass package's `GlassTabBar` and `GlassContainer` on all floating chrome; read through
  /// `OneUIEffectsController.isLiquid`).
  final navStyle = ValueNotifier('frosted');

  /// Settings › "Glass effect", for `liquid` glass: `premium`, `standard` or `auto` (the glass
  /// package picks per phone; see `LiquidQualityScope`).
  final navGlass = ValueNotifier('premium');

  /// Settings › Glass › "Liquid glass on", for `liquid` glass: `all`, `controls` (the nav bar and
  /// buttons; menus and modals stay frosted) or `navbar` (the nav bar only).
  final liquidScope = ValueNotifier('all');

  /// Settings › Display & effects › Display size, each one of [displaySizes] (loaded with
  /// [loadAppearance] and [loadCallEffects]): the whole app, multiplying `DesignWidth`'s scale in
  /// both engines; the nav bar (`navBarScale`); the Calls and Contacts header pills (`headerScale`).
  final displaySize = ValueNotifier(1.0);
  final navBarSize = ValueNotifier(1.0);
  final headerSize = ValueNotifier(1.0);
  static const displaySizes = [0.9, 1.0, 1.1, 1.2, 1.3];

  late final _sizeKeys = {displaySize: 'display_size', navBarSize: 'nav_bar_size', headerSize: 'header_size'};

  Future<void> _loadDisplaySize() async {
    for (final MapEntry(key: notifier, value: key) in _sizeKeys.entries) {
      final size = await _prefs.getDouble(key);
      if (displaySizes.contains(size)) notifier.value = size!;
    }
  }

  Future<void> setSize(ValueNotifier<double> notifier, double value) async {
    notifier.value = value;
    await _prefs.setDouble(_sizeKeys[notifier]!, value);
  }

  /// Awaited before the first frame, so the app doesn't open dark and then turn light, or
  /// frosted and then flat.
  Future<void> loadAppearance() async {
    await _loadDisplaySize();
    final mode = await _prefs.getString('theme_mode');
    if (mode == 'system' || mode == 'light' || mode == 'dark') themeMode.value = mode!;
    final effects = await _prefs.getString('visual_effects');
    if (effects == null) visualEffects.value = await _effectsDefault();
    if (effects == 'full' || effects == 'reduced' || effects == 'off') visualEffects.value = effects!;
    final dark = await _prefs.getString('glass_dark');
    if (dark == 'classic' || dark == 'soft' || dark == 'bold') glassDark.value = dark!;
    final nav = await _prefs.getString('nav_style');
    if (nav == 'frosted' || nav == 'liquid') navStyle.value = nav!;
    final navEffect = await _prefs.getString('nav_glass');
    if (navEffect == 'premium' || navEffect == 'standard' || navEffect == 'auto') navGlass.value = navEffect!;
    final scope = await _prefs.getString('liquid_scope');
    if (scope == 'all' || scope == 'controls' || scope == 'navbar') liquidScope.value = scope!;
  }

  /// Settings › Language: `system` or a language tag. Kept natively (`AppLanguage.kt`), where
  /// Android 13+ keeps its own per-app language, so it's read again on every resume.
  final language = ValueNotifier('system');

  Future<void> loadLanguage() async {
    try {
      final tag = await TelecomBridge.instance.getAppLanguage();
      language.value = tag == 'system' ? tag : tag.split(RegExp('[-_]')).first; // Android's page may add a region
    } catch (_) {} // no bridge (tests): keep the system language
  }

  Future<void> setLanguage(String tag) async {
    language.value = tag;
    await TelecomBridge.instance.setAppLanguage(tag);
  }

  /// The level until the user picks one: never saved, so a later cutoff still reaches them.
  /// Off on budget chips, reduced on midrange, full above (`DeviceTier.kt`), until a level is saved.
  Future<String> _effectsDefault() async {
    final Map<String, Object?> pick;
    try {
      pick = await TelecomBridge.instance.effectsDefault();
    } catch (_) {
      return 'full';
    }
    final tier = pick['tier'];
    final level = tier == 'off' || tier == 'reduced' || tier == 'full' ? tier as String : 'full';
    unawaited(_logDevice(pick, level));
    return level;
  }

  /// Every crash and lag report then shows the chip and the level it was given. Not awaited, so
  /// it never holds up the first frame.
  Future<void> _logDevice(Map<String, Object?> pick, String level) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      for (final key in ['soc', 'platform', 'hardware', 'gpu']) {
        await crashlytics.setCustomKey('device_$key', '${pick[key] ?? ''}');
      }
      await crashlytics.setCustomKey('effects_default', level);
      await crashlytics.setCustomKey('effects_source', '${pick['source'] ?? ''}');
    } catch (_) {
      // Firebase isn't set up (tests, builds without google-services.json).
    }
  }

  /// Settings › "Call screen effects": the same levels as [visualEffects], for the call
  /// screen's own engine (which reads it in `inCallMain` and on every resume, never awaited).
  final callEffects = ValueNotifier('full');

  /// Settings › "Call screen edge glow", with full call screen effects: `classic`, `soft` or
  /// `bold`, like the main app's. Loaded with [callEffects].
  final callGlass = ValueNotifier('soft');

  /// Settings › Answer buttons: `two` buttons (Decline | Answer) or `one` (swipe up to
  /// answer, down to decline). Loaded with [callEffects], for the call screen's engine.
  final answerStyle = ValueNotifier('two');

  /// Settings › Answer buttons › Answer call, with 1 button: swipe `up` or `down` to answer.
  final answerDirection = ValueNotifier('up');

  Future<void> loadCallEffects() async {
    await _loadDisplaySize();
    final effects = await _prefs.getString('call_effects');
    if (effects == null) callEffects.value = await _effectsDefault();
    if (effects == 'full' || effects == 'reduced' || effects == 'off') callEffects.value = effects!;
    final glass = await _prefs.getString('call_glass');
    if (glass == 'classic' || glass == 'soft' || glass == 'bold') callGlass.value = glass!;
    final style = await _prefs.getString('answer_style');
    if (style == 'two' || style == 'one') answerStyle.value = style!;
    final direction = await _prefs.getString('answer_direction');
    if (direction == 'up' || direction == 'down') answerDirection.value = direction!;
  }

  Future<void> setAnswerDirection(String value) async {
    answerDirection.value = value;
    await _prefs.setString('answer_direction', value);
  }

  Future<void> setAnswerStyle(String value) async {
    answerStyle.value = value;
    await _prefs.setString('answer_style', value);
  }

  Future<void> setCallGlass(String value) async {
    callGlass.value = value;
    await _prefs.setString('call_glass', value);
  }

  Future<void> setCallEffects(String value) async {
    callEffects.value = value;
    await _prefs.setString('call_effects', value);
  }

  Future<void> setVisualEffects(String value) async {
    visualEffects.value = value;
    await _prefs.setString('visual_effects', value);
  }

  Future<void> setGlassDark(String value) async {
    glassDark.value = value;
    await _prefs.setString('glass_dark', value);
  }

  Future<void> setNavStyle(String value) async {
    navStyle.value = value;
    await _prefs.setString('nav_style', value);
  }

  Future<void> setNavGlass(String value) async {
    navGlass.value = value;
    await _prefs.setString('nav_glass', value);
  }

  Future<void> setLiquidScope(String value) async {
    liquidScope.value = value;
    await _prefs.setString('liquid_scope', value);
  }

  Future<void> setThemeMode(String value) async {
    themeMode.value = value;
    await _prefs.setString('theme_mode', value);
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
