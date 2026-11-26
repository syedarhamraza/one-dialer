import 'package:flutter/material.dart';

import '../core/prefs/dialer_prefs.dart';
import '../features/in_call/call_controls.dart' show answerGreen;
import '../l10n/l10n.dart';
import '../theme/one_ui_theme.dart';
import 'call_glyph.dart';
import 'press_glow.dart';

/// Settings › Call button on rows: the call button at the end of a Calls row, in Settings › Call
/// button style ([DialerPrefs.callButtonStyle], beta: `tint`, `glyph`, `lit`). [size] square.
class RowCallButton extends StatelessWidget {
  const RowCallButton({super.key, required this.onPressed});

  /// Null disables it (while selecting).
  final VoidCallback? onPressed;

  static const double size = 48;
  static const double _circle = 38;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: DialerPrefs.instance.callButtonStyle,
    builder: (context, style, _) {
      final l10n = context.l10n;
      if (style == 'glyph') {
        return IconButton(
          tooltip: l10n.call,
          onPressed: onPressed,
          icon: const CallGlyph(Icons.call_rounded, size: 24, color: answerGreen),
        );
      }
      final lit = style == 'lit';
      final lightGreen = Color.lerp(answerGreen, Colors.white, context.palette.isLight ? 0 : .25)!;
      return Semantics(
        button: true,
        enabled: onPressed != null,
        label: l10n.call,
        onTap: onPressed,
        excludeSemantics: true,
        child: Tooltip(
          message: l10n.call,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              // Lit is flat: the keypad's LitButton shadow reads as a second disc under a button this small.
              child: PressGlow(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: lit ? answerGreen : answerGreen.withValues(alpha: .2),
                    shape: const CircleBorder(),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onPressed,
                      child: SizedBox.square(
                        dimension: _circle,
                        child: Center(
                          child: CallGlyph(Icons.call_rounded, size: 20, color: lit ? Colors.white : lightGreen),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
