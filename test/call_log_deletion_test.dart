import 'dart:async';

import 'package:dialer/core/telecom/telecom_bridge.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/recents/call_log_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repo = CallLogRepository.instance;
  final bridge = TelecomBridge.instance;
  late Completer<void> deletion;
  late List<Map<String, Object>> native;
  Map<String, Object> row(int id) => {'id': id, 'number': '$id', 'type': 'incoming', 'date': id};
  setUp(() {
    deletion = Completer<void>();
    native = [row(2), row(1)];
    repo.calls.value = native.map(CallLogEntry.fromMap).toList();
    bridge.onCallLogChanged = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.syedarhamraza.dialer/telecom'),
      (call) async {
        if (call.method == 'getCallLog') return native;
        if (call.method == 'deleteCalls') await deletion.future;
        return null;
      },
    );
  });
  tearDown(() => repo.calls.value = []);

  test('deletion is immediate and observer refresh cannot resurrect pending rows', () async {
    await repo.start();
    final done = repo.delete([1]);
    expect(repo.calls.value.map((c) => c.id), [2]);
    bridge.onCallLogChanged!();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repo.calls.value.map((c) => c.id), [2]);
    native = [row(3), row(2)];
    deletion.complete();
    await done;
    expect(repo.calls.value.map((c) => c.id), [3, 2]);
  });

  test('failed deletion restores its rows without losing newly arrived calls', () async {
    await repo.start();
    final done = repo.delete([1]);
    final failed = expectLater(done, throwsA(isA<PlatformException>()));
    native = [row(3), row(2), row(1)];
    bridge.onCallLogChanged!();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    deletion.completeError(PlatformException(code: 'DENIED'));
    await failed;
    expect(repo.calls.value.map((c) => c.id), [3, 2, 1]);
  });
}
