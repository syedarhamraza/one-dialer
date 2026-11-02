import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../l10n/l10n.dart';

/// A ColorOS 17 call-control body, a circle or (with [radius]) a squircle-ended key: frosted (the backdrop blurred behind it), milky, glowing up
/// from every edge (least along the top), with a lip along the top edge and a fainter one below. The glass package supplies the press: it squeezes, stretches toward
/// the finger and glows, with no glass surface (`GlassButtonStyle.transparent`).
/// Taps still belong to [child] (its IconButton or key detector); the glass button only reads
/// raw pointer events for the effect. A circle, or a stadium when [radius] is given.
class CallBody extends StatelessWidget {
  const CallBody({super.key, this.radius, this.pill = false, required this.child});
  final double? radius;

  /// Round ends (a stadium) instead of the keys' squircle ends; [radius] is ignored.
  final bool pill;
  final Widget child;

  static void _taps() {}

  @override
  Widget build(BuildContext context) => GlassButton.custom(
    style: GlassButtonStyle.transparent,
    onTap: _taps,
    excludeFromSemantics: true,
    canRequestFocus: false,
    // Below full call screen effects: no glass lighting on press, just the squeeze.
    glowColor: callFlat(context) ? Colors.transparent : null,
    ambientBaseLight: callFlat(context) ? 0 : null,
    shape: pill
        ? const LiquidRoundedRectangle(borderRadius: 999)
        : radius == null
        ? const LiquidOval()
        : LiquidRoundedSuperellipse(borderRadius: radius!),
    // No live backdrop blur: the call backdrop behind is already blurred, so a per-control blur
    // looked the same but re-read the backdrop for every key on every frame of the keypad morph.
    child: CallFrost(radius: pill ? double.infinity : radius, child: child),
  );
}

/// Settings › "Call screen effects" for the call screen below it (`InCallApp`): widgets that
/// read [callFlat] rebuild when it changes.
class CallEffects extends InheritedNotifier<OneUIEffectsController> {
  CallEffects({super.key, required super.child}) : super(notifier: OneUIEffectsController.instance);
}

/// Below full call screen effects: One UI's flat fills instead of the frosted artwork, and
/// flat coloured buttons with no glow, sheen or rim.
bool callFlat(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<CallEffects>();
  return OneUIEffectsController.instance.callLevel != 'full';
}

/// How strongly a glass body is drawn ([CallBodyArtwork.opacity]) and its 3D edges.
typedef GlassLook = ({double opacity, GlassEdges edges});

/// An edge glow style (Settings › "… edge glow"): classic is the original glass ([classicOpacity]
/// per control); soft is half the glass, like ColorOS 17's Phone, with 2x edges; bold brightens
/// them 3x and thickens them.
GlassLook glassLook(String style, {double classicOpacity = 1}) => switch (style) {
  'classic' => (opacity: classicOpacity, edges: GlassEdges.callScreen),
  'soft' => (opacity: .5, edges: const GlassEdges(strength: 2)),
  _ => (opacity: .5, edges: const GlassEdges(strength: 3, bottomLip: 3, lip: 2)),
};

/// A solid button's edges for [look]: the glass's edges at its opacity (the glass draws them
/// through it), and a little softer still, since over solid colour they read stronger. Null
/// with classic: the button keeps its own.
GlassEdges? litEdges(GlassLook look) {
  if (look.edges == GlassEdges.callScreen) return null;
  final scale = look.opacity * .7;
  return GlassEdges(
    strength: look.edges.strength * scale,
    bottomLip: look.edges.bottomLip * scale,
    lip: look.edges.lip,
  );
}

/// The call screen's glass look (Settings › "Call screen edge glow"); full effects only.
GlassLook callGlass(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<CallEffects>();
  return glassLook(OneUIEffectsController.instance.callGlassStyle);
}

/// [CallFrost]'s fills below full call screen effects.
const callFrostFill = Color(0x40FFFFFF);
const callSolidFill = Color(0xFF6E7278);

