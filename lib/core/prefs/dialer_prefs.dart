import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/recents/call_log.dart' show numberKey;
import '../crash_reporting.dart' show crashReportingStarted;
import '../telecom/telecom_bridge.dart';

/// Small app settings: speed dial slots and per-contact default SIM.
class DialerPrefs {
  DialerPrefs._();

  static final DialerPrefs instance = DialerPrefs._();

  // A thin handle over the platform store, made per use, so tests that swap the store reach it.
  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

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

  /// The call screen background for a contact id, or `all` for every call: `color:<argb hex>`,
  /// `photo:<file name>`, `soft:<file name>`, `contact:`, `contact:soft` or `auto:` (see `CallBackground`);
  /// null is the default.
  Future<String?> callBackground(String scope) => _prefs.getString('call_bg_$scope');

  Future<void> setCallBackground(String scope, String? value) async {
    if (value == null) {
      await _prefs.remove('call_bg_$scope');
    } else {
      await _prefs.setString('call_bg_$scope', value);
    }
    changes.value++;
  }

  /// The photo picked for [scope]'s call background (`photo:<file name>` or `soft:<file name>`),
  /// kept while another background is in use so choosing Photo again brings it back. Its file is
  /// in the backgrounds folder, so Export settings carries it.
  Future<String?> keptCallPhoto(String scope) => _prefs.getString('call_bg_photo_$scope');

  Future<void> setKeptCallPhoto(String scope, String? value) async {
    if (value == null) {
      await _prefs.remove('call_bg_photo_$scope');
    } else {
      await _prefs.setString('call_bg_photo_$scope', value);
    }
  }

  /// Settings › "Tap a recent call": `details` (open its page), `dial` (write the number
  /// in the keypad), `call` (call it) or `sim` (dual SIM only: pick a SIM and call). Notifiers so rows read
  /// it synchronously; [loadChoices] fills them at startup.
  final recentTap = ValueNotifier('details');

  /// A tap on a Calls row calls: the row's call button steps aside then, since it'd only repeat it (Settings greys the button out and says why).
  bool get tapCalls => recentTap.value == 'call';

  /// Settings › SIM cards › "Which SIM to call with" (dual SIM): `phone` (Android's default SIM,
  /// asking when it's "Ask every time"), `menu` (always ask), `recent` (no asking: the SIM last used
  /// with that number, see [CallLogRepository.recentSim]) or `sim:<id>` (always that SIM). It
  /// overrides Android's default; a contact's own SIM still comes first ([placeCall]).
  final simChoice = ValueNotifier('phone');

  /// Settings › Keypad › "Two Call buttons": one per SIM on a dual SIM phone, whatever SIM cards
  /// says. Null until chosen: then the keypad shows them only where calls ask ([keypadTwoCallButtons]),
  /// as before this was its own setting.
  final keypadSimButtons = ValueNotifier<bool?>(null);

  // Settings › Keypad & recents, quick calling (all off by default): a call button on Calls and
  // Contacts rows, swipe right to call / left to message.
  final rowCallButton = ValueNotifier(false);
  final swipeToCall = ValueNotifier(false);

  /// Calls ⋮ › Group by contact: one row per contact a day (all their numbers, any calls in
  /// between), else only back-to-back calls from one number of one kind share a row.
  final groupByContact = ValueNotifier(true);

  /// Beta: the look of the swipe ([swipeStyles]) and of the row call button ([callButtonStyles]),
  /// to compare on the phone before one is kept (`docs/beta-only.md`).
  final swipeStyle = ValueNotifier('pill');
  final callButtonStyle = ValueNotifier('tint');
  static const swipeStyles = ['pill', 'flat'];
  static const callButtonStyles = ['tint', 'glyph', 'lit'];

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
    if (tap == 'details' || tap == 'dial' || tap == 'call' || tap == 'sim') recentTap.value = tap!;
    rowCallButton.value = await _prefs.getBool('row_call_button') ?? false;
    swipeToCall.value = await _prefs.getBool('swipe_to_call') ?? false;
    groupByContact.value = await _prefs.getBool('group_by_contact') ?? true;
    if (await _prefs.getString('swipe_style') case final v? when swipeStyles.contains(v)) swipeStyle.value = v;
    // A style since removed (Pill, Glass) goes back to the default.
    final buttonStyle = await _prefs.getString('call_button_style');
    callButtonStyle.value = callButtonStyles.contains(buttonStyle) ? buttonStyle! : callButtonStyles.first;
    final sim = await _prefs.getString('sim_call');
    if (sim == 'phone' || sim == 'menu' || sim == 'recent' || (sim?.startsWith('sim:') ?? false)) {
      simChoice.value = sim!;
    } else {
      // Before SIM cards had one rule, `sim_choice` was only how to ask when Android has no default.
      final old = await _prefs.getString('sim_choice');
      if (old == 'recent') simChoice.value = 'recent';
      if (old == 'menu') keypadSimButtons.value = false;
    }
    keypadSimButtons.value = await _prefs.getBool('keypad_sim_buttons') ?? keypadSimButtons.value;
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
  /// package picks per phone; see `LiquidQualityScope`). Automatic by default: premium at 120 Hz
  /// out-rastered a Snapdragon 7+ Gen 3's frame budget.
  final navGlass = ValueNotifier('auto');

  /// Settings › Glass › "Liquid glass on", for `liquid` glass: `all`, `controls` (the nav bar and
  /// buttons; menus and modals stay frosted) or `navbar` (the nav bar only).
  final liquidScope = ValueNotifier('all');

