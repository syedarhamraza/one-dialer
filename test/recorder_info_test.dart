import 'package:dialer/core/telecom/call_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a running helper records both sides', () {
    final r = RecorderInfo.fromMap({
      'ready': true,
      'canRecord': true,
      'method': 'shell',
      'helperPaired': true,
      'helperRunning': true,
    });
    expect(r.ready, isTrue);
    expect(r.method, 'shell');
    expect(r.helperRunning, isTrue);
  });

  test('missing keys leave the recorder unable to record', () {
    final r = RecorderInfo.fromMap(const {});
    expect(r.canRecord, isFalse);
    expect(r.method, 'none');
    expect(r.ready, isFalse);
  });
}