/// A frosted control's body: [CallBodyArtwork] at full call screen effects, One UI's flat
/// fill below that (translucent when reduced, solid when off), so resizing it (the keypad
/// morph) re-rasterizes nothing.
class CallFrost extends StatelessWidget {
  const CallFrost({super.key, required this.radius, required this.child});
  final double? radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!callFlat(context)) {
      final look = callGlass(context);
      return CallBodyArtwork(radius: radius, opacity: look.opacity, edges: look.edges, child: child);
    }
    // Light, like the frosted controls over the call's colours (the call screen is never dark):
    // a white wash when reduced; when off, a solid grey that keeps the white icons legible.
    final fill = OneUIEffectsController.instance.callLevel == 'off' ? callSolidFill : callFrostFill;
    final r = radius;
    final OutlinedBorder shape = r == null
        ? const CircleBorder()
        : r == double.infinity
        ? const StadiumBorder()
        : RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(r));
    return DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: shape),
      child: child,
    );
  }
}

/// The frosted backdrop stays live; only the static glow and rim are rasterized once.
/// A fixed-resolution image remains reusable while the glass press and keypad scale it.
/// The main app's keypad keys use it too, with their softer [glow] and [opacity].
class CallBodyArtwork extends StatefulWidget {
  const CallBodyArtwork({
    super.key,
    required this.radius,
    this.glow = 1,
    this.spread = 1,
    this.opacity = 1,
    this.edges = GlassEdges.callScreen,
    this.lipsOnly = false,
    required this.child,
  });
  final double? radius;

  final double glow;

  /// How far the edge glow reaches in (see [TintedCallBody.spread]).
  final double spread;

  /// How strongly the whole body (wash, glow and lips) is drawn.
  final double opacity;

  /// The 3D lips and the bottom glow (see [GlassEdges]).
  final GlassEdges edges;

  /// Only the 3D lips ([paintGlassLips]), for solid bodies with no milky wash (the green [LitButton]s).
  final bool lipsOnly;
  final Widget child;

  @override
  State<CallBodyArtwork> createState() => _CallBodyArtworkState();
}

class _CallBodyArtworkState extends State<CallBodyArtwork> {
  _CachedBodyPainter? _painter;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final light = context.palette.isLight;
    if (_painter == null ||
        _painter!.light != light ||
        _painter!.radius != widget.radius ||
        _painter!.ratio != ratio ||
        _painter!.glow != widget.glow ||
        _painter!.spread != widget.spread ||
        _painter!.opacity != widget.opacity ||
        _painter!.edges != widget.edges ||
        _painter!.lipsOnly != widget.lipsOnly) {
      _painter?.dispose();
      _painter = _CachedBodyPainter(
        widget.radius,
        ratio,
        widget.glow,
        widget.spread,
        widget.opacity,
        widget.edges,
        light,
        lipsOnly: widget.lipsOnly,
      );
    }
    return CustomPaint(painter: _painter, child: widget.child);
  }

  @override
  void dispose() {
    _painter?.dispose();
    super.dispose();
  }
}

class _CachedBodyPainter extends CustomPainter {
  _CachedBodyPainter(
    this.radius,
    this.ratio,
    this.glow,
    this.spread,
    this.opacity,
    this.edges,
    this.light, {
    this.lipsOnly = false,
  });
  final double? radius;
  final double ratio;
  final double glow;
  final double spread;
  final double opacity;
  final GlassEdges edges;
  final bool light;
  final bool lipsOnly;
  ui.Image? _image;
  Size? _size;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_image == null || _size != size) {
      final recorder = ui.PictureRecorder();
      final recording = Canvas(recorder)..scale(ratio);
      if (lipsOnly) {
        paintGlassLips(recording, Offset.zero & size, radius, edges);
      } else {
        TintedCallBody(radius, glow: glow, spread: spread, edges: edges, light: light).paint(recording, size);
      }
      final picture = recorder.endRecording();
      final image = picture.toImageSync((size.width * ratio).ceil(), (size.height * ratio).ceil());
      picture.dispose();
      _image?.dispose();
      _image = image;
      _size = size;
    }
    canvas.drawImageRect(
      _image!,
      Rect.fromLTWH(0, 0, size.width * ratio, size.height * ratio),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(0, 0, 0, opacity),
    );
  }

  void dispose() => _image?.dispose();

  @override
  bool shouldRepaint(_CachedBodyPainter oldDelegate) =>
      radius != oldDelegate.radius ||
      ratio != oldDelegate.ratio ||
      glow != oldDelegate.glow ||
      spread != oldDelegate.spread ||
      opacity != oldDelegate.opacity ||
      edges != oldDelegate.edges ||
      lipsOnly != oldDelegate.lipsOnly ||
      light != oldDelegate.light;
}

