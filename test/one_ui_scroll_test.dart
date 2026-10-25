import 'package:dialer/theme/one_ui_scroll.dart';
import 'package:dialer/widgets/one_ui_subpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('short pages bounce back without stretch notifications', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var overscroll = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        scrollBehavior: const OneUIScrollBehavior(),
        home: Scaffold(
          body: NotificationListener<OverscrollNotification>(
            onNotification: (_) {
              overscroll++;
              return false;
            },
            child: ListView(controller: controller, children: const [SizedBox(height: 80)]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.position.maxScrollExtent, 0);
    expect(controller.position.physics.shouldAcceptUserOffset(controller.position), isTrue);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    expect(controller.offset, greaterThan(0)); // pulled past the end
    expect(controller.offset, lessThan(60)); // but softer than the finger
    await gesture.up();
    await tester.pumpAndSettle();
    expect(overscroll, 0);
    expect(controller.offset, 0);
  });

  testWidgets('subpages fill the screen, so a bounce does not cut off short content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const OneUIScrollBehavior(),
        home: OneUISubpage(title: 'T', builder: (_) => const [SizedBox(height: 80)]),
      ),
    );
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).height,
      tester.view.physicalSize.height / tester.view.devicePixelRatio,
    );
  });

  testWidgets('long pages retain scrolling and header snap', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const OneUIScrollBehavior(),
        home: Scaffold(
          body: ListView(
            controller: controller,
            physics: OneUIScrollPhysics.bigHeader,
            children: const [SizedBox(height: 1800)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.position.physics.shouldAcceptUserOffset(controller.position), isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(OneUIScrollPhysics.bigHeaderCollapse, 1));
  });

  testWidgets('fitted content holds still under the app-wide bounce', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var overscroll = 0;
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const OneUIScrollBehavior(),
        home: NotificationListener<OverscrollNotification>(
          onNotification: (_) {
            overscroll++;
            return false;
          },
          child: SingleChildScrollView(
            controller: controller,
            physics: const HoldStillScrollPhysics(),
            child: const SizedBox(height: 80),
          ),
        ),
      ),
    );
    expect(controller.position.physics.shouldAcceptUserOffset(controller.position), isFalse);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(overscroll, 0);
    expect(controller.offset, 0);
  });
}
