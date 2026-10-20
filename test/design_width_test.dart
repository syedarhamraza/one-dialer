import 'package:dialer/app/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<(Size, EdgeInsets, Size)> layOut(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 36);
    addTearDown(tester.view.reset);
    late MediaQueryData seen;
    final probe = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DesignWidth(child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.of(context);
            return SizedBox.expand(key: probe);
          },
        ),
      ),
    );
    return (seen.size, seen.padding, tester.getSize(find.byKey(probe)));
  }

  testWidgets('a narrow phone lays out at the design width, scaled to fit', (tester) async {
    final (size, padding, drawn) = await layOut(tester, const Size(360, 780));
    expect(size.width, DesignWidth.width);
    expect(size.height, closeTo(780 * 420 / 360, .01));
    expect(padding.top, closeTo(36 * 420 / 360, .01));
    expect(drawn, size); // laid out at 420 wide; FittedBox shrinks it onto the 360 screen
  });

  testWidgets('the design width lays out unscaled', (tester) async {
    final (size, padding, _) = await layOut(tester, const Size(420, 933));
    expect(size, const Size(420, 933));
    expect(padding.top, 36);
  });

  testWidgets('a wider phone scales up to the design width', (tester) async {
    final (size, _, _) = await layOut(tester, const Size(448, 998));
    expect(size.width, closeTo(DesignWidth.width, .01));
  });

  testWidgets('tablets stop scaling up at the cap and get more room instead', (tester) async {
    final (size, _, _) = await layOut(tester, const Size(800, 1280));
    expect(size.width, closeTo(800 / DesignWidth.maxScale, .01));
  });

  testWidgets('landscape never scales', (tester) async {
    final (size, padding, _) = await layOut(tester, const Size(780, 360));
    expect(size, const Size(780, 360));
    expect(padding.top, 36);
  });
}
