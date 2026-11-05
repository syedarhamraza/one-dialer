import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws [icon] like [Icon], but the call handset and hang-up glyphs are our own Glossy handset
/// (`assets/icons/handset.png`, from `tool/icons/render_icons.py`); hang-up is it turned 135°.
class CallGlyph extends StatelessWidget {
  const CallGlyph(this.icon, {super.key, this.color, this.size});

  /// The glyph's share of its box: upright, and turned to hang up.
  static const handsetScale = .85, hangUpScale = .9;

  /// How much a handset grows as it tips over into the hang-up glyph.
  static const tipGrowth = hangUpScale / handsetScale;

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final handset = icon == Icons.call_rounded;
    if (!handset && icon != Icons.call_end_rounded) {
      return Icon(icon, color: color, size: size);
    }
    final theme = IconTheme.of(context);
    final box = size ?? theme.size ?? 24;
    // Material's glyph fills about 18 of its 24; ours fills its whole image. Turned to hang up, the
    // handset lies across the diagonal and looks smaller, so it's drawn larger.
    final glyph = ImageIcon(
      const AssetImage('assets/icons/handset.png'),
      color: color ?? theme.color,
      size: box * (handset ? handsetScale : hangUpScale),
    );
    return SizedBox.square(
      dimension: box,
      child: Center(
        child: handset ? glyph : Transform.rotate(angle: 3 * math.pi / 4, child: glyph),
      ),
    );
  }
}
