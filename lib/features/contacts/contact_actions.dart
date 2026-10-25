import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_dialog.dart';
import 'contact_qr.dart';

/// Contact-page actions behind Share and More.
abstract final class ContactActions {
  /// Share › vCard file (VCF).
  static Future<void> shareVCard(Contact contact) => shareVCards([contact]);

  /// Several contacts in one .vcf (selection mode's Share).
  static Future<void> shareVCards(List<Contact> contacts) async {
    if (contacts.isEmpty) return;
    final vcard = contacts.map((c) => FlutterContacts.vCard.export(c)).join('\n');
    final first = contacts.first;
    final name = contacts.length > 1
        ? '${contacts.length} contacts'
        : (first.displayName?.trim().isNotEmpty ?? false)
        ? first.displayName!.trim()
        : 'contact';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(vcard), mimeType: 'text/x-vcard', name: '$name.vcf')],
        fileNameOverrides: ['$name.vcf'],
      ),
    );
  }

  /// Share › Text: name and numbers, one per line.
  static Future<void> shareText(DialerContact contact) => SharePlus.instance.share(
    ShareParams(
      text: [contact.name, for (final (i, n) in contact.numbers.indexed) '${contact.labels[i]}: $n'].join('\n'),
    ),
  );

  /// More › QR code: the contact as a vCard QR that other phones' cameras can add.
  static Future<void> showQr(BuildContext context, Contact contact) => showCosCard<void>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          contact.displayName ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
        ),
        const SizedBox(height: 18),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
            ),
            child: QrImageView(
              // Without photos: QR codes hold only a few KB.
              data: contactQrPayload(contact),
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Scan with a phone camera to add this contact',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15.5, height: 1.35, color: OneUITheme.textSecondary),
        ),
        const SizedBox(height: 24),
        CosPill(label: 'Close', onTap: () => Navigator.pop(ctx)),
      ],
    ),
  );

  /// More › Change ringtone/vibration (Android's ringtone picker).
  static Future<void> changeRingtone(String contactId) async {
    final bridge = TelecomBridge.instance;
    final picked = await bridge.pickRingtone(await bridge.getRingtone(contactId));
    if (picked == null) return; // cancelled
    await bridge.setRingtone(contactId, picked.isEmpty ? null : picked);
  }

  /// More › Delete. Returns whether it was deleted.
  static Future<bool> delete(BuildContext context, String contactId, String name) async {
    final ok = await showCosConfirm(
      context,
      title: 'Delete $name?',
      message: 'This contact will be removed from this phone and from its accounts.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return false;
    await ContactsRepository.instance.delete([contactId]);
    return true;
  }
}
