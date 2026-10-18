import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/one_ui_floating_modal.dart';

/// Liquid glass shared by every call control. One layer refracts the caller's backdrop for all
/// the circles and keys inside it, so the shapes cost a single pass together.
class CallGlassLayer extends StatelessWidget {
  const CallGlassLayer({super.key, required this.child});
  final Widget child;

  /// Premium frosted glass: the package's native frost, tuned to its dark-material values.
  static const settings = LiquidGlassSettings(
    thickness: 10,
    blur: 8,
    frost: .6,
    frostOpacity: .85,
    frostClamp: -.45,
    frostWeight: .5,
    glassColor: Color.fromRGBO(255, 255, 255, 0.08),
    lightIntensity: .5,
    refractiveIndex: 1.15,
    saturation: 1.2,
    chromaticAberration: 0,
  );

  @override
  Widget build(BuildContext context) =>
      AdaptiveLiquidGlassLayer(settings: settings, quality: GlassQuality.premium, child: child);
}

/// A glass body inside [CallGlassLayer] with the package's press feel: it squeezes, stretches
/// toward the finger and glows. Taps still belong to [child] (its IconButton or key detector);
/// the glass button only reads raw pointer events for the effect.
class CallGlass extends StatelessWidget {
  const CallGlass({super.key, this.radius, required this.child});
  final double? radius;
  final Widget child;

  static void _taps() {}

  @override
  Widget build(BuildContext context) => GlassButton.custom(
    onTap: _taps,
    excludeFromSemantics: true,
    canRequestFocus: false,
    quality: GlassQuality.premium,
    shape: radius == null ? const LiquidOval() : LiquidRoundedRectangle(borderRadius: radius!),
    child: child,
  );
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
    this.menu,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;
  final double size;

  /// Wraps just the circle (not its label) in a menu, given a builder for the circle with
  /// the menu's own toggle as its tap.
  final Widget Function(Widget Function(VoidCallback toggle) circle)? menu;

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
              iconSize: size * .36,
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
                  child: Icon(icon, key: ValueKey(icon), color: color),
                ),
              ),
            ),
          ],
        ),
      );
      return enabled ? CallGlass(child: body) : body;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        menu == null ? circle(onPressed) : menu!(circle),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: AnimatedSwitcher(
            duration: fast,
            child: Text(
              label,
              key: ValueKey(label),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, height: 1.1, color: enabled ? Colors.white : const Color(0x73FFFFFF)),
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
