import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws [icon] like [Icon], but the call handset and hang-up glyphs are our own Glossy handset
/// (`assets/icons/handset.png`, from `tool/icons/render_icons.py`); hang-up is it turned 135°, and
/// an ongoing call ([Icons.phone_in_talk_rounded]) is it with sound waves (`handset_talk.png`).
/// [Icons.chat_rounded] and [Icons.videocam_rounded] are its matching Message and Video glyphs
/// (`message.png`, `video.png`), and [Icons.person_add_alt_1_rounded] its Add contact glyph
/// (`add_contact.png`), for the contact and call details pages' tiles. The nav bar's unselected Calls
/// ([Icons.call_outlined]) is the handset outlined, and Contacts ([Icons.people_alt_rounded],
/// [Icons.people_alt_outlined]) ColorOS's two people (`handset_outline.png`, `contacts*.png`).
class CallGlyph extends StatelessWidget {
  const CallGlyph(this.icon, {super.key, this.color, this.size});

  /// The glyph's share of its box: upright, and turned to hang up.
  static const handsetScale = .85, hangUpScale = .9;

  /// How much a handset grows as it tips over into the hang-up glyph.
  static const tipGrowth = hangUpScale / handsetScale;

  static final _companions = {
    Icons.chat_rounded: 'assets/icons/message.png',
    Icons.videocam_rounded: 'assets/icons/video.png',
    Icons.person_add_alt_1_rounded: 'assets/icons/add_contact.png',
    Icons.call_outlined: 'assets/icons/handset_outline.png',
    Icons.people_alt_rounded: 'assets/icons/contacts.png',
    Icons.people_alt_outlined: 'assets/icons/contacts_outline.png',
  };

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final handset = icon == Icons.call_rounded;
    final talk = icon == Icons.phone_in_talk_rounded;
    final theme = IconTheme.of(context);
    final box = size ?? theme.size ?? 24;
    // Drawn on Material's 24-unit grid, so they fill their box like an Icon.
    if (_companions[icon] case final asset?) {
      return ImageIcon(AssetImage(asset), color: color ?? theme.color, size: box);
    }
    if (!handset && !talk && icon != Icons.call_end_rounded) {
      return Icon(icon, color: color, size: size);
    }
    // Material's glyph fills about 18 of its 24; ours fills its whole image. Turned to hang up, the
    // handset lies across the diagonal and looks smaller, so it's drawn larger. The talk glyph's
    // handset is smaller within its image (the waves share it), so it fills its whole box.
    final glyph = ImageIcon(
      AssetImage(talk ? 'assets/icons/handset_talk.png' : 'assets/icons/handset.png'),
      color: color ?? theme.color,
      size: box * (talk ? 1 : (handset ? handsetScale : hangUpScale)),
    );
    return SizedBox.square(
      dimension: box,
      child: Center(
        child: talk
            // Nudged up and right so the handset and waves sit optically centred.
            ? Transform.translate(offset: const Offset(1, -1), child: glyph)
            : handset
            ? glyph
            : Transform.rotate(angle: 3 * math.pi / 4, child: glyph),
      ),
    );
  }
}
