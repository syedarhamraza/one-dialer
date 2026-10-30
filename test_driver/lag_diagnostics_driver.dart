import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final output = File('build/lag-diagnostics-results.json');
    await output.parent.create(recursive: true);
    await output.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  },
);