  /// Settings › Display & effects › Display size, each one of [displaySizes] (loaded with
  /// [loadAppearance], in the main engine only: the call screen keeps its own size): the pages,
  /// multiplying `DesignWidth`'s scale (the top buttons keep their size, see `headerScale`); the
  /// nav bar (`navBarScale`).
  final displaySize = ValueNotifier(1.0);
  final navBarSize = ValueNotifier(1.0);
  static const displaySizes = [0.9, 1.0, 1.1, 1.2];

  late final _sizeKeys = {displaySize: 'display_size', navBarSize: 'nav_bar_size'};

  void _loadDisplaySize(Map<String, Object?> saved) {
    for (final MapEntry(key: notifier, value: key) in _sizeKeys.entries) {
      final size = (saved[key] as num?)?.toDouble();
      // A test build's Largest (1.3) comes back as the top step, Larger.
      if (size != null && size > displaySizes.last) notifier.value = displaySizes.last;
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
    // One read for every key: each separate read is a platform round trip before the first frame.
    final saved = await _prefs.getAll(
      allowList: {
        ..._sizeKeys.values,
        'theme_mode',
        'visual_effects',
        'glass_dark',
        'nav_style',
        'nav_glass',
        'liquid_scope',
      },
    );
    _loadDisplaySize(saved);
    String? read(String key) => switch (saved[key]) {
      final String value => value,
      _ => null,
    };
    final mode = read('theme_mode');
    if (mode == 'system' || mode == 'light' || mode == 'dark') themeMode.value = mode!;
    final effects = read('visual_effects');
    effectsSaved = effects != null;
    if (effects == null) visualEffects.value = await _effectsDefault();
    if (effects == 'full' || effects == 'reduced' || effects == 'off') visualEffects.value = effects!;
    final dark = read('glass_dark');
    if (dark == 'classic' || dark == 'soft' || dark == 'bold') glassDark.value = dark!;
    final nav = read('nav_style');
    if (nav == 'frosted' || nav == 'liquid') navStyle.value = nav!;
    final navEffect = read('nav_glass');
    if (navEffect == 'premium' || navEffect == 'standard' || navEffect == 'auto') navGlass.value = navEffect!;
    final scope = read('liquid_scope');
    if (scope == 'all' || scope == 'controls' || scope == 'navbar') liquidScope.value = scope!;
  }

  /// Whether the user ever picked a [visualEffects] level; until then it's the phone's default,
  /// which `OneUIEffectsController.stepDown` may lower for the session.
  bool effectsSaved = false;

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
      // Firebase starts unawaited, alongside the first frame.
      await crashReportingStarted;
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

  /// Settings › "Call screen animations" (on by default). Off stills the whole call screen,
  /// as Android's "Remove animations" does. Loaded with [callEffects].
  final callAnimations = ValueNotifier(true);

  /// Settings › "Hide contact phone numbers": a saved caller shows only their name on the
  /// call screen and in Calls. Loaded with [callEffects].
  final hideContactNumbers = ValueNotifier(false);

  /// Settings › "Caller photo": `side` (beside the name, ColorOS 17) or `stacked` (above it,
  /// centred). Loaded with [callEffects].
  final callerLayout = ValueNotifier('side');

  Future<void> setCallerLayout(String value) async {
    callerLayout.value = value;
    await _prefs.setString('caller_layout', value);
  }

  Future<void> setCallAnimations(bool value) async {
    callAnimations.value = value;
    await _prefs.setBool('call_animations', value);
  }

  Future<void> setHideContactNumbers(bool value) async {
    hideContactNumbers.value = value;
    await _prefs.setBool('hide_contact_numbers', value);
  }

  Future<void> loadCallEffects() async {
    callAnimations.value = await _prefs.getBool('call_animations') ?? true;
    hideContactNumbers.value = await _prefs.getBool('hide_contact_numbers') ?? false;
    final effects = await _prefs.getString('call_effects');
    if (effects == null) callEffects.value = await _effectsDefault();
    if (effects == 'full' || effects == 'reduced' || effects == 'off') callEffects.value = effects!;
    final glass = await _prefs.getString('call_glass');
    if (glass == 'classic' || glass == 'soft' || glass == 'bold') callGlass.value = glass!;
    final style = await _prefs.getString('answer_style');
    if (style == 'two' || style == 'one') answerStyle.value = style!;
    final layout = await _prefs.getString('caller_layout');
    if (layout == 'side' || layout == 'stacked') callerLayout.value = layout!;
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
    effectsSaved = true;
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

  Future<void> setRowCallButton(bool value) async {
    rowCallButton.value = value;
    await _prefs.setBool('row_call_button', value);
  }

  Future<void> setGroupByContact(bool value) async {
    groupByContact.value = value;
    await _prefs.setBool('group_by_contact', value);
  }

  Future<void> setSwipeToCall(bool value) async {
    swipeToCall.value = value;
    await _prefs.setBool('swipe_to_call', value);
  }

  Future<void> setSwipeStyle(String value) async {
    swipeStyle.value = value;
    await _prefs.setString('swipe_style', value);
  }

  Future<void> setCallButtonStyle(String value) async {
    callButtonStyle.value = value;
    await _prefs.setString('call_button_style', value);
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
    await _prefs.setString('sim_call', value);
  }

  Future<void> setKeypadSimButtons(bool value) async {
    keypadSimButtons.value = value;
    await _prefs.setBool('keypad_sim_buttons', value);
  }

  /// Settings › Software update › Auto download (an `AutoUpdateCheck` name); null = never.
  Future<String?> getAutoUpdateCheck() => _prefs.getString('auto_update_check');

  Future<void> setAutoUpdateCheck(String mode) => _prefs.setString('auto_update_check', mode);
}
