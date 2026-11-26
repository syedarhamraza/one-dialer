import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/telecom/call_info.dart';
import '../core/telecom/telecom_bridge.dart';
import '../l10n/l10n.dart';
import 'one_ui_floating_menu.dart';
import 'one_ui_toast.dart';
import 'place_call.dart';

/// One way to video call someone: the carrier's own video call (ViLTE/ViNR), an app's video row on
/// their contact (WhatsApp, Telegram, Meet...), or Meet by number.
class VideoOption {
  const VideoOption({required this.label, this.dataId, this.mimeType}) : carrier = false;
  const VideoOption.carrier() : label = '', dataId = null, mimeType = null, carrier = true;

  /// The app's name; the carrier option's is [AppLocalizations.carrierVideo].
  final String label;
  final bool carrier;

  /// The contact's app row to open; null for Meet by number.
  final int? dataId;
  final String? mimeType;
}

const _meetVideo = 'vnd.android.cursor.item/com.google.android.apps.tachyon.phone.meet';

/// The Video menu's options: carrier video first when the SIM (or the call) can ([carrier]), the
/// contact's app rows ([TelecomBridge.getVideoApps]), then Meet by number when Meet is installed
/// ([meetByNumber]) and the contact has no Meet row of its own.
List<VideoOption> videoOptionsFrom(
  List<Map<Object?, Object?>> apps, {
  required bool meetByNumber,
  bool carrier = false,
}) => [
  if (carrier) const VideoOption.carrier(),
  for (final a in apps)
    VideoOption(label: a['label']! as String, dataId: a['dataId']! as int, mimeType: a['mimeType']! as String),
  if (meetByNumber && !apps.any((a) => a['mimeType'] == _meetVideo)) const VideoOption(label: 'Meet'),
];

/// The ways to video call [number]: carrier video, its contact's apps, and Meet by number.
/// [carrier] null asks the SIMs (a new call); the call screen passes whether its call can switch.
Future<List<VideoOption>> videoOptions(String number, {bool? carrier}) async {
  final bridge = TelecomBridge.instance;
  final contactId = number.isEmpty ? null : ContactsRepository.instance.contactFor(number)?.id;
  final (apps, meet, sims) = await (
    contactId == null ? Future.value(const <Map<Object?, Object?>>[]) : bridge.getVideoApps(contactId),
    number.isEmpty ? Future.value(false) : bridge.canMeetCall(),
    carrier == null && number.isNotEmpty ? bridge.quickSims() : Future.value(const <SimCard>[]),
  ).wait;
  return videoOptionsFrom(apps, meetByNumber: meet, carrier: carrier ?? sims.any((s) => s.video));
}

/// Asks for the camera (carrier video calls only); false when it isn't allowed, with a toast.
Future<bool> cameraAllowed(BuildContext context) async {
  if (await Permission.camera.request().isGranted) return true;
  if (context.mounted) OneUIToast.show(context, context.l10n.cameraNeeded);
  return false;
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
  Future<bool> Function()? onCarrier,
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
          OneUIFloatingMenuItem(
            label: o.carrier ? context.l10n.carrierVideo : o.label,
            icon: o.carrier ? Icons.sim_card_rounded : Icons.videocam_rounded,
            onTap: () => picked.complete(o),
          ),
      ],
    );
    // The menu calls the item's onTap right after it closes, so a pick has landed by now.
    if (!picked.isCompleted) return false;
    pick = await picked.future;
  }
  if (!context.mounted) return false;
  if (pick.carrier) {
    return onCarrier != null
        ? onCarrier()
        : _carrierCall(context, number, anchorKey: anchorKey, anchorContext: anchorContext);
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

/// A new carrier video call, on the one SIM that can make it (else the usual SIM choice).
Future<bool> _carrierCall(
  BuildContext context,
  String number, {
  GlobalKey? anchorKey,
  BuildContext? anchorContext,
}) async {
  if (!await cameraAllowed(context)) return false;
  final video = (await TelecomBridge.instance.quickSims()).where((s) => s.video).toList();
  if (!context.mounted) return false;
  return placeCall(
    context,
    number,
    simId: video.length == 1 ? video.single.id : null,
    anchorKey: anchorKey,
    anchorContext: anchorContext,
    video: true,
  );
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