/// How strongly a [TintedCallBody] draws its 3D edges; the call screen's is the default.
@immutable
class GlassEdges {
  const GlassEdges({this.strength = 1, this.bottomLip = 1, this.lip = 1});

  static const callScreen = GlassEdges();

  /// The top lip and the glow along the bottom.
  final double strength;

  /// The fainter lip along the bottom.
  final double bottomLip;

  /// The lips' width, in logical pixels.
  final double lip;

  @override
  bool operator ==(Object other) =>
      other is GlassEdges && other.strength == strength && other.bottomLip == bottomLip && other.lip == lip;

  @override
  int get hashCode => Object.hash(strength, bottomLip, lip);
}

/// The milky wash, edge glow and lips drawn over each control's frosted blur.
class TintedCallBody extends CustomPainter {
  const TintedCallBody(
    this.radius, {
    this.glow = 1,
    this.spread = 1,
    this.edges = GlassEdges.callScreen,
    this.light = false,
  });
  final double? radius;

  /// Light mode: a denser white wash and a bright white rim (the press draws its shadow).
  final bool light;

  /// Strength of the edge glow and the brighter border glow (1 = the call screen's).
  final double glow;

  /// How far the soft edge glow reaches in from the edge (1 = the call screen's).
  final double spread;

  /// The 3D lips and the glow along the bottom.
  final GlassEdges edges;

  Color _g(int argb) {
    final c = Color(argb);
    return c.withValues(alpha: c.a * glow);
  }

  Color _e(Color c) => _scaled(c, edges.strength);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = bodyPath(rect, radius);
    // An even milky wash over the blur, a little lighter toward the bottom.
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: light
              ? const [Color(0xB8FFFFFF), Color(0xA8FFFFFF), Color(0xC2FFFFFF)]
              : const [Color(0x33FFFFFF), Color(0x2BFFFFFF), Color(0x3DFFFFFF)],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );
    if (light) {
      canvas.drawPath(
        bodyPath(rect.deflate(.4), radius == null ? null : radius! - .4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = const Color(0xE6FFFFFF),
      );
    }
    // The ColorOS glow: a soft light hugging every edge, shallow so the centre stays clear, and
    // weaker along the top. A blurred stroke clipped to the shape keeps it inside.
    canvas
      ..save()
      ..clipPath(shape)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.5 * spread
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * spread)
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_g(0x10FFFFFF), _g(0x2BFFFFFF), _e(_g(0x3DFFFFFF))],
            stops: const [0, .5, 1],
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
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Top a little softer, the sides softer still, the bottom brightest.
            colors: [_g(0x33FFFFFF), _g(0x26FFFFFF), _g(0x26FFFFFF), _e(_g(0x6EFFFFFF))],
            stops: const [0, .25, .75, 1],
          ).createShader(rect),
      )
      ..restore();
    paintGlassLips(canvas, rect, radius, edges);
  }

  @override
  bool shouldRepaint(TintedCallBody oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.glow != glow ||
      oldDelegate.spread != spread ||
      oldDelegate.edges != edges ||
      oldDelegate.light != light;
}

/// The 3D lips of a [TintedCallBody], also drawn on their own ([CallBodyArtwork.lipsOnly]): clearer along the top edge, fainter along the bottom, and faded out toward the
/// sides so they don't wrap round the rounded ends.
void paintGlassLips(Canvas canvas, Rect rect, double? radius, GlassEdges edges) {
  final lip = edges.lip;
  canvas
    ..saveLayer(rect, Paint())
    ..drawPath(
      bodyPath(rect.deflate(lip / 2), radius == null ? null : radius - lip / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lip
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _scaled(const Color(0x3BFFFFFF), edges.strength),
            const Color(0x00FFFFFF),
            const Color(0x00FFFFFF),
            _scaled(const Color(0x1FFFFFFF), edges.bottomLip),
          ],
          stops: const [0, .3, .7, 1],
        ).createShader(rect),
    )
    ..drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
          stops: [.12, .32, .68, .88],
        ).createShader(rect),
    )
    ..restore();
}

