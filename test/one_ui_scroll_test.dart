import 'package:dialer/theme/one_ui_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('short pages do not accept drags or produce stretch notifications', (tester) async {
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
    expect(controller.position.physics.shouldAcceptUserOffset(controller.position), isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(overscroll, 0);
    expect(controller.offset, 0);
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
}
