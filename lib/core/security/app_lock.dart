import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../prefs/dialer_prefs.dart';
import '../telecom/telecom_bridge.dart';

/// Settings › Privacy & security › App lock: the phone's own fingerprint, face or screen lock
/// (`AppLock.kt`), so the app keeps no secret. Leaving the app covers it at once (so the app
/// never shows unlocked on the way back); coming back within [lockAfter] uncovers it again.
class AppLock {
  AppLock._();
  static final instance = AppLock._();

  final _bridge = TelecomBridge.instance;

  final enabled = ValueNotifier(false);

  /// Seconds as text, for `choiceRow`: '0' (at once), '60', '300'.
  final lockAfter = ValueNotifier<String?>('0');

  /// The app is covered by the lock screen.
  final locked = ValueNotifier(false);

  DateTime? _leftAt;
  bool _asking = false;

  /// Before the first frame: a locked app mustn't flash its content.
  Future<void> load() async {
    final prefs = DialerPrefs.instance;
    try {
      // Settings restored onto a phone without a screen lock leave the lock off.
      enabled.value = await prefs.appLock() && await _bridge.appLockAvailable();
    } on PlatformException {
      enabled.value = false;
    }
    lockAfter.value = '${await prefs.lockAfter()}';
    locked.value = enabled.value;
    if (enabled.value) _bridge.setSecure(true).ignore();
  }

  /// The app went to the background.
  Future<void> left() async {
    if (!enabled.value || locked.value || _asking) return;
    if (await _bridge.expectingReturn()) return; // our own picker or prompt
    _leftAt = DateTime.now();
    locked.value = true;
  }

  /// The app came back: uncovered again when it was away for less than [lockAfter].
  void returned() {
    final at = _leftAt;
    _leftAt = null;
    final grace = int.tryParse(lockAfter.value ?? '') ?? 0;
    if (at != null && grace > 0 && DateTime.now().difference(at).inSeconds < grace) locked.value = false;
  }

  /// The unlock prompt under [title], without changing [locked] (the vault asks this too).
  Future<bool> authenticate(String title) async {
    _asking = true;
    try {
      return await _bridge.authenticate(title);
    } on PlatformException {
      return false;
    } finally {
      _asking = false;
    }
  }

  Future<bool> unlock(String title) async {
    final ok = await authenticate(title);
    if (ok) locked.value = false;
    return ok;
  }

  /// Turning it on or off asks first, so a borrowed unlocked phone can't turn it off.
  Future<bool> setEnabled(bool on, String title) async {
    if (!await authenticate(title)) return false;
    enabled.value = on;
    await DialerPrefs.instance.setAppLock(on);
    await _bridge.setSecure(on);
    return true;
  }

  Future<void> setLockAfter(String seconds) async {
    lockAfter.value = seconds;
    await DialerPrefs.instance.setLockAfter(int.parse(seconds));
  }
}
