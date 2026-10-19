import 'package:dialer/features/setup/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('setup screen asks for the default role with no way to skip', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SetupScreen(onDone: () {})));
    await tester.pumpAndSettle();

    expect(find.text('Set One Dialer as your default phone app'), findsOneWidget);
    expect(find.bySemanticsLabel('Set as default'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
  });
}
