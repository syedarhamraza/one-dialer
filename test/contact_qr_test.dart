import 'package:dialer/features/contacts/contact_qr.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QR is a MECARD with every number, escaped name and no photo', () {
    final data = contactQrPayload(
      Contact(
        displayName: 'علی; Khan, A\\B\nOffice',
        phones: const [
          Phone(number: '+92 300 1234567', label: Label(PhoneLabel.mobile)),
          Phone(number: ' 0421234567 ', label: Label(PhoneLabel.custom, 'Desk')),
          Phone(number: ' '),
        ],
      ),
    );
    expect(data, r'MECARD:N:علی\; Khan\, A\\B Office;TEL:+92 300 1234567;TEL:0421234567;;');
  });
  test('QR falls back to structured name when display name is absent', () {
    final data = contactQrPayload(
      Contact(
        name: const Name(first: 'Ada', last: 'Lovelace'),
        phones: const [Phone(number: '+4412345')],
      ),
    );
    expect(data, 'MECARD:N:Ada Lovelace;TEL:+4412345;;');
  });
}
