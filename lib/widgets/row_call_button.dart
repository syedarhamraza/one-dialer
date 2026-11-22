import 'package:flutter/material.dart';

import '../core/prefs/dialer_prefs.dart';
import '../features/in_call/call_controls.dart' show answerGreen;
import '../l10n/l10n.dart';
import '../theme/one_ui_theme.dart';
import 'press_glow.dart';

/// Settings › Call button on rows: the call button at the end of a Calls or Contacts row, in
/// Settings › Call button style ([DialerPrefs.callButtonStyle], beta: `tint`, `glyph`, `glass`,
/// `lit`, `pill`). 48 high; [widthFor] says how wide, so rows can size their trailing slot.
class RowCallButton extends StatelessWidget {
  const RowCallButton({super.key, required this.onPressed});

  /// Null disables it (while selecting).
  final VoidCallback? onPressed;

  static const double _circle = 38;

  /// The pill's width holds the handset and the word, at 13 sp.
  static double widthFor(String style) => style == 'pill' ? 88 : 48;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: DialerPrefs.instance.callButtonStyle,
    builder: (context, style, _) {
      final l10n = context.l10n;
      final palette = context.palette;
      if (style == 'glyph') {
        return IconButton(
          tooltip: l10n.call,
          onPressed: onPressed,
          icon: const Icon(Icons.call_rounded, size: 24, color: answerGreen),
        );
      }
      final pill = style == 'pill';
      final OutlinedBorder shape = pill ? const StadiumBorder() : const CircleBorder();
      final lightGreen = Color.lerp(answerGreen, Colors.white, palette.isLight ? 0 : .25)!;
      final fg = style == 'lit' ? Colors.white : (style == 'glass' ? answerGreen : lightGreen);
      final ink = Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: pill ? 30 : _circle,
            width: pill ? null : _circle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pill ? 11 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call_rounded, size: pill ? 16 : 20, color: fg),
                  if (pill) ...[
                    const SizedBox(width: 5),
                    Text(
                      l10n.call,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      final body = switch (style) {
        // Flat: the keypad's LitButton shadow reads as a second disc under a button this small.
        'lit' => PressGlow(
          child: DecoratedBox(
            decoration: ShapeDecoration(color: answerGreen, shape: shape),
            child: ink,
          ),
        ),
        'glass' => PressGlow(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.pill,
              shape: shape.copyWith(side: BorderSide(color: palette.divider, width: .8)),
            ),
            child: ink,
          ),
        ),
        _ => PressGlow(
          child: DecoratedBox(
            decoration: ShapeDecoration(color: answerGreen.withValues(alpha: .2), shape: shape),
            child: ink,
          ),
        ),
      };
      return Semantics(
        button: true,
        enabled: onPressed != null,
        label: l10n.call,
        onTap: onPressed,
        excludeSemantics: true,
        child: Tooltip(
          message: l10n.call,
          child: SizedBox(
            width: widthFor(style),
            height: 48,
            child: Center(
              // Long translations (and wide test fonts) shrink to fit rather than overflow.
              child: FittedBox(fit: BoxFit.scaleDown, child: body),
            ),
          ),
        ),
      );
    },
  );
}
