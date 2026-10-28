import 'package:flutter_test/flutter_test.dart';

import 'package:dialer/core/telecom/call_info.dart';

void main() {
  test('primary call prefers ringing over held calls', () {
    final snapshot = CallSnapshot.fromMap({
      'calls': [
        {'id': 'call-0', 'state': 'holding', 'number': '111'},
        {'id': 'call-1', 'state': 'ringing', 'number': '222'},
      ],
      'audio': {
        'muted': true,
        'route': 'speaker',
        'supportedRoutes': ['earpiece', 'speaker'],
      },
    });

    expect(snapshot.primary?.id, 'call-1');
    expect(snapshot.audio.muted, isTrue);
    expect(snapshot.audio.route, AudioRoute.speaker);
  });
}