Color _scaled(Color c, double by) => c.withValues(alpha: (c.a * by).clamp(0.0, 1.0));

/// A circle, a superellipse whose ends are ColorOS's soft oval rather than a true semicircle, or
/// (an infinite [radius]) a stadium with round ends.
Path bodyPath(Rect rect, double? radius) => radius == null
    ? (Path()..addOval(rect))
    : radius.isInfinite
    ? (Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2))))
    : (Path()..addRSuperellipse(RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius))));

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

/// The lit fill of an active action: the 1-button Answer ball's white.
const _lit = Color(0xFFF2F2F4);

/// Shared round action for the call controls and the persistent bottom row. Turning it on
/// grows a lit white fill out from the icon; unavailable actions keep the frosted body with a
/// greyed icon.
class CallAction extends StatelessWidget {
  const CallAction({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    required this.onPressed,
    this.size = 60,
    this.glyph,
    this.circleKey,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;
  final double size;

  /// Draws the icon instead of [icon], for glyphs Material lacks (the 10-dot dial pad).
  final Widget Function(Color? color)? glyph;

  /// Marks the circle, so a menu opened from it can anchor there.
  final Key? circleKey;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final fast = still ? Duration.zero : const Duration(milliseconds: 180);
    final enabled = onPressed != null;
    final foreground = active ? const Color(0xFF111418) : (enabled ? Colors.white : const Color(0x59FFFFFF));
    Widget circle(VoidCallback? onPressed) {
      final body = SizedBox.square(
        key: circleKey,
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: active ? 1 : 0,
              duration: still ? Duration.zero : (active ? springSettle : const Duration(milliseconds: 220)),
              curve: active ? bouncySpring : Curves.easeInCubic,
              child: Container(
                // The 1-button Answer ball's glass finish; a plain fill below full call effects.
                decoration: glassBody(_lit, const CircleBorder(), flat: callFlat(context)),
                foregroundDecoration: callGlassGlow(context, const CircleBorder()),
              ),
            ),
            // The label under the circle is visible; a tooltip on long press would only repeat it.
            Semantics(
              label: label,
              child: IconButton(
                isSelected: active,
                iconSize: size * .5,
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
            ),
          ],
        ),
      );
      // Unavailable: the same frosted body, without the glass press.
      return enabled ? CallBody(child: body) : CallFrost(radius: null, child: body);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle(onPressed),
        const SizedBox(height: 6),
        SizedBox(
          // Room for a two-line label, no more, so the rows sit close as on ColorOS.
          height: 32,
          child: ExcludeSemantics(
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
                  color: enabled ? const Color(0xC7FFFFFF) : const Color(0x59FFFFFF),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String audioRouteLabel(AppLocalizations l10n, AudioRoute route) => switch (route) {
  AudioRoute.earpiece => l10n.audioPhone,
  AudioRoute.speaker => l10n.speaker,
  AudioRoute.bluetooth => 'Bluetooth',
  AudioRoute.wiredHeadset => l10n.wiredHeadset,
};

IconData audioRouteIcon(AudioRoute route) => switch (route) {
  AudioRoute.earpiece => Icons.phone_in_talk_rounded,
  AudioRoute.speaker => Icons.volume_up_rounded,
  AudioRoute.bluetooth => Icons.bluetooth_audio_rounded,
  AudioRoute.wiredHeadset => Icons.headset_rounded,
};

/// The app's floating menu over the Speaker button, the current route marked like a choice row's.
Future<void> chooseCallAudioRoute(BuildContext context, AudioInfo audio, GlobalKey anchor) => OneUIFloatingMenu.show(
  context: context,
  anchorKey: anchor,
  light: true,
  scale: 1.15,
  width: 250,
  items: [
    for (final route in audio.supportedRoutes)
      if (route == AudioRoute.bluetooth && audio.bluetoothDevices.isNotEmpty)
        // One row per device, so a watch and earbuds can be told apart.
        for (final (i, device) in audio.bluetoothDevices.indexed)
          OneUIFloatingMenuItem(
            label: audio.bluetoothLabel(i),
            icon: route == audio.route && device.id == audio.activeBluetooth
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            onTap: () => TelecomBridge.instance.setBluetoothDevice(device.id),
          )
      else
        OneUIFloatingMenuItem(
          label: audioRouteLabel(context.l10n, route),
          icon: route == audio.route ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
          onTap: () => TelecomBridge.instance.setAudioRoute(route),
        ),
  ],
);

/// Opens the call note over the call screen. Text saves as it's typed, so a note survives the
/// other side hanging up mid-sentence. Returns whether a note is left. [light] is the call
/// screen's look: a flat white card like its menus.
Future<bool> editCallNote(BuildContext context, String number, DateTime at, {bool light = false}) async {
  final initial = await DialerPrefs.instance.callNote(number, at) ?? '';
  if (!context.mounted) return initial.isNotEmpty;
  final text = light
      ? await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (context) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
              child: ClipRSuperellipse(
                borderRadius: const BorderRadius.all(Radius.circular(34)),
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: _CallNoteSheet(number: number, at: at, initial: initial, light: true),
                  ),
                ),
              ),
            ),
          ),
        )
      : await OneUIFloatingModal.show<String>(
          context: context,
          builder: (context) => _CallNoteSheet(number: number, at: at, initial: initial),
        );
  return (text ?? await DialerPrefs.instance.callNote(number, at) ?? '').trim().isNotEmpty;
}

