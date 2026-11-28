import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/security/app_lock.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_toast.dart';
import '../contacts/contact_actions.dart';
import '../contacts/manage_contacts_screen.dart';
import 'vault_screen.dart';

typedef VaultContact = ({String id, String name, List<String> numbers, String vcard});
typedef VaultCall = ({String number, int date, int duration, int type});

/// The private vault's Dart side; the encrypted store and the call-log sweep are `Vault.kt`.
abstract final class PrivateVault {
  static final _bridge = TelecomBridge.instance;

  static Future<({List<VaultContact> contacts, List<VaultCall> calls})> read() async {
    final data = await _bridge.vaultRead();
    return (
      contacts: [
        for (final c in (data['contacts'] as List?) ?? const [])
          if (c is Map)
            (
              id: c['id'] as String,
              name: c['name'] as String? ?? '',
              numbers: [for (final n in (c['numbers'] as List?) ?? const []) n as String],
              vcard: c['vcard'] as String,
            ),
      ],
      calls: [
        for (final c in (data['calls'] as List?) ?? const [])
          if (c is Map)
            (
              number: c['number'] as String,
              date: c['date'] as int,
              duration: c['duration'] as int,
              type: c['type'] as int,
            ),
      ],
    );
  }

  /// Contacts ⋮ › Private vault and Settings › Privacy & security: asks every time.
  static Future<void> open(BuildContext context) async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    try {
      if (!await _bridge.appLockAvailable()) {
        if (context.mounted) OneUIToast.show(context, l10n.appLockNeedsScreenLock);
        return;
      }
    } on PlatformException {
      return;
    }
    if (!await AppLock.instance.authenticate(l10n.unlockPrivateVault)) return;
    navigator.push(MaterialPageRoute<void>(builder: (_) => const VaultScreen()));
  }

  /// Contact page › Move to private vault: saved in the vault (its calls move with it) before
  /// it's deleted from Android's contacts, so a failure never loses it. True when moved.
  static Future<bool> moveIn(BuildContext context, Contact full) async {
    final l10n = context.l10n;
    final name = full.displayName?.trim() ?? '';
    final ok = await showCosConfirm(
      context,
      title: l10n.moveToVaultTitle(name.isEmpty ? l10n.unknown : name),
      message: l10n.moveToVaultMessage,
      confirmLabel: l10n.move,
    );
    if (!ok || !context.mounted) return false;
    // The vault holds the phone's real lock: it asks before anything leaves Android's contacts.
    if (!await AppLock.instance.authenticate(l10n.unlockPrivateVault)) return false;
    try {
      await _bridge.vaultAdd(name, [for (final p in full.phones) p.number], FlutterContacts.vCard.export(full));
    } on PlatformException {
      if (context.mounted) OneUIToast.show(context, l10n.couldNotOpenVault);
      return false;
    }
    if (full.id != null) await ContactsRepository.instance.delete([full.id!]);
    if (context.mounted) OneUIToast.show(context, l10n.movedToVault);
    return true;
  }

  /// Saved back to Android's contacts first, then taken out with its calls.
  static Future<bool> moveOut(BuildContext context, VaultContact contact) async {
    final l10n = context.l10n;
    final parsed = importVCards(contact.vcard);
    if (parsed == null || parsed.isEmpty) {
      OneUIToast.show(context, l10n.couldNotOpenFile);
      return false;
    }
    try {
      await FlutterContacts.create(parsed.first, account: saveAccount());
      await _bridge.vaultRemove(contact.id, restoreCalls: true);
    } on Object {
      if (context.mounted) OneUIToast.show(context, l10n.couldNotOpenVault);
      return false;
    }
    if (context.mounted) OneUIToast.show(context, l10n.movedOutOfVault);
    return true;
  }

  static Future<bool> delete(BuildContext context, VaultContact contact) async {
    final l10n = context.l10n;
    final ok = await showCosConfirm(
      context,
      title: l10n.deleteContactTitle(contact.name),
      message: l10n.deleteFromVaultMessage,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return false;
    await _bridge.vaultRemove(contact.id, restoreCalls: false);
    return true;
  }

  /// Import into vault: a .vcf's contacts go straight in, never through Android's contacts.
  static Future<int> import(BuildContext context) async {
    final l10n = context.l10n;
    final String? text;
    try {
      text = await _bridge.pickVcf();
    } on PlatformException {
      if (context.mounted) OneUIToast.show(context, l10n.couldNotOpenFile);
      return 0;
    }
    if (text == null || !context.mounted) return 0;
    final contacts = importVCards(text);
    if (contacts == null) {
      OneUIToast.show(context, l10n.couldNotOpenFile);
      return 0;
    }
    if (contacts.isEmpty) {
      OneUIToast.show(context, l10n.noContactsInFile);
      return 0;
    }
    for (final c in contacts) {
      await _bridge.vaultAdd(c.displayName?.trim() ?? '', [
        for (final p in c.phones) p.number,
      ], FlutterContacts.vCard.export(c));
    }
    if (context.mounted) OneUIToast.show(context, l10n.contactsImported(contacts.length));
    return contacts.length;
  }

  /// Export: one .vcf through the share sheet, after saying it isn't encrypted.
  static Future<void> export(BuildContext context, List<VaultContact> contacts) async {
    final l10n = context.l10n;
    final ok = await showCosConfirm(
      context,
      title: l10n.exportContacts,
      message: l10n.vaultExportMessage,
      confirmLabel: l10n.exportContacts,
    );
    if (!ok) return;
    final vcard = contacts.map((c) => c.vcard.trim()).join('\n');
    final parsed = importVCards(vcard) ?? const <Contact>[];
    await ContactActions.shareVCards(l10n, parsed);
  }
}
