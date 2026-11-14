import 'dart:ui';

/// State of a call as reported by Android Telecom (see `CallManager.kt`).
enum CallState {
  newCall,
  dialing,
  connecting,
  ringing,
  active,
  holding,
  disconnecting,
  disconnected,
  selectPhoneAccount,
  unknown;

  static CallState parse(String? raw) => switch (raw) {
    'new' => newCall,
    'dialing' => dialing,
    'connecting' => connecting,
    'ringing' => ringing,
    'active' => active,
    'holding' => holding,
    'disconnecting' => disconnecting,
    'disconnected' => disconnected,
    'selectPhoneAccount' => selectPhoneAccount,
    _ => unknown,
  };
}

enum AudioRoute {
  earpiece,
  speaker,
  bluetooth,
  wiredHeadset;

  static AudioRoute parse(String? raw) => values.firstWhere((r) => r.name == raw, orElse: () => earpiece);
}

class CallInfo {
  const CallInfo({
    required this.id,
    required this.state,
    this.number,
    this.name,
    this.connectTime,
    this.isConference = false,
    this.canHold = false,
    this.canMerge = false,
    this.canSwap = false,
    this.simId,
    this.isHd = false,
    this.isWifi = false,
    this.isPrivate = false,
    this.formattedNumber,
    this.location,
    this.disconnectCode,
    this.disconnectLabel,
  });

  factory CallInfo.fromMap(Map<Object?, Object?> map) {
    final connectMillis = map['connectTimeMillis'] as int? ?? 0;
    return CallInfo(
      id: map['id'] as String,
      state: CallState.parse(map['state'] as String?),
      number: map['number'] as String?,
      name: map['name'] as String?,
      connectTime: connectMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(connectMillis) : null,
      isConference: map['isConference'] as bool? ?? false,
      canHold: map['canHold'] as bool? ?? false,
      canMerge: map['canMerge'] as bool? ?? false,
      canSwap: map['canSwap'] as bool? ?? false,
      simId: map['simId'] as String?,
      isHd: map['isHd'] as bool? ?? false,
      isWifi: map['isWifi'] as bool? ?? false,
      isPrivate: map['isPrivate'] as bool? ?? false,
      formattedNumber: map['formattedNumber'] as String?,
      location: map['location'] as String?,
      disconnectCode: map['disconnectCode'] as String?,
      disconnectLabel: map['disconnectLabel'] as String?,
    );
  }

  final String id;
  final CallState state;
  final String? number;
  final String? name;
  final DateTime? connectTime;
  final bool isConference;
  final bool canHold;
  final bool canMerge;
  final bool canSwap;

  /// Matches `SimCard.id`.
  final String? simId;
  final bool isHd;
  final bool isWifi;

  /// Caller hid their number.
  final bool isPrivate;

  /// Grouped for display (`0300 1234567`); null when the number can't be parsed.
  final String? formattedNumber;

  /// Country of a foreign caller; null for domestic numbers.
  final String? location;

  /// Why the call ended: busy, rejected, missed, error, local, remote, canceled.
  final String? disconnectCode;

  /// The carrier's own explanation, when it gave one.
  final String? disconnectLabel;

  String get displayName => (name?.isNotEmpty ?? false) ? name! : (number ?? 'Unknown');
}

class AudioInfo {
  const AudioInfo({
    this.muted = false,
    this.route = AudioRoute.earpiece,
    this.supportedRoutes = const [AudioRoute.earpiece],
    this.bluetoothDevices = const [],
    this.activeBluetooth,
  });

  factory AudioInfo.fromMap(Map<Object?, Object?> map) => AudioInfo(
    muted: map['muted'] as bool? ?? false,
    route: AudioRoute.parse(map['route'] as String?),
    supportedRoutes: (map['supportedRoutes'] as List<Object?>? ?? const [])
        .map((r) => AudioRoute.parse(r as String?))
        .toList(),
    bluetoothDevices: [
      for (final d in map['bluetoothDevices'] as List<Object?>? ?? const [])
        if (d case {'id': final String id, 'name': final String? name}) (id: id, name: name),
    ],
    activeBluetooth: map['activeBluetooth'] as String?,
  );

  final bool muted;
  final AudioRoute route;
  final List<AudioRoute> supportedRoutes;

  /// Connected Bluetooth devices (a watch and earbuds at once); [name] is null without the
  /// Nearby devices permission.
  final List<({String id, String? name})> bluetoothDevices;

  /// The [bluetoothDevices] id the call is on, when it's on Bluetooth.
  final String? activeBluetooth;

  /// A device's name, or "Bluetooth 2" when Android hides names.
  String bluetoothLabel(int index) {
    final name = bluetoothDevices[index].name;
    if (name != null && name.isNotEmpty) return name;
    return bluetoothDevices.length > 1 ? 'Bluetooth ${index + 1}' : 'Bluetooth';
  }

