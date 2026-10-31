import 'package:dialer/core/telecom/telecom_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.syedarhamraza.dialer/telecom');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var error = 'NO_CALL';

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      throw PlatformException(code: error);
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('acting on a call that already ended is not an error', () async {
    error = 'NO_CALL';
    final bridge = TelecomBridge.instance;
    await bridge.hangUp('call-1');
    await bridge.answer('call-1');
    await bridge.rejectWithMessage('call-1', 'Busy');
    await bridge.playDtmf('call-1', '5');
    expect(calls.map((c) => c.method), ['hangUp', 'answer', 'rejectWithMessage', 'playDtmf']);
    expect(calls[2].arguments, {'id': 'call-1', 'message': 'Busy'});
    expect(calls[3].arguments, {'id': 'call-1', 'digit': '5'});
  });

  test('other failures still reach the caller', () async {
    error = 'NO_PERMISSION';
    expect(() => TelecomBridge.instance.hangUp('call-1'), throwsA(isA<PlatformException>()));
  });
}
