import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:dialer/features/setup/setup_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  testWidgets('setup screen asks for the default role with no way to skip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SetupScreen(onDone: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set One Dialer as your default phone app'), findsOneWidget);
    expect(find.bySemanticsLabel('Set as default'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
  });

  for (final light in [false, true]) {
    testWidgets('setup title follows the ${light ? 'light' : 'dark'} palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: light ? OneUITheme.lightTheme : OneUITheme.darkTheme,
          home: SetupScreen(onDone: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text('Set One Dialer as your default phone app'));
      final palette = light ? OneUIPalette.light : OneUIPalette.dark;
      expect(title.style!.color, palette.textPrimary);
    });
  }

  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  if (fontPath.isNotEmpty) {
    testWidgets('render setup previews', (tester) async {
      await tester.runAsync(() async {
        await (FontLoader('sans-serif')..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView))).load();
      });
      tester.view.physicalSize = const Size(420, 933);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final (name, theme) in [('light', OneUITheme.lightTheme), ('dark', OneUITheme.darkTheme)]) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: theme,
            home: RepaintBoundary(
              key: boundary,
              child: SetupScreen(onDone: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ImageByteFormat.png);
          File('build/setup-$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  }
}
