import 'dart:io';

import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/services.dart';

/// Loads Roboto (from the Flutter SDK, with Cyrillic and Turkish letters) as the app's font, for
/// tests whose layout depends on how wide real text is: the test font draws every letter as a
/// square as wide as it is tall.
Future<void> loadRealFont() async {
  // flutter_tester lives under <sdk>/bin/cache/artifacts/engine/...; the fonts sit beside it.
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path && !dir.path.endsWith('cache')) {
    dir = dir.parent;
  }
  final fonts = '${dir.path}/artifacts/material_fonts';
  Future<ByteData> bytes(String file) async => ByteData.sublistView(await File('$fonts/$file').readAsBytes());
  for (final family in [OneUITheme.fontFamily, 'Roboto', 'sans-serif']) {
    await (FontLoader(family)
          ..addFont(bytes('roboto-regular.ttf'))
          ..addFont(bytes('roboto-medium.ttf'))
          ..addFont(bytes('roboto-bold.ttf')))
        .load();
  }
  await (FontLoader('MaterialIcons')..addFont(bytes('materialicons-regular.otf'))).load();
}
