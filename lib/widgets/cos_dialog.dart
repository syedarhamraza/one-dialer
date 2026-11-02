import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart';
import '../l10n/l10n.dart';

/// One button of a [showCosActions] dialog.
typedef CosAction<T> = ({String label, T value, bool destructive});

/// ColorOS 17's alert: a rounded card floating above the bottom edge, the
/// message centred, and the choices as call-glass pills. Two choices sit side by side (Cancel first),
/// more stack. Back or a tap outside returns null. Choosers (SIM, numbers) are not alerts:
/// they keep their own sheets.
Future<T?> showCosActions<T>(
  BuildContext context, {
  String? title,
  required String message,
  required List<CosAction<T>> actions,
}) => showCosCard<T>(
  context,
  (context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Texts(title: title, message: message),
      const SizedBox(height: 24),
      if (actions.length == 2)
        Row(
          spacing: 12,
          children: [
            for (final a in actions)
              Expanded(
                child: CosPill(
                  label: a.label,
                  destructive: a.destructive,
                  onTap: () => Navigator.pop(context, a.value),
                ),
              ),
          ],
        )
      else
        Column(
          spacing: 10,
          children: [
            for (final a in actions)
              CosPill(label: a.label, destructive: a.destructive, onTap: () => Navigator.pop(context, a.value)),
          ],
        ),
    ],
  ),
);

/// A yes/no alert; true only when [confirmLabel] is tapped.
Future<bool> showCosConfirm(
  BuildContext context, {
  String? title,
  required String message,
  String? cancelLabel,
  required String confirmLabel,
  bool destructive = false,
}) async =>
    await showCosActions<bool>(
      context,
      title: title,
      message: message,
      actions: [
        (label: cancelLabel ?? context.l10n.cancel, value: false, destructive: false),
        (label: confirmLabel, value: true, destructive: destructive),
      ],
    ) ??
    false;

/// An alert with one text field; the trimmed text, or null when cancelled.
Future<String?> showCosTextInput(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hint = '',
  String? confirmLabel,
  TextInputType keyboardType = TextInputType.text,
  int? maxLength,
}) => showCosCard<String>(
  context,
  (_) => _TextInput(
    title: title,
    initialValue: initialValue,
    hint: hint,
    confirmLabel: confirmLabel ?? context.l10n.save,
    keyboardType: keyboardType,
    maxLength: maxLength,
  ),
);

/// Pops up like the floating menu: a spring scale from the bottom centre with a quick fade
/// in; out by shrinking back and fading.
final _spring = GlassSpringCurve(
  SpringDescription.withDampingRatio(mass: 1, stiffness: 320, ratio: .8),
  const Duration(milliseconds: 400),
);

/// Shows [content] in the alerts' card, for popups that aren't plain alerts (the contact QR).
Future<T?> showCosCard<T>(BuildContext context, WidgetBuilder content) {
  HapticFeedback.lightImpact();
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      // ColorOS 17 dims a light page only lightly; the card's shadow lifts it.
      barrierColor: context.palette.isLight ? const Color(0x4D000000) : Colors.black54,
      barrierLabel: context.l10n.dismiss,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (context, animation, _) => _Frame(animation: animation, child: content(context)),
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  /// Concentric with the pills: their 26 plus the card's 20 of padding.
  static const double _radius = 46;
  static const _shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(_radius)));

  /// ColorOS 17's alert card: light grey (white glass pills vanish on white) brightening toward
  /// the top, with a bright rim and a soft shadow; in dark, the card grey with a faint rim.
  static ShapeDecoration _card(OneUIPalette palette) => palette.isLight
      ? ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFFAFAFC), palette.page],
          ),
          shape: _shape.copyWith(side: const BorderSide(color: Colors.white)),
          shadows: OneUIPalette.lightMenuShadow,
        )
      : ShapeDecoration(
          color: palette.card,
          shape: _shape.copyWith(side: const BorderSide(color: Color(0x14FFFFFF), width: .8)),
        );

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Padding(
      // Rides above the keyboard while typing.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final v = still ? 1.0 : animation.value;
                final closing = animation.status == AnimationStatus.reverse;
                final scale = .9 + .1 * (closing ? Curves.easeIn.transform(v) : _spring.transform(v));
                final fade = Curves.easeOut.transform(closing ? v : (v / .28).clamp(0.0, 1.0));
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: Opacity(opacity: fade, child: child),
                );
              },
              // No blur of its own: a backdrop read under the open spring's scale costs tens of ms
              // a frame on Adreno. The glass is on the buttons.
              child: DecoratedBox(
                decoration: _card(context.palette),
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Texts extends StatelessWidget {
  const _Texts({this.title, required this.message});

  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (title != null) ...[
        Text(
          title!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
      ],
      Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: title == null ? 18 : 15,
          height: 1.4,
          color: title == null ? context.palette.textPrimary : context.palette.textSecondary,
        ),
      ),
    ],
  );
}

/// An alert button in the app's own style: a frosted call-glass pill like the header and
/// nav buttons (it carries the press); red text when it destroys something.
class CosPill extends StatelessWidget {
  const CosPill({super.key, required this.label, required this.onTap, this.destructive = false});

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => CallGlass(
    radius: 26,
    child: Material(
      type: MaterialType.transparency,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // Full width: the glass press hands its child loose constraints.
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: destructive ? OneUITheme.accentRed : context.palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Owns its controller, so it outlives the close animation.
class _TextInput extends StatefulWidget {
  const _TextInput({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.confirmLabel,
    required this.keyboardType,
    this.maxLength,
  });

  final String title;
  final String initialValue;
  final String hint;
  final String confirmLabel;
  final TextInputType keyboardType;
  final int? maxLength;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: context.palette.textPrimary,
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: ShapeDecoration(
          // White on the light card's grey.
          color: context.palette.isLight ? context.palette.card : context.palette.pill,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        ),
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          textCapitalization: widget.keyboardType == TextInputType.text
              ? TextCapitalization.sentences
              : TextCapitalization.none,
          onSubmitted: (_) => _submit(),
          style: TextStyle(fontSize: 17, color: context.palette.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: context.palette.textSecondary),
            border: InputBorder.none,
            counterStyle: TextStyle(color: context.palette.textSecondary),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        spacing: 12,
        children: [
          Expanded(
            child: CosPill(label: context.l10n.cancel, onTap: () => Navigator.pop(context)),
          ),
          Expanded(
            child: CosPill(label: widget.confirmLabel, onTap: _submit),
          ),
        ],
      ),
    ],
  );
}
