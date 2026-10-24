import 'package:flutter_contacts/flutter_contacts.dart';

/// MECARD, not vCard: phone camera scanners read its TEL fields reliably, while some
/// (vivo's among them) add a vCard QR's name but drop every TEL;TYPE= line.
String contactQrPayload(Contact contact) {
  String escape(String value) =>
      value.replaceAll(RegExp(r'[\r\n]+'), ' ').replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');
  final name = contact.name;
  final displayName = contact.displayName?.trim();
  final fullName = displayName != null && displayName.isNotEmpty
      ? displayName
      : [name?.first, name?.middle, name?.last].whereType<String>().where((s) => s.isNotEmpty).join(' ');
  return [
    'MECARD:N:${escape(fullName)}',
    for (final phone in contact.phones)
      if (phone.number.trim().isNotEmpty) 'TEL:${escape(phone.number.trim())}',
    ';',
  ].join(';');
}