class _CallNoteSheet extends StatefulWidget {
  const _CallNoteSheet({required this.number, required this.at, required this.initial, this.light = false});
  final String number;
  final DateTime at;
  final String initial;
  final bool light;

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

  void _delete() {
    _controller.clear();
    _flush(); // Blank removes the note.
    Navigator.of(context).pop('');
  }

  void _done() {
    _flush();
    Navigator.of(context).pop(_controller.text);
  }

  void _changed(String _) {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 400), _flush);
  }

  static const _ink = Color(0xFF111418);

  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: widget.light ? _card() : _sheet());

  Widget _sheet() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(context.l10n.callNote, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          if (widget.initial.isNotEmpty)
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: OneUITheme.accentRed),
              child: Text(context.l10n.delete),
            ),
          TextButton(onPressed: _done, child: Text(context.l10n.done)),
        ],
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: context.l10n.callNoteHint),
        onChanged: _changed,
      ),
    ],
  );

  // The call screen's: a ColorOS dialog on the menus' white card, centred title, a grey field and
  // pill buttons along the bottom.
  Widget _card() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.l10n.callNote,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: _ink),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: _ink, fontSize: 16, height: 1.35),
        cursorColor: answerGreen,
        decoration: InputDecoration(
          hintText: context.l10n.callNoteHint,
          hintStyle: const TextStyle(color: Color(0x80111418)),
          filled: true,
          fillColor: Color(0x0F000000),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        onChanged: _changed,
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          if (widget.initial.isNotEmpty) ...[
            Expanded(child: _pill(context.l10n.delete, const Color(0x0F000000), OneUITheme.accentRed, _delete)),
            const SizedBox(width: 10),
          ],
          Expanded(child: _pill(context.l10n.done, answerGreen, Colors.white, _done)),
        ],
      ),
    ],
  );

  Widget _pill(String label, Color background, Color foreground, VoidCallback onPressed) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      minimumSize: const Size.fromHeight(48),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  );
}

/// The dial pad glyph: ten dots, three rows of three and one under the middle (the 0 key), sized like an icon.
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
        if (row == 3 && column != 1) continue;
        canvas.drawCircle(Offset(left + column * gap, top + row * gap), dot, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DialPadDots oldDelegate) => oldDelegate.color != color;
}

/// End's red, shared by the End pill, Decline and the Answer flight's landing.
const endRed = Color(0xFFD2463A);

/// Answer's green, shared by Answer, the start of the Answer flight and the keypad's call button.
const answerGreen = Color(0xFF2FAE52);

