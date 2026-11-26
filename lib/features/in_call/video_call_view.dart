import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../widgets/squircle.dart';
import 'call_controls.dart';
import 'call_screen_widgets.dart' show callerName;

/// Whether [call]'s carrier video shows: placing it or live, not ringing (the camera waits for
/// Answer) or ended.
bool showsVideo(CallInfo call) =>
    call.isVideo &&
    switch (call.state) {
      CallState.dialing || CallState.connecting || CallState.active || CallState.holding => true,
      _ => false,
    };

/// A carrier video call's picture: the other side, filling the screen under the header and
/// controls. Android's IMS stack draws it into a texture of this engine (`VideoCalls.kt`).
class VideoCallView extends StatefulWidget {
  const VideoCallView({super.key, required this.call});

  final CallInfo call;

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  (int, int)? _textures;

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.videoTextures(widget.call.id).then((t) {
      if (mounted) setState(() => _textures = t);
    }, onError: (Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final t = _textures;
    final peer = call.peerSize;
    // Only we send (`tx`) or it's paused: there's no picture of theirs to show.
    final theirs = t != null && !peer.isEmpty && (call.video == 'bidirectional' || call.video == 'rx');
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (theirs)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: peer.width,
              height: peer.height,
              child: Texture(textureId: t.$1),
            ),
          ),
        // Shade at the top and bottom, so the caller's name and the controls stay readable.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0xB3000000)],
                stops: [0, .28, .55, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Our camera's preview, a rounded tile above the controls. It asks for the same textures as
/// [VideoCallView] (made once per call) and shows the second.
class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key, required this.call});

  final CallInfo call;

  static const _width = 104.0;

  /// The camera's frame size, as it arrives (portrait until the camera says).
  static Size _frame(CallInfo call) => call.previewSize.isEmpty ? const Size(480, 640) : call.previewSize;

  /// The camera's frame stood upright. The texture turns the frames by the sensor angle itself
  /// (as AOSP's TextureView), so only the shape swaps, as AOSP swaps the capabilities in portrait.
  @visibleForTesting
  static Size upright(CallInfo call) {
    final p = _frame(call);
    return (call.cameraRotation % 180 == 90) ? p.flipped : p;
  }

  /// The tile's height: our camera's upright shape at [_width].
  static double heightFor(CallInfo call) {
    final p = upright(call);
    return _width * p.height / p.width;
  }

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  int? _texture;

  /// Flipping: the old camera's last frames would show turned for the new one, so the tile
  /// fades out until the new camera's frames have arrived.
  bool _flipping = false;
  Timer? _flip;

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.frontCamera == widget.call.frontCamera) return;
    _flipping = true;
    _flip?.cancel();
    _flip = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _flipping = false);
    });
  }

  @override
  void dispose() {
    _flip?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.videoTextures(widget.call.id).then((t) {
      if (mounted) setState(() => _texture = t?.$2);
    }, onError: (Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final t = _texture;
    final preview = VideoPreview.upright(widget.call);
    return SizedBox(
      width: VideoPreview._width,
      height: VideoPreview.heightFor(widget.call),
      child: t == null
          ? null
          : AnimatedOpacity(
              opacity: _flipping ? 0 : 1,
              // Out at once (the stale frames mustn't show), back in gently.
              duration: _flipping || MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: SquircleBorder(borderRadius: BorderRadius.circular(18))),
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: preview.width,
                    height: preview.height,
                    child: Texture(textureId: t),
                  ),
                ),
              ),
            ),
    );
  }
}

/// The other side asked to switch this voice call to video: Decline or Accept, in the held-call
/// card's look.
class VideoRequestCard extends StatelessWidget {
  const VideoRequestCard({super.key, required this.call, required this.onAccept});

  final CallInfo call;

  /// Accepting turns our camera on, so the call screen asks for it first.
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CallBody(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.videocam_rounded, size: 22, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    callerName(l10n, call),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(l10n.videoRequest, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            VideoPill(label: l10n.decline, onTap: () => TelecomBridge.instance.videoRespond(call.id, accept: false)),
            const SizedBox(width: 6),
            VideoPill(label: l10n.accept, color: answerGreen, onTap: onAccept),
          ],
        ),
      ),
    );
  }
}

/// A small stadium button of the call screen (the held card's Switch pill).
class VideoPill extends StatelessWidget {
  const VideoPill({super.key, required this.label, required this.onTap, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 6)],
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
    final tappable = GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: body);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: color == null
          // Frosted like SMS reply and the connected screen's buttons; the tap goes inside the body,
          // whose press would otherwise take it.
          ? CallBody(pill: true, child: tappable)
          : DecoratedBox(
              decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
              child: tappable,
            ),
    );
  }
}
