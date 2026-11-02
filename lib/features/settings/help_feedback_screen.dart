import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_info.dart';
import '../../core/diagnostics/lag_diagnostics.dart';
import '../../widgets/cos_dialog.dart';
import '../../core/config/app_version.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../../l10n/l10n.dart';

/// Settings › Help & feedback: send feedback by email (with the app and phone details filled in),
/// and who made the app.
class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  static Future<void> _reportLag(BuildContext context) async {
    final send = await showCosConfirm(
      context,
      title: context.l10n.reportLag,
      message: context.l10n.reportLagMessage,
      confirmLabel: context.l10n.sendReport,
    );
    if (!send || !context.mounted) return;
    final id = await LagDiagnostics.instance.reportLag();
    if (!context.mounted) return;
    if (id == null) {
      OneUIToast.show(context, context.l10n.reportUnavailable);
      return;
    }
    final copy = await showCosActions<bool>(
      context,
      title: context.l10n.reportQueued,
      message: context.l10n.reportQueuedMessage(id),
      actions: [
        (label: context.l10n.done, value: false, destructive: false),
        (label: context.l10n.copyId, value: true, destructive: false),
      ],
    );
    if (copy == true) {
      await Clipboard.setData(ClipboardData(text: id));
      if (context.mounted) OneUIToast.show(context, context.l10n.reportIdCopied);
    }
  }

  static Future<void> _open(BuildContext context, String url, String failure) async {
    try {
      await TelecomBridge.instance.openSystemSettings('url:$url');
    } on PlatformException {
      if (context.mounted) OneUIToast.show(context, failure);
    }
  }

  static Future<void> _sendFeedback(BuildContext context) async {
    final version = await AppVersion.current();
    var phone = '';
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      phone = '\nDevice: ${info.manufacturer} ${info.model}\nAndroid: ${info.version.release}';
    } catch (_) {
      // Not on Android (tests): no phone details.
    }
    final code = version?.code;
    final details = 'Version: ${version?.label ?? 'unknown'}${code == null ? '' : ' ($code)'}$phone';
    final mail = Uri(
      scheme: 'mailto',
      path: AppInfo.feedbackEmail,
      // Uri's queryParameters encodes spaces as '+', which mail apps show literally.
      query:
          'subject=${Uri.encodeComponent('${AppInfo.name} feedback')}'
          '&body=${Uri.encodeComponent('\n\n\n---\n$details')}',
    );
    if (context.mounted) await _open(context, '$mail', context.l10n.noEmailApp);
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: context.l10n.helpFeedback,
      builder: (context) => [
        OneUIGroupCard(
          items: [
            OneUIGroupItem(title: context.l10n.sendFeedback, onTap: () => _sendFeedback(context)),
            OneUIGroupItem(title: context.l10n.reportLag, onTap: () => _reportLag(context)),
          ],
        ),
        OneUIGroupCard(
          headerTitle: context.l10n.developer,
          items: [
            OneUIGroupItem(title: context.l10n.name, value: AppInfo.developerName, trailing: const SizedBox.shrink()),
            OneUIGroupItem(
              title: 'GitHub',
              value: AppInfo.developerGithub,
              onTap: () => _open(context, 'https://github.com/${AppInfo.developerGithub}', context.l10n.noBrowser),
            ),
          ],
        ),
      ],
    );
  }
}
