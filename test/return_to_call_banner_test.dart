import 'package:dialer/app/return_to_call_banner.dart';
import 'package:dialer/core/telecom/call_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> call(String id, String state) => {'id': id, 'state': state, 'number': '5550100'};
  CallInfo? ongoing(List<Map<String, Object?>> calls) => ongoingCall(CallSnapshot.fromMap({'calls': calls}));

  test('return to call shows for ongoing calls only, the active one first', () {
    expect(ongoingCall(null), isNull);
    expect(ongoing([]), isNull);
    expect(ongoing([call('a', 'ringing')]), isNull);
    expect(ongoing([call('a', 'dialing')])?.id, 'a');
    expect(ongoing([call('a', 'holding'), call('b', 'active')])?.id, 'b');
    expect(ongoing([call('a', 'disconnected')]), isNull);
  });
}
