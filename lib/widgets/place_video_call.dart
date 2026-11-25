import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/telecom/telecom_bridge.dart';
import '../l10n/l10n.dart';
import 'one_ui_floating_menu.dart';
import 'one_ui_toast.dart';

/// One way to video call someone: an app's video row on their contact (WhatsApp, Telegram,
/// Meet...), or Meet by number.
class VideoOption {
  const VideoOption({required this.label, this.dataId, this.mimeType});

  final String label;

  /// The contact's app row to open; null for Meet by number.
  final int? dataId;
  final String? mimeType;
}

const _meetVideo = 'vnd.android.cursor.item/com.google.android.apps.tachyon.phone.meet';

/// The Video menu's options: the contact's app rows ([TelecomBridge.getVideoApps]), then Meet by
/// number when Meet is installed ([meetByNumber]) and the contact has no Meet row of its own.
List<VideoOption> videoOptionsFrom(List<Map<Object?, Object?>> apps, {required bool meetByNumber}) => [
  for (final a in apps)
    VideoOption(label: a['label']! as String, dataId: a['dataId']! as int, mimeType: a['mimeType']! as String),
  if (meetByNumber && !apps.any((a) => a['mimeType'] == _meetVideo)) const VideoOption(label: 'Meet'),
];

/// The ways to video call [number]: its contact's apps, and Meet by number.
Future<List<VideoOption>> videoOptions(String number) async {
  final bridge = TelecomBridge.instance;
  final contactId = number.isEmpty ? null : ContactsRepository.instance.contactFor(number)?.id;
  final (apps, meet) = await (
    contactId == null ? Future.value(const <Map<Object?, Object?>>[]) : bridge.getVideoApps(contactId),
    number.isEmpty ? Future.value(false) : bridge.canMeetCall(),
  ).wait;
  return videoOptionsFrom(apps, meetByNumber: meet);
}

/// Video calls [number] the way the user picks from [options]: straight through when there's one,
/// else our floating menu from [anchorKey]'s control (or [anchorContext]'s). False when nothing
/// opened: the menu was dismissed, or the app couldn't open (a toast says so).
Future<bool> placeVideoCall(
  BuildContext context,
  String number,
  List<VideoOption> options, {
  GlobalKey? anchorKey,
  BuildContext? anchorContext,
  double scale = 1,
}) async {
  if (options.isEmpty) return false;
  var pick = options.first;
  if (options.length > 1) {
    final picked = Completer<VideoOption>();
    await OneUIFloatingMenu.show(
      context: context,
      anchorKey: anchorKey,
      anchorContext: anchorContext,
      centered: true,
      fallbackBottom: 120,
      width: 220,
      scale: scale,
      items: [
        for (final o in options)
          OneUIFloatingMenuItem(label: o.label, icon: Icons.videocam_rounded, onTap: () => picked.complete(o)),
      ],
    );
    // The menu calls the item's onTap right after it closes, so a pick has landed by now.
    if (!picked.isCompleted) return false;
    pick = await picked.future;
  }
  final bridge = TelecomBridge.instance;
  try {
    if (pick.dataId case final id?) {
      await bridge.openContactData(id, pick.mimeType!);
    } else if (!await bridge.meetCall(number)) {
      throw PlatformException(code: 'NO_APP');
    }
    return true;
  } on PlatformException {
    if (context.mounted) OneUIToast.show(context, context.l10n.couldNotOpenApp);
    return false;
  }
}

/// The call details page's Video tile body: loads [number]'s options, greyed out while there are none.
class VideoTileLoader extends StatefulWidget {
  const VideoTileLoader({super.key, required this.number, required this.builder});

  final String number;

  /// Builds the tile; the tap is null while there's no way to video call.
  final Widget Function(BuildContext context, VoidCallback? onTap) builder;

  @override
  State<VideoTileLoader> createState() => _VideoTileLoaderState();
}

class _VideoTileLoaderState extends State<VideoTileLoader> {
  List<VideoOption> _options = const [];

  @override
  void initState() {
    super.initState();
    videoOptions(widget.number).then((o) {
      if (mounted) setState(() => _options = o);
    }, onError: (Object _) {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _options.isEmpty ? null : () => placeVideoCall(context, widget.number, _options, anchorContext: context),
  );
}
