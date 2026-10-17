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
  });

  factory AudioInfo.fromMap(Map<Object?, Object?> map) => AudioInfo(
    muted: map['muted'] as bool? ?? false,
    route: AudioRoute.parse(map['route'] as String?),
    supportedRoutes: (map['supportedRoutes'] as List<Object?>? ?? const [])
        .map((r) => AudioRoute.parse(r as String?))
        .toList(),
  );

  final bool muted;
  final AudioRoute route;
  final List<AudioRoute> supportedRoutes;
}

/// Everything the in-call UI needs, pushed on every Telecom change.
class CallSnapshot {
  const CallSnapshot({this.calls = const [], this.audio = const AudioInfo()});

  factory CallSnapshot.fromMap(Map<Object?, Object?> map) => CallSnapshot(
    calls: (map['calls'] as List<Object?>? ?? const [])
        .map((c) => CallInfo.fromMap(c! as Map<Object?, Object?>))
        .toList(),
    audio: map['audio'] == null ? const AudioInfo() : AudioInfo.fromMap(map['audio']! as Map<Object?, Object?>),
  );

  final List<CallInfo> calls;
  final AudioInfo audio;

  /// The call the in-call screen should focus on.
  CallInfo? get primary {
    if (calls.isEmpty) return null;
    return calls.firstWhere(
      (c) => c.state == CallState.ringing,
      orElse: () => calls.firstWhere((c) => c.state != CallState.holding, orElse: () => calls.first),
    );
  }
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