/// ColorOS 17's solid buttons (End, Decline, Answer), lit from below like the frosted ones: a
/// shade deeper at the top, lighter toward the bottom, a light rim and a soft drop glow in their
/// own colour. Pair with [solidGlow] as the foreground.
ShapeDecoration solidBody(Color color, OutlinedBorder shape, {double glow = .3, double blur = 22, bool flat = false}) =>
    flat
    ? ShapeDecoration(color: color, shape: shape)
    : ShapeDecoration(
        shape: shape.copyWith(side: const BorderSide(color: Color(0x2EFFFFFF), width: .8)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.black, .1)!, color, Color.lerp(color, Colors.white, .14)!],
          stops: const [0, .55, 1],
        ),
        shadows: [
          BoxShadow(
            color: color.withValues(alpha: glow),
            blurRadius: blur,
            offset: const Offset(0, 6),
          ),
        ],
      );

/// The glow rising from a solid button's bottom edge; nothing when [flat].
/// [strength] scales it like [GlassEdges.strength].
ShapeDecoration solidGlow(OutlinedBorder shape, {bool flat = false, double strength = 1}) => flat
    ? ShapeDecoration(shape: shape)
    : ShapeDecoration(
        shape: shape.copyWith(side: BorderSide.none),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x00FFFFFF), const Color(0x00FFFFFF), _scaled(const Color(0x3DFFFFFF), strength)],
          stops: const [0, .5, 1],
        ),
      );

/// The call buttons (End, Answer, Decline) as glass: [solidBody] a touch see-through, so the
/// backdrop tints it, and without its even rim ([glassGlow] draws a lit one). Pair with [glassGlow].
ShapeDecoration glassBody(Color color, OutlinedBorder shape, {double glow = .3, double blur = 22, bool flat = false}) {
  if (flat) return ShapeDecoration(color: color, shape: shape);
  final body = solidBody(color.withValues(alpha: .86), shape, glow: glow, blur: blur);
  return ShapeDecoration(
    shape: shape.copyWith(side: BorderSide.none),
    gradient: body.gradient,
    shadows: body.shadows,
  );
}

/// [solidGlow] plus a glass sheen over the top and a rim that catches the light at the top
/// edge and fades down the sides.
/// [edges] scales the sheen and rim ([GlassEdges.strength]) and thickens the rim ([GlassEdges.lip]).
Decoration glassGlow(OutlinedBorder shape, {bool flat = false, GlassEdges edges = GlassEdges.callScreen}) =>
    flat ? ShapeDecoration(shape: shape) : _GlassGlow(shape.copyWith(side: BorderSide.none), edges);

/// [glassGlow] in the call screen's effects and edge glow style.
Decoration callGlassGlow(BuildContext context, OutlinedBorder shape) =>
    glassGlow(shape, flat: callFlat(context), edges: litEdges(callGlass(context)) ?? GlassEdges.callScreen);

class _GlassGlow extends Decoration {
  const _GlassGlow(this.shape, this.edges);
  final OutlinedBorder shape;
  final GlassEdges edges;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GlassGlowPainter(shape, edges);
}

class _GlassGlowPainter extends BoxPainter {
  _GlassGlowPainter(this.shape, GlassEdges edges)
    : rim = 1.2 * edges.lip,
      _sheen = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          for (final c in const [0x47FFFFFF, 0x12FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x3DFFFFFF])
            _scaled(Color(c), edges.strength),
        ],
        stops: const [0, .28, .46, .55, 1],
      ),
      _rim = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          for (final c in const [0x80FFFFFF, 0x14FFFFFF, 0x00FFFFFF, 0x29FFFFFF]) _scaled(Color(c), edges.strength),
        ],
        stops: const [0, .3, .65, 1],
      );
  final OutlinedBorder shape;
  final double rim;
  final LinearGradient _sheen;
  final LinearGradient _rim;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final path = shape.getOuterPath(rect);
    canvas.drawPath(path, Paint()..shader = _sheen.createShader(rect));
    // Inset half the stroke so the rim sits inside the edge.
    canvas.drawPath(
      shape.getOuterPath(rect.deflate(rim / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim
        ..shader = _rim.createShader(rect),
    );
  }
}