  /// The label for the device in use, or 'Bluetooth' when Android doesn't say which.
  String get activeBluetoothLabel {
    final i = bluetoothDevices.indexWhere((d) => d.id == activeBluetooth);
    return i < 0 ? 'Bluetooth' : bluetoothLabel(i);
  }
}

/// Everything the in-call UI needs, pushed on every Telecom change.
class CallSnapshot {
  const CallSnapshot({this.calls = const [], this.audio = const AudioInfo(), this.recording});

  factory CallSnapshot.fromMap(Map<Object?, Object?> map) => CallSnapshot(
    calls: (map['calls'] as List<Object?>? ?? const [])
        .map((c) => CallInfo.fromMap(c! as Map<Object?, Object?>))
        .toList(),
    audio: map['audio'] == null ? const AudioInfo() : AudioInfo.fromMap(map['audio']! as Map<Object?, Object?>),
    recording: map['recording'] == null ? null : RecorderInfo.fromMap(map['recording']! as Map<Object?, Object?>),
  );

  final List<CallInfo> calls;
  final AudioInfo audio;

  /// The companion recorder's state; null when it isn't installed (no recording UI then).
  final RecorderInfo? recording;

  /// The call the in-call screen should focus on.
  CallInfo? get primary {
    if (calls.isEmpty) return null;
    return calls.firstWhere(
      (c) => c.state == CallState.ringing,
      orElse: () => calls.firstWhere((c) => c.state != CallState.holding, orElse: () => calls.first),
    );
  }
}

/// One Recorder, the sideloaded companion (`RecorderCompanion.kt`).
class RecorderInfo {
  const RecorderInfo({
    this.ready = false,
    this.recording = false,
    this.trusted = true,
    this.accessibilityOn = false,
    this.micGranted = false,
    this.consented = false,
    this.autoRecordMode = 'off',
    this.bytes = 0,
    this.error,
  });

  factory RecorderInfo.fromMap(Map<Object?, Object?> map) => RecorderInfo(
    ready: map['ready'] as bool? ?? false,
    recording: map['recording'] as bool? ?? false,
    trusted: map['trusted'] as bool? ?? true,
    accessibilityOn: map['accessibilityOn'] as bool? ?? false,
    micGranted: map['micGranted'] as bool? ?? false,
    consented: map['consented'] as bool? ?? false,
    autoRecordMode: map['autoRecordMode'] as String? ?? 'off',
    bytes: map['bytes'] as int? ?? 0,
    error: map['error'] as String?,
  );

  /// Set up (mic, accessibility service) and the consent notice accepted.
  final bool ready;
  final bool recording;

  /// False when the companion refuses this build (its signing certificate isn't pinned).
  final bool trusted;
  final bool accessibilityOn;
  final bool micGranted;
  final bool consented;

  /// Auto-record rule: `off`, `all`, `unknown` or `contacts` (`RecordRules.kt`).
  final String autoRecordMode;

  /// Space the recordings take.
  final int bytes;

  /// Why the last start failed: `accessibility`, `microphone` or `start`.
  final String? error;
}

/// A saved recording, named `<startMillis>_<number>.m4a` by the companion.
class CallRecording {
  const CallRecording({
    required this.name,
    this.number,
    required this.start,
    required this.duration,
    required this.bytes,
    this.incoming,
    this.simId,
    this.starred = false,
    this.title,
  });

  factory CallRecording.fromMap(Map<Object?, Object?> map) => CallRecording(
    name: map['name']! as String,
    number: map['number'] as String?,
    start: DateTime.fromMillisecondsSinceEpoch(map['startMillis'] as int? ?? 0),
    duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
    bytes: map['bytes'] as int? ?? 0,
    incoming: switch (map['direction']) {
      'in' => true,
      'out' => false,
      _ => null,
    },
    simId: (map['simId'] as String?)?.nullIfEmpty,
    starred: map['starred'] as bool? ?? false,
    title: (map['title'] as String?)?.nullIfEmpty,
  );

  final String name;
  final String? number;
  final DateTime start;
  final Duration duration;
  final int bytes;

  /// Null for recordings made before direction was saved.
  final bool? incoming;
  final String? simId;
  final bool starred;

  /// The user's own name for it (Rename).
  final String? title;
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// A call-capable SIM (a Telecom phone account).
class SimCard {
  const SimCard({required this.id, required this.label, required this.color, this.isDefault = false});

  factory SimCard.fromMap(Map<Object?, Object?> map) => SimCard(
    id: map['id']! as String,
    label: (map['label'] as String?)?.trim().isNotEmpty == true ? map['label']! as String : 'SIM',
    color: Color(map['color'] as int? ?? 0xFF5390F5).withAlpha(0xFF),
    isDefault: map['isDefault'] as bool? ?? false,
  );

  final String id;
  final String label;
  final Color color;

  /// The SIM Android calls with by default; none is default when "Ask every time" is set.
  final bool isDefault;
}
