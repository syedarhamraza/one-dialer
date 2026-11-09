import 'package:dialer/features/keypad/special_codes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('secret codes carry their digits', () {
    expect((specialCode('*#*#4636#*#*') as SecretCode).digits, '4636');
  });

  test('IMEI and SAR are device codes', () {
    expect((specialCode('*#06#') as DeviceCode).isImei, isTrue);
    expect((specialCode('*#07#') as DeviceCode).isImei, isFalse);
  });

  test('network codes, numbers and partial codes are dialled', () {
    for (final n in [
      '*#21#',
      '*123#',
      '03001234567',
      '*#06',
      '*#*#4636#*#',
      '#*#06#',
    ]) {
      expect(specialCode(n), isNull, reason: n);
    }
  });
}
