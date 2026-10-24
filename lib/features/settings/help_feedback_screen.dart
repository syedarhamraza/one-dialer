import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';

/// Settings › Help & feedback: send feedback by email (with the app and phone details filled in),
/// and who made the app.
class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

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
      query: 'subject=${Uri.encodeComponent('${AppInfo.name} feedback')}'
          '&body=${Uri.encodeComponent('\n\n\n---\n$details')}',
    );
    if (context.mounted) await _open(context, '$mail', 'No email app found');
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Help & feedback',
      builder: (context) => [
        OneUIGroupCard(
          items: [OneUIGroupItem(title: 'Send feedback', onTap: () => _sendFeedback(context))],
        ),
        OneUIGroupCard(
          headerTitle: 'Developer',
          items: [
            const OneUIGroupItem(title: 'Name', value: AppInfo.developerName, trailing: SizedBox.shrink()),
            OneUIGroupItem(
              title: 'GitHub',
              value: AppInfo.developerGithub,
              onTap: () => _open(context, 'https://github.com/${AppInfo.developerGithub}', 'No browser found'),
            ),
          ],
        ),
      ],
    );
  }
}
