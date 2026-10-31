import '../core/telecom/call_info.dart';

const _ongoing = {CallState.active, CallState.holding, CallState.dialing, CallState.connecting};

/// The call the nav bar's return-to-call button brings back, the active one first; null while
/// nothing is ongoing. Ringing calls have their own full-screen notification.
CallInfo? ongoingCall(CallSnapshot? snapshot) {
  final calls = (snapshot?.calls ?? const <CallInfo>[]).where((c) => _ongoing.contains(c.state));
  return calls.where((c) => c.state == CallState.active).firstOrNull ?? calls.firstOrNull;
}
