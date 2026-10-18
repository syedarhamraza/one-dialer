import 'dart:io';
import 'dart:ui' as ui;

import 'package:dialer/features/in_call/call_controls.dart';
import 'package:dialer/widgets/letter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exports the incoming call screen's Decline and Answer balls, the island glyph and the no-photo
/// caller avatar as the images on vivo's Origin Island (CallNotifications.kt). Re-run after changing their look:
/// `flutter test test/island_buttons_test.dart --dart-define=PREVIEW_FONT=<Flutter SDK>/bin/cache/artifacts/material_fonts/roboto-regular.ttf`
void main() {
  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  testWidgets('export island call buttons', skip: fontPath.isEmpty, (tester) async {
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('${File(fontPath).parent.path}/materialicons-regular.otf')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await icons.load();
    });
    const size = 72.0;
    // IncomingControls' ball, without the drop glow the card's slot would clip.
    Widget ball(Color color, IconData icon) => Container(
      width: size,
      height: size,
      decoration: solidBody(color, const CircleBorder(), glow: 0),
      foregroundDecoration: solidGlow(const CircleBorder()),
      child: Icon(icon, color: Colors.white, size: size * .46),
    );
    Widget speaker(Color fill, Color glyph) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
      child: Icon(Icons.volume_up_rounded, color: glyph, size: size * .46),
    );
    for (final (name, widget) in [
      ('island_decline', ball(endRed, Icons.call_end_rounded)),
      ('island_answer', ball(answerGreen, Icons.call_rounded)),
      ('island_phone', const Icon(Icons.call_rounded, color: answerGreen, size: size)), // collapsed island
      ('island_caller', const LetterAvatar(name: '', size: size)), // card's caller when there's no photo
      // CallControlButton's Speaker: frosted with a white glyph, or white with a dark glyph when on.
      ('island_speaker', speaker(const Color(0x2EFFFFFF), Colors.white)),
      ('island_speaker_on', speaker(const Color(0xEBFFFFFF), const Color(0xFF111418))),
    ]) {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(key: boundary, child: widget),
          ),
        ),
      );
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(
          pixelRatio: 3,
        );
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('android/app/src/main/res/drawable-nodpi/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
