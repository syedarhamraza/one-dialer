import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/telecom/telecom_bridge.dart';

bool isWhatsAppNumber(String number) =>
    RegExp(r'^\+?[0-9]{3,15}$').hasMatch(number.replaceAll(RegExp(r'[\s().-]'), ''));

/// A handoff to WhatsApp, never a cellular call or an automatic chat fallback.
Future<void> openWhatsAppVoiceCall(BuildContext context, String number) async {
  final bridge = TelecomBridge.instance;
  void message(String text) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  try {
    final info = await bridge.getWhatsAppCalls(number);
    if (!context.mounted) return;
    final apps = (info['apps'] as List? ?? []).cast<Map>();
    final actions = (info['actions'] as List? ?? []).cast<Map>();
    if (apps.isEmpty) {
      message('WhatsApp is not installed.');
      return;
    }
    if (actions.isNotEmpty) {
      final app = await _chooseApp(context, actions);
      if (app == null || !context.mounted) return;
      try {
        await bridge.startWhatsAppCall(number, app);
        return;
      } on PlatformException {
        // An action may disappear between discovery and launch. Offer the same fallback.
      }
    }
    if (!context.mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp calling unavailable'),
        content: Text(
          info['hasContactsPermission'] == false
              ? 'Contacts access is needed to find WhatsApp call actions. You can open a chat and call from WhatsApp instead.'
              : 'There is no available WhatsApp voice-call action for this number. Open a chat to call from WhatsApp?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Open WhatsApp chat')),
        ],
      ),
    );
    if (open != true || !context.mounted) return;
    var international = info['internationalNumber'] as String?;
    international ??= await showDialog<String>(context: context, builder: (_) => const _CountryCodeDialog());
    if (international == null || !context.mounted) return;
    final app = await _chooseApp(context, apps);
    if (app != null) await bridge.openWhatsAppChat(international, app);
  } on PlatformException catch (error) {
    message(
      error.code == 'NO_PERMISSION'
          ? 'Contacts access is unavailable. Please enable it in Settings.'
          : 'Could not open WhatsApp. Please try again.',
    );
  }
}

Future<String?> _chooseApp(BuildContext context, List<Map> apps) async {
  if (apps.length == 1) return apps.single['package'] as String;
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Choose WhatsApp'),
      children: [
        for (final app in apps)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, app['package'] as String),
            child: Text(app['label'] as String),
          ),
      ],
    ),
  );
}

class _CountryCodeDialog extends StatefulWidget {
  const _CountryCodeDialog();
  @override
  State<_CountryCodeDialog> createState() => _CountryCodeDialogState();
}

class _CountryCodeDialogState extends State<_CountryCodeDialog> {
  final controller = TextEditingController(text: '+');
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Include country code'),
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Full international number',
        hintText: '+ country code and number',
        errorText: error,
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(
        onPressed: () {
          final value = controller.text.replaceAll(RegExp(r'[\s().-]'), '');
          if (!RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(value)) {
            setState(() => error = 'Enter +, country code, and phone number');
          } else {
            Navigator.pop(context, value);
          }
        },
        child: const Text('Open chat'),
      ),
    ],
  );
}

class WhatsAppCallIcon extends StatelessWidget {
  const WhatsAppCallIcon({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 32,
    height: 32,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: Size(32, 32), painter: _WhatsAppOutline()),
        Icon(Icons.call, size: 18, color: Colors.white),
      ],
    ),
  );
}

class _WhatsAppOutline extends CustomPainter {
  const _WhatsAppOutline();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(4, 28)
      ..lineTo(6, 21)
      ..cubicTo(0, 11, 7, 3, 16, 3)
      ..cubicTo(24, 3, 29, 9, 29, 16)
      ..cubicTo(29, 26, 19, 31, 11, 26)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WhatsAppOutline oldDelegate) => false;
}
