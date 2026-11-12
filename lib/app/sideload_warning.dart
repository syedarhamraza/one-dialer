import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/prefs/dialer_prefs.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/updates/data/update_service.dart';
import '../l10n/l10n.dart';
import '../widgets/cos_dialog.dart';
import 'app_info.dart';

/// Opens the website page that says how to get the official copy.
void openOfficialVersion() => TelecomBridge.instance.openSystemSettings('url:${AppInfo.officialUrl}');

/// Warns, once ever, that this copy wasn't installed from Google Play (an APK shared or
/// extracted by another app). Release builds only: debug and profile installs come from adb.
Future<void> warnIfSideloaded(
  BuildContext context, {
  @visibleForTesting bool release = kReleaseMode,
  @visibleForTesting Future<String?> Function() installer = PlayUpdateService.installerStore,
}) async {
  if (!release || await DialerPrefs.instance.sideloadWarned()) return;
  if (await installer() == PlayUpdateService.playStoreInstaller) return;
  // Marked before showing, so a kill mid-dialog never shows it again.
  await DialerPrefs.instance.setSideloadWarned();
  if (!context.mounted) return;
  final official = await showCosConfirm(
    context,
    title: context.l10n.notFromPlayTitle,
    message: context.l10n.notFromPlayWarning,
    cancelLabel: context.l10n.keepUsing,
    confirmLabel: context.l10n.getOfficialVersion,
  );
  if (official) openOfficialVersion();
}
