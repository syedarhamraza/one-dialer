import 'dart:io';

import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/services.dart';

/// Loads Roboto (test/fonts, copied from the Flutter SDK's material fonts, Apache 2.0, with Cyrillic and
/// Turkish letters) as the app's font, for tests whose layout depends on how wide real text is: the test
/// font draws every letter as a square as wide as it is tall. Kept in the repo because a fresh SDK (CI)
/// only downloads its own copy on the first app build.
Future<void> loadRealFont() async {
  Future<ByteData> bytes(String file) async => ByteData.sublistView(await File('test/fonts/$file').readAsBytes());
  for (final family in [OneUITheme.fontFamily, 'Roboto', 'sans-serif']) {
    await (FontLoader(family)
          ..addFont(bytes('roboto-regular.ttf'))
          ..addFont(bytes('roboto-medium.ttf'))
          ..addFont(bytes('roboto-bold.ttf')))
        .load();
  }
  // Real icons too when the SDK has them (only previews care; icon sizes don't depend on the glyphs).
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path && !dir.path.endsWith('cache')) {
    dir = dir.parent;
  }
  final icons = File('${dir.path}/artifacts/material_fonts/materialicons-regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
  }
}
