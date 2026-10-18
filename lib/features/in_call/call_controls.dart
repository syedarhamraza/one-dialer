import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';

/// A ColorOS 17 call-control body, a circle or (with [radius]) a squircle-ended key: frosted (the backdrop blurred behind it), milky, glowing up
/// from every edge (least along the top), with a lip along the top edge and a fainter one below. Needs a [BackdropGroup] above it. The glass package supplies the press: it squeezes, stretches toward
/// the finger and glows, with no glass surface (`GlassButtonStyle.transparent`).
/// Taps still belong to [child] (its IconButton or key detector); the glass button only reads
/// raw pointer events for the effect. A circle, or a stadium when [radius] is given.
class CallBody extends StatelessWidget {
  const CallBody({super.key, this.radius, required this.child});
  final double? radius;
  final Widget child;

  static void _taps() {}

  @override
  Widget build(BuildContext context) => GlassButton.custom(
    style: GlassButtonStyle.transparent,
    onTap: _taps,
    excludeFromSemantics: true,
    canRequestFocus: false,
    shape: radius == null ? const LiquidOval() : LiquidRoundedSuperellipse(borderRadius: radius!),
    child: ClipPath(
      clipper: _BodyClip(radius),
      // Frosted like ColorOS: what's behind is blurred away. Grouped, so all the controls under
      // one BackdropGroup share a single backdrop read instead of a blur layer each.
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: CustomPaint(painter: _TintedBody(radius), child: child),
      ),
    ),
  );
}

/// The milky wash, edge glow and lips drawn over each control's frosted blur.
class _TintedBody extends CustomPainter {
  const _TintedBody(this.radius);
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = bodyPath(rect, radius);
    // An even milky wash over the blur, a little lighter toward the bottom.
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33FFFFFF), Color(0x2BFFFFFF), Color(0x3DFFFFFF)],
          stops: [0, .5, 1],
        ).createShader(rect),
    );
    // The ColorOS glow: a soft light hugging every edge, shallow so the centre stays clear, and
    // weaker along the top. A blurred stroke clipped to the shape keeps it inside.
    canvas
      ..save()
      ..clipPath(shape)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x0DFFFFFF), Color(0x24FFFFFF), Color(0x33FFFFFF)],
            stops: [0, .5, 1],
          ).createShader(rect),
      )
      ..restore();
    // A brighter glow right on the border, strongest along the bottom.
    canvas
      ..save()
      ..clipPath(shape)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Top a little softer, the sides softer still, the bottom brightest.
            colors: [Color(0x2BFFFFFF), Color(0x1FFFFFFF), Color(0x1FFFFFFF), Color(0x5CFFFFFF)],
            stops: [0, .25, .75, 1],
          ).createShader(rect),
      )
      ..restore();
    // The 3D lip: clearer along the top edge, fainter along the bottom.
    canvas.drawPath(
      bodyPath(rect.deflate(.5), radius == null ? null : radius! - .5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x4DFFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x29FFFFFF)],
          stops: [0, .3, .7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TintedBody oldDelegate) => oldDelegate.radius != radius;
}

/// A circle, or a superellipse whose ends are ColorOS's soft oval rather than a true semicircle.
Path bodyPath(Rect rect, double? radius) => radius == null
    ? (Path()..addOval(rect))
    : (Path()..addRSuperellipse(RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius))));

class _BodyClip extends CustomClipper<Path> {
  const _BodyClip(this.radius);
  final double? radius;

  @override
  Path getClip(Size size) => bodyPath(Offset.zero & size, radius);

  @override
  bool shouldReclip(_BodyClip oldClipper) => oldClipper.radius != radius;
}

/// A [GlassSpring] as a curve, so implicit animations can move like the glass package.
class GlassSpringCurve extends Curve {
  GlassSpringCurve(SpringDescription spring, Duration duration)
    : _sim = SpringSimulation(spring, 0, 1, 0),
      _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
  final SpringSimulation _sim;
  final double _seconds;

  @override
  double transformInternal(double t) => _sim.x(t * _seconds);
}

/// The bouncy glass spring for on/off state changes, and how long it takes to settle.
const springSettle = Duration(milliseconds: 700);
final bouncySpring = GlassSpringCurve(GlassSpring.bouncy(), springSettle);

/// An unavailable action: just an outline, so it reads as "not yet" rather than broken.
const _outlined = BoxDecoration(
  shape: BoxShape.circle,
  border: Border.fromBorderSide(BorderSide(color: Color(0x2EFFFFFF))),
);

