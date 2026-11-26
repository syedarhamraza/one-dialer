import 'package:flutter/material.dart';

import '../core/prefs/dialer_prefs.dart';
import '../core/telecom/telecom_bridge.dart';
import '../l10n/l10n.dart';
import '../widgets/cos_dialog.dart';

/// SHA-256 of One Dialer's signing certificates, as pinned in the recorder's `TrustedDialer.kt`:
/// Play app signing, the upload key, and the maintainer's debug key.
const officialCertHashes = {
  'f2eb6384aa959b7c24455f1c5708e26ddb297e70f174de2505b219b65f5803de',
  'bed3b0971aa8f61eef04a76331d19c05fb3da960415cefc414dfa0cb0d291261',
  'b11c05d54364c5a210a3a5d809f4c3b19350817aefe8639a3bf515ee17a9a65b',
};

/// Whether any of [hashes] (the copy's signing history, newest last) is one of ours. Unknown
/// (null or empty) counts as official, so a failed read never nags real users.
bool isOfficialCert(List<String>? hashes) =>
    hashes == null ||
    hashes.isEmpty ||
    hashes.any((hash) => officialCertHashes.contains(hash.trim().toLowerCase()));

/// Whether this copy is signed by One Dialer's own keys (read once); true on any error.
Future<bool> isOfficialBuild() => _official ??= () async {
  try {
    return isOfficialCert(await TelecomBridge.instance.signingCertHashes());
  } on Object {
    return true;
  }
}();

Future<bool>? _official;

/// Says, once ever, that this copy is a rebuild by someone else, with credit to the original.
Future<void> noteIfUnofficial(
  BuildContext context, {
  @visibleForTesting Future<bool> Function() official = isOfficialBuild,
}) async {
  if (await official() || await DialerPrefs.instance.unofficialNoted()) return;
  // Marked before showing, so a kill mid-dialog never shows it again.
  await DialerPrefs.instance.setUnofficialNoted();
  if (!context.mounted) return;
  await showCosActions<void>(
    context,
    title: context.l10n.unofficialBuildTitle,
    message: context.l10n.unofficialBuildCredit,
    actions: [(label: context.l10n.ok, value: null, destructive: false)],
  );
}
