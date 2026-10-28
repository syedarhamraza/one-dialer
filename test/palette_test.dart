import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/one_ui_glass_surface.dart';

void main() {
  testWidgets('light pages get the light palette, glass keeps the dark one', (tester) async {
    late OneUIPalette page, glass;
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.lightTheme,
        home: Builder(
          builder: (context) {
            page = context.palette;
            return OneUIGlassSurface(
              child: Builder(
                builder: (context) {
                  glass = context.palette;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    expect(page, same(OneUIPalette.light));
    expect(glass, same(OneUIPalette.dark));
  });
}
