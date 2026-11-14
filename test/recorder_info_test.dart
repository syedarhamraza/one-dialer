import 'package:dialer/core/telecom/call_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a One Recorder from before both sides reads as the microphone method', () {
    final r = RecorderInfo.fromMap({
      'ready': true,
      'canRecord': true,
      'method': 'mic',
      'accessibilityOn': true,
      'micGranted': true,
    });
    expect(r.canRecord, isTrue);
    expect(r.method, 'mic');
    expect(r.helperPaired, isFalse);
    expect(r.helperRunning, isFalse);
  });

  test('both sides needs neither the microphone nor the accessibility service', () {
    final r = RecorderInfo.fromMap({
      'ready': true,
      'canRecord': true,
      'method': 'shell',
      'helperPaired': true,
      'helperRunning': true,
      'accessibilityOn': false,
      'micGranted': false,
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
