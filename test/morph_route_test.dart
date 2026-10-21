import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/morph_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const screen = Size(420, 933);
  const buttonRect = Rect.fromLTWH(340, 840, 58, 58);

  Future<void> open(WidgetTester tester, {bool reduceMotion = false}) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion), child: child!),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fromRect(
                rect: buttonRect,
                child: Builder(
                  builder: (button) => TextButton(
                    onPressed: () => Navigator.of(button).push(
                      MorphPageRoute<void>(
                        source: button,
                        color: OneUITheme.dialGreen,
                        builder: (_) => const Scaffold(body: Center(child: TextField())),
                      ),
                    ),
                    child: const Text('+'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('+'));
    await tester.pump();
  }

  Rect clip(WidgetTester tester) => tester.getRect(find.byType(ClipRSuperellipse).last);

  testWidgets('grows out of the button, fills the screen, and shrinks back into it', (tester) async {
    await open(tester);
    await tester.pump(const Duration(milliseconds: 40));
    final early = clip(tester);
    expect(early.width, lessThan(screen.width));
    expect(early.contains(buttonRect.center), isTrue);

    // Typing while it opens: the page keeps its state when the morph finishes.
    await tester.enterText(find.byType(TextField), 'kept');
    await tester.pumpAndSettle();
    expect(clip(tester), Offset.zero & screen);
    expect(find.text('kept'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final closing = clip(tester);
    expect(closing.width, lessThan(screen.width));
    expect(closing.contains(buttonRect.center), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('+'), findsOneWidget);
  });

  testWidgets('reduced motion just fades, without the morph', (tester) async {
    await open(tester, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ClipRSuperellipse), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
}
