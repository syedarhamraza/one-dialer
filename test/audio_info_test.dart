import 'package:dialer/core/telecom/call_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the Bluetooth devices and the one in use', () {
    final audio = AudioInfo.fromMap({
      'route': 'bluetooth',
      'supportedRoutes': ['earpiece', 'speaker', 'bluetooth'],
      'bluetoothDevices': [
        {'id': 'AA', 'name': 'Galaxy Watch'},
        {'id': 'BB', 'name': 'Galaxy Buds'},
      ],
      'activeBluetooth': 'BB',
    });
    expect(audio.bluetoothDevices.map((d) => d.id), ['AA', 'BB']);
    expect(audio.bluetoothLabel(0), 'Galaxy Watch');
    expect(audio.activeBluetoothLabel, 'Galaxy Buds');
  });

  test('numbers devices when Android hides their names', () {
    final audio = AudioInfo.fromMap({
      'bluetoothDevices': [
        {'id': 'AA', 'name': null},
        {'id': 'BB', 'name': null},
      ],
      'activeBluetooth': 'AA',
    });
    expect(audio.bluetoothLabel(1), 'Bluetooth 2');
    expect(audio.activeBluetoothLabel, 'Bluetooth 1');
  });

  test('defaults to no devices', () {
    final audio = AudioInfo.fromMap({'route': 'speaker'});
    expect(audio.bluetoothDevices, isEmpty);
    expect(audio.activeBluetooth, isNull);
    expect(audio.activeBluetoothLabel, 'Bluetooth');
  });
}