/// Shared round action for the call controls and the persistent bottom row. Turning it on
/// grows a white fill out from the icon; unavailable actions show as an outline.
class CallAction extends StatelessWidget {
  const CallAction({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    required this.onPressed,
    this.size = 60,
    this.glyph,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;
  final double size;

  /// Draws the icon instead of [icon], for glyphs Material lacks (the 12-dot dial pad).
  final Widget Function(Color? color)? glyph;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final fast = still ? Duration.zero : const Duration(milliseconds: 180);
    final enabled = onPressed != null;
    final foreground = active ? const Color(0xFF111418) : (enabled ? Colors.white : const Color(0x73FFFFFF));
    Widget circle(VoidCallback? onPressed) {
      final body = SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!enabled) const DecoratedBox(decoration: _outlined),
            AnimatedScale(
              scale: active ? 1 : 0,
              duration: still ? Duration.zero : (active ? springSettle : const Duration(milliseconds: 220)),
              curve: active ? bouncySpring : Curves.easeInCubic,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xEBFFFFFF),
                  boxShadow: [BoxShadow(color: Color(0x40FFFFFF), blurRadius: 18)],
                ),
              ),
            ),
            IconButton(
              tooltip: label,
              isSelected: active,
              iconSize: size * .42,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shape: const CircleBorder(),
                side: BorderSide.none,
                elevation: 0,
              ),
              onPressed: onPressed,
              icon: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: foreground),
                duration: fast,
                builder: (context, color, _) => AnimatedSwitcher(
                  duration: fast,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: Tween(begin: .6, end: 1.0).animate(animation), child: child),
                  ),
                  child: glyph?.call(color) ?? Icon(icon, key: ValueKey(icon), color: color),
                ),
              ),
            ),
          ],
        ),
      );
      return enabled ? CallBody(child: body) : body;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle(onPressed),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: AnimatedSwitcher(
            duration: fast,
            // Labels hang just under the circle, level with End's.
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
            child: Text(
              label,
              key: ValueKey(label),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
                color: enabled ? const Color(0xC7FFFFFF) : const Color(0x66FFFFFF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String audioRouteLabel(AudioRoute route) => switch (route) {
  AudioRoute.earpiece => 'Phone',
  AudioRoute.speaker => 'Speaker',
  AudioRoute.bluetooth => 'Bluetooth',
  AudioRoute.wiredHeadset => 'Wired headset',
};

Future<void> chooseCallAudioRoute(BuildContext context, AudioInfo audio) async {
  final route = await OneUIFloatingModal.show<AudioRoute>(
    context: context,
    builder: (context) => Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Audio output', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          for (final route in audio.supportedRoutes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (route) {
                AudioRoute.earpiece => Icons.phone_in_talk_rounded,
                AudioRoute.speaker => Icons.volume_up_rounded,
                AudioRoute.bluetooth => Icons.bluetooth_audio_rounded,
                AudioRoute.wiredHeadset => Icons.headset_rounded,
              }),
              title: Text(audioRouteLabel(route)),
              trailing: route == audio.route ? const Icon(Icons.check_rounded, color: Color(0xFFB5E8D1)) : null,
              onTap: () => Navigator.of(context).pop(route),
            ),
        ],
      ),
    ),
  );
  if (route != null && context.mounted) await TelecomBridge.instance.setAudioRoute(route);
}

/// Opens the call note over the call screen. Text saves as it's typed, so a note survives the
/// other side hanging up mid-sentence. Returns whether a note is left.
Future<bool> editCallNote(BuildContext context, String number, DateTime at) async {
  final initial = await DialerPrefs.instance.callNote(number, at) ?? '';
  if (!context.mounted) return initial.isNotEmpty;
  final text = await OneUIFloatingModal.show<String>(
    context: context,
    builder: (context) => _CallNoteSheet(number: number, at: at, initial: initial),
  );
  return (text ?? await DialerPrefs.instance.callNote(number, at) ?? '').trim().isNotEmpty;
}

class _CallNoteSheet extends StatefulWidget {
  const _CallNoteSheet({required this.number, required this.at, required this.initial});
  final String number;
  final DateTime at;
  final String initial;

  @override
  State<_CallNoteSheet> createState() => _CallNoteSheetState();
}

class _CallNoteSheetState extends State<_CallNoteSheet> {
  late final _controller = TextEditingController(text: widget.initial);
  Timer? _save;

  void _flush() {
    _save?.cancel();
    _save = null;
    DialerPrefs.instance.setCallNote(widget.number, widget.at, _controller.text);
  }

  @override
  void dispose() {
    if (_save != null) _flush();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Call note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                _flush();
                Navigator.of(context).pop(_controller.text);
              },
              child: const Text('Done'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Write something to remember from this call'),
          onChanged: (_) {
            _save?.cancel();
            _save = Timer(const Duration(milliseconds: 400), _flush);
          },
        ),
      ],
    ),
  );
}

/// ColorOS's dial pad glyph: twelve dots, three across and four down, sized like an icon.
class DialPadGlyph extends StatelessWidget {
  const DialPadGlyph({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final size = IconTheme.of(context).size ?? 24;
    return CustomPaint(size: Size.square(size), painter: _DialPadDots(color ?? IconTheme.of(context).color!));
  }
}

class _DialPadDots extends CustomPainter {
  const _DialPadDots(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.height / 4.6;
    final dot = gap * .3;
    final left = size.width / 2 - gap;
    final top = size.height / 2 - gap * 1.5;
    final paint = Paint()..color = color;
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawCircle(Offset(left + column * gap, top + row * gap), dot, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DialPadDots oldDelegate) => oldDelegate.color != color;
}
