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

  /// The Contacts icon or another app's contact intent: `kind` is tab, view, edit or insert,
  /// with `id` (view, edit) or `phone` and `name` (insert).
  void Function(Map<Object?, Object?> action)? onContactAction;

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
      case 'onContactAction':
        onContactAction?.call(call.arguments as Map<Object?, Object?>);
      case 'onCallLogChanged':
        onCallLogChanged?.call();
    }
  }

  // Setup
  Future<bool> isDefaultDialer() async => await _methods.invokeMethod<bool>('isDefaultDialer') ?? false;

  Future<bool> requestDefaultDialer() async => await _methods.invokeMethod<bool>('requestDefaultDialer') ?? false;

  /// Brings the ongoing call's screen back (the "return to call" banner).
  Future<void> showInCallScreen() => _methods.invokeMethod('showInCallScreen');

  /// The `tel:` number the app was launched with, if any (returned once).
  Future<String?> consumeDialNumber() => _methods.invokeMethod<String>('consumeDialNumber');

  /// Whether the app was opened from the missed-call notification (returned once).
  Future<bool> consumeOpenRecents() async => await _methods.invokeMethod<bool>('consumeOpenRecents') ?? false;

  Future<Map<Object?, Object?>?> consumeContactAction() =>
      _methods.invokeMapMethod<Object?, Object?>('consumeContactAction');

  /// Android's photo picker; returns the picked photo as JPEG bytes (max 720px), or null.
  Future<Uint8List?> pickPhoto() => _methods.invokeMethod<Uint8List>('pickPhoto');

  /// The camera's quick capture (a small photo); null when cancelled.
  Future<Uint8List?> takePhoto() => _methods.invokeMethod<Uint8List>('takePhoto');

  // Contact extras (ContactExtras.kt)
  /// WhatsApp / WhatsApp Business chat rows for a contact: label, dataId, mimeType, icon (PNG bytes).
  Future<List<Map<Object?, Object?>>> getMessagingApps(String contactId) async =>
      await _methods.invokeListMethod<Map<Object?, Object?>>('getMessagingApps', {'contactId': contactId}) ?? const [];

  Future<void> openContactData(int dataId, String mimeType) =>
      _methods.invokeMethod('openContactData', {'dataId': dataId, 'mimeType': mimeType});

  /// The accounts' copies linked into a contact: id, name, accountType, accountName.
  Future<List<Map<Object?, Object?>>> getRawContacts(String contactId) async =>
      await _methods.invokeListMethod<Map<Object?, Object?>>('getRawContacts', {'contactId': contactId}) ?? const [];

  /// Where a new contact can be saved: {type, name}; null type and name is the phone itself.
  Future<List<Map<Object?, Object?>>> getContactAccounts() async =>
      await _methods.invokeListMethod<Map<Object?, Object?>>('getContactAccounts') ?? const [];

  /// An empty contact on the phone itself (no account), to fill in with update; its id.
  Future<String> createLocalContact() async => (await _methods.invokeMethod<String>('createLocalContact'))!;

  /// Joins the contacts into one (Android's "link"), for Merge duplicates.
  Future<void> mergeContacts(List<String> contactIds) =>
      _methods.invokeMethod('mergeContacts', {'contactIds': contactIds});

  /// A .vcf file's text from the files app; null when cancelled.
  Future<String?> pickVcf() => _methods.invokeMethod<String>('pickVcf');

  Future<void> unlinkRawContacts(String contactId, List<int> rawIds) =>
      _methods.invokeMethod('unlinkRawContacts', {'contactId': contactId, 'rawIds': rawIds});

  /// The contact's custom ringtone URI, or null for the default.
  Future<String?> getRingtone(String contactId) =>
      _methods.invokeMethod<String>('getRingtone', {'contactId': contactId});

  /// The contact's custom ringtone's name, or null when it follows the system.
  Future<String?> getRingtoneTitle(String contactId) =>
      _methods.invokeMethod<String>('getRingtoneTitle', {'contactId': contactId});

  Future<void> setRingtone(String contactId, String? uri) =>
      _methods.invokeMethod('setRingtone', {'contactId': contactId, 'uri': uri});

  /// Android's ringtone picker. Returns the picked URI, "" for Default, or null if cancelled.
  Future<String?> pickRingtone(String? current) => _methods.invokeMethod<String>('pickRingtone', {'current': current});

  // Settings
  Future<List<String>> getQuickReplies() async =>
      await _methods.invokeListMethod<String>('getQuickReplies') ?? const [];

  Future<void> setQuickReplies(List<String> replies) => _methods.invokeMethod('setQuickReplies', {'replies': replies});

  /// What incoming calls need (default dialer, notifications, full-screen, screening) plus the app version.
  Future<Map<Object?, Object?>> getCallHealth() async =>
      await _methods.invokeMapMethod<Object?, Object?>('getCallHealth') ?? const {};

  /// The launcher icon style (`default`, which is Glossy, or `classic`) for both Phone and Contacts.
  Future<String> getLauncherIcon() async => await _methods.invokeMethod<String>('getLauncherIcon') ?? 'default';

  Future<void> setLauncherIcon(String style) => _methods.invokeMethod('setLauncherIcon', {'style': style});

  /// The visual effects level this phone starts on (`DeviceTier.kt`): `tier` (`off`, `reduced` or
  /// `full`), `source` (`soc`, `platform`, `gpu` or `ram`) and the raw `soc`, `platform`,
  /// `hardware` and `gpu` strings it was read from.
  Future<Map<String, Object?>> effectsDefault() async =>
      (await _methods.invokeMapMethod<String, Object?>('effectsDefault')) ?? const {};

  /// `notifications`, `fullScreen`, `defaultApps`, `contactsStorage`, `googleContactsSync`, `app`,
  /// or `url:https://…`. Throws `NO_ACTIVITY` when the phone has no such screen.
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

  /// Settings › Incoming call reminders and Answer/End calls (`CallPrefs.kt`, read by the call service):
  /// `incomingStyle`, `vibrateAnswerEnd`, `speakerDefault`, `autoAnswer`, `autoAnswerDelay`.
  /// Settings › Language: `system` or a language tag (`AppLanguage.kt`).
  Future<String> getAppLanguage() async => await _methods.invokeMethod<String>('getAppLanguage') ?? 'system';

  Future<void> setAppLanguage(String tag) => _methods.invokeMethod('setAppLanguage', {'tag': tag});

  Future<Map<Object?, Object?>> getCallSettings() async =>
      await _methods.invokeMapMethod<Object?, Object?>('getCallSettings') ?? const {};

  Future<void> setCallSetting(String key, Object value) =>
      _methods.invokeMethod('setCallSetting', {'key': key, 'value': value});

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

  /// Calls back call-log row [id]; an app's row (WhatsApp...) is called back by that app.
  Future<void> callBack(int id) => _methods.invokeMethod('callBack', {'id': id});

  final _appIcons = <String, Future<Uint8List?>>{};

  /// [package]'s launcher icon as a PNG, fetched once per run.
  Future<Uint8List?> appIcon(String package) =>
      _appIcons[package] ??= _methods.invokeMethod<Uint8List>('getAppIcon', {'package': package});

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
  Future<void> rejectWithMessage(String id, String message) => _call('rejectWithMessage', id, {'message': message});

  /// Opens the keypad to place another call; Telecom holds the current one.
  Future<void> openDialer() => _methods.invokeMethod('openDialer');

  /// Whether Google Meet can take a video call to a number.
  Future<bool> canMeetCall() async => await _methods.invokeMethod<bool>('canMeetCall') ?? false;

  /// Opens a Google Meet video call to [number]; false if Meet couldn't start.
  Future<bool> meetCall(String number) async =>
      await _methods.invokeMethod<bool>('meetCall', {'number': number}) ?? false;
  Future<void> hangUp(String id) => _call('hangUp', id);
  Future<void> hold(String id) => _call('hold', id);
  Future<void> unhold(String id) => _call('unhold', id);
  Future<void> merge(String id) => _call('merge', id);
  Future<void> swap(String id) => _call('swap', id);

  Future<void> playDtmf(String id, String digit) => _call('playDtmf', id, {'digit': digit});
  Future<void> stopDtmf(String id) => _call('stopDtmf', id);

  // Audio
  Future<void> setMuted(bool muted) => _methods.invokeMethod('setMuted', {'muted': muted});

  Future<void> setAudioRoute(AudioRoute route) => _methods.invokeMethod('setAudioRoute', {'route': route.name});

  /// Moves the call to one Bluetooth device ([AudioInfo.bluetoothDevices]' id).
  Future<void> setBluetoothDevice(String id) => _methods.invokeMethod('setBluetoothDevice', {'id': id});

  /// Acts on one call. NO_CALL means it ended between the tap and the action (the caller hung
  /// up as you pressed a button): there is nothing left to do, so it isn't an error.
  Future<void> _call(String method, String id, [Map<String, Object?> extra = const {}]) async {
    try {
      await _methods.invokeMethod(method, {'id': id, ...extra});
    } on PlatformException catch (e) {
      if (e.code != 'NO_CALL') rethrow;
    }
  }
}
