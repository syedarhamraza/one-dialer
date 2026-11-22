import 'dart:async';

import 'package:dialer/core/telecom/telecom_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs around every test file: the SIM list [TelecomBridge.quickSims] keeps would otherwise
/// carry one test's mocked SIMs into the next.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(TelecomBridge.forgetSims);
  await testMain();
}
