import 'dart:io';
import 'dart:ui' as ui;

import 'package:dialer/features/in_call/call_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exports the Play Store icon (512 × 512 PNG, full square: Play rounds the corners and adds the
/// shadow) to `docs/play-icon.png`, drawn like the launcher icon (`res/mipmap-anydpi/ic_launcher.xml`).
/// Re-run after changing the icon:
/// `flutter test test/play_icon_test.dart --dart-define=PREVIEW_FONT=<Flutter SDK>/bin/cache/artifacts/material_fonts/roboto-regular.ttf`
void main() {
  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  testWidgets('export Play Store icon', skip: fontPath.isEmpty, (tester) async {
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('${File(fontPath).parent.path}/materialicons-regular.otf')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await icons.load();
    });
    const size = 512.0;
    final boundary = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(size, size));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: boundary,
          child: Container(
            width: size,
            height: size,
            // ic_launcher_background.xml: solidBody's Answer-green gradient plus solidGlow's lift.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(answerGreen, Colors.black, .1)!,
                  answerGreen,
                  Color.lerp(answerGreen, Colors.white, .14)!,
                ],
                stops: const [0, .55, 1],
              ),
            ),
            foregroundDecoration: solidGlow(const RoundedRectangleBorder()),
            // ic_launcher_foreground.xml scales the 24-unit glyph by 2.4; launchers show the middle 72 of its 108 units.
            child: const Icon(Icons.call_rounded, color: Colors.white, size: size * 24 * 2.4 / 72),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('docs/play-icon.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.binding.setSurfaceSize(null);
  });
}
