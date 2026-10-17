import 'package:flutter/services.dart';

import 'call_info.dart';

/// Dart side of `CallBridge.kt`. Keep channel and method names in sync.
class TelecomBridge {
  TelecomBridge._() {
    _methods.setMethodCallHandler(_onNativeCall);
  }

  static final TelecomBridge instance = TelecomBridge._();

  static const _methods = MethodChannel('com.syedarhamraza.dialer/telecom');
  static const _events = EventChannel('com.syedarhamraza.dialer/call_state');

  /// Fires when the app is opened from a `tel:` link while already running.
  void Function(String number)? onDialIntent;

  /// Fires when the missed-call notification is tapped while the app is running.
  VoidCallback? onOpenRecents;

  /// Fires on every change to the system call log.
  VoidCallback? onCallLogChanged;

  late final Stream<CallSnapshot> callState = _events.receiveBroadcastStream().map(
    (e) => CallSnapshot.fromMap(e as Map<Object?, Object?>),
  );

  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onDialIntent':
        onDialIntent?.call(call.arguments as String);
      case 'onOpenRecents':
        onOpenRecents?.call();
      case 'onCallLogChanged':
        onCallLogChanged?.call();
    }
  }

  // Setup
  Future<bool> isDefaultDialer() async => await _methods.invokeMethod<bool>('isDefaultDialer') ?? false;

  Future<bool> requestDefaultDialer() async => await _methods.invokeMethod<bool>('requestDefaultDialer') ?? false;

  /// The `tel:` number the app was launched with, if any (returned once).
  Future<String?> consumeDialNumber() => _methods.invokeMethod<String>('consumeDialNumber');

  /// Whether the app was opened from the missed-call notification (returned once).
  Future<bool> consumeOpenRecents() async => await _methods.invokeMethod<bool>('consumeOpenRecents') ?? false;

  /// Android's photo picker; returns the picked photo as JPEG bytes (max 720px), or null.
  Future<Uint8List?> pickPhoto() => _methods.invokeMethod<Uint8List>('pickPhoto');

  // Settings
  Future<List<String>> getQuickReplies() async =>
      await _methods.invokeListMethod<String>('getQuickReplies') ?? const [];

  Future<void> setQuickReplies(List<String> replies) => _methods.invokeMethod('setQuickReplies', {'replies': replies});

  /// What incoming calls need (default dialer, notifications, full-screen, screening) plus the app version.
  Future<Map<Object?, Object?>> getCallHealth() async =>
      await _methods.invokeMapMethod<Object?, Object?>('getCallHealth') ?? const {};

  /// `notifications`, `fullScreen`, `defaultApps`, `app`, or `url:https://…`.
  Future<void> openSystemSettings(String page) => _methods.invokeMethod('openSystemSettings', {'page': page});

  // Blocking rules (read by DialerScreeningService.kt)
  /// Only the call-screening role holder may screen calls, so the rules need this role.
  Future<bool> hasScreeningRole() async => await _methods.invokeMethod<bool>('hasScreeningRole') ?? false;

  /// Shows Android's prompt; true if the role is held afterwards.
  Future<bool> requestScreeningRole() async => await _methods.invokeMethod<bool>('requestScreeningRole') ?? false;

  Future<Map<Object?, Object?>> getBlocking() async =>
      await _methods.invokeMapMethod<Object?, Object?>('getBlocking') ?? const {};

  Future<void> setBlocking({required bool blockHidden, required bool blockNonContacts}) =>
      _methods.invokeMethod('setBlocking', {'blockHidden': blockHidden, 'blockNonContacts': blockNonContacts});

  // Call log
  /// Newest first, up to 500 calls. Throws [PlatformException] `NO_PERMISSION` without call-log access.
  Future<List<Map<Object?, Object?>>> getCallLog() async =>
      await _methods.invokeListMethod<Map<Object?, Object?>>('getCallLog') ?? const [];

  Future<void> deleteCalls(List<int> ids) => _methods.invokeMethod('deleteCalls', {'ids': ids});

  /// Marks missed calls seen and clears the missed-call notification.
  Future<void> markMissedRead() => _methods.invokeMethod('markMissedRead');

  // Calls
  /// Calls [number], on the SIM with [simId] if given (otherwise Android's default or its own picker).
  Future<void> placeCall(String number, {String? simId}) =>
      _methods.invokeMethod('placeCall', {'number': number, 'simId': simId});

  /// Opens the default SMS app on a conversation with [number].
  Future<void> sendSms(String number) => _methods.invokeMethod('sendSms', {'number': number});

  /// Call-capable SIMs in slot order; empty without READ_PHONE_STATE.
  Future<List<SimCard>> getSims() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>('getSims') ?? const [];
    return raw.map(SimCard.fromMap).toList();
  }

  /// Keypad feedback tone (respects the system "Dial pad tones" setting).
  Future<void> playTone(String digit) => _methods.invokeMethod('playTone', {'digit': digit});
  Future<void> stopTone() => _methods.invokeMethod('stopTone');

  Future<void> answer(String id) => _call('answer', id);
  Future<void> reject(String id) => _call('reject', id);

  /// Declines and texts [message] to the caller.
  Future<void> rejectWithMessage(String id, String message) =>
      _methods.invokeMethod('rejectWithMessage', {'id': id, 'message': message});

  /// Opens the keypad to place another call; Telecom holds the current one.
  Future<void> openDialer() => _methods.invokeMethod('openDialer');
  Future<void> hangUp(String id) => _call('hangUp', id);
  Future<void> hold(String id) => _call('hold', id);
  Future<void> unhold(String id) => _call('unhold', id);
  Future<void> merge(String id) => _call('merge', id);
  Future<void> swap(String id) => _call('swap', id);

  Future<void> playDtmf(String id, String digit) => _methods.invokeMethod('playDtmf', {'id': id, 'digit': digit});
  Future<void> stopDtmf(String id) => _call('stopDtmf', id);

  // Audio
  Future<void> setMuted(bool muted) => _methods.invokeMethod('setMuted', {'muted': muted});

  Future<void> setAudioRoute(AudioRoute route) => _methods.invokeMethod('setAudioRoute', {'route': route.name});

  Future<void> _call(String method, String id) => _methods.invokeMethod(method, {'id': id});
}
