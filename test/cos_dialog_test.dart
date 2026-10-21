import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/cos_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> open(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return context;
  }

  testWidgets('confirm: true on the confirm pill, false on Back; destructive is red', (tester) async {
    final context = await open(tester);
    var result = showCosConfirm(context, message: 'Delete it?', confirmLabel: 'Delete', destructive: true);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('Delete')).style!.color, OneUITheme.accentRed);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);

    result = showCosConfirm(context, message: 'Delete it?', confirmLabel: 'Delete');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('text input returns trimmed text and keeps to maxLength', (tester) async {
    final context = await open(tester);
    final result = showCosTextInput(context, title: 'Message', maxLength: 5);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hello world'); // the field stops at 5
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await result, 'hello');
  });
}
