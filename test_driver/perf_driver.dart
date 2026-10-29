import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Writes integration_test/perf_test.dart's frame timings to `build/perf/$PERF_DEVICE.json`.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final device = Platform.environment['PERF_DEVICE'] ?? 'device';
    final file = File('build/perf/$device.json');
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln('Wrote ${file.path}');
  },
);
