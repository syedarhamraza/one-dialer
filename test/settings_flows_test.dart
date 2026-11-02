import 'package:dialer/features/blocking/blocking_screen.dart';
import 'package:dialer/features/settings/app_icon_screen.dart';
import 'package:dialer/features/settings/quick_replies_screen.dart';
import 'package:dialer/widgets/one_ui_radio.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final telecom = <MethodCall>[];

  setUp(() {
    telecom.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      telecom.add(call);
      return switch (call.method) {
        'getBlocking' => <String, Object?>{},
        'hasScreeningRole' => false,
        'getQuickReplies' => ['Hi'],
        'getLauncherIcon' => 'classic',
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (_) async => null);
  });

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  // Stops at the input: flutter_contacts' block call checks dart:io Platform.isAndroid, which
  // a desktop test host can't fake.
  testWidgets('Add number opens the menu, and Enter number the floating input', (tester) async {
    await open(tester, const BlockingScreen());
    await tester.tap(find.text('Add number'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from contacts'), findsOneWidget);
    await tester.tap(find.text('Enter number'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from contacts'), findsNothing);
    expect(find.text('Block number'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a quick reply is kept to one SMS', (tester) async {
    await open(tester, const QuickRepliesScreen());
    await tester.tap(find.text('Add message'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x' * 200);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = telecom.lastWhere((c) => c.method == 'setQuickReplies').arguments;
    expect('$saved', contains('x' * 160));
    expect('$saved', isNot(contains('x' * 161)));
  });

  testWidgets('the app icon page shows the current style and switches both icons', (tester) async {
    await open(tester, const AppIconScreen());
    bool selected(int i) => tester.widgetList<OneUIRadio>(find.byType(OneUIRadio)).elementAt(i).isSelected;
    expect([selected(0), selected(1)], [false, true]); // classic
    await tester.tap(find.text('Glossy'));
    await tester.pumpAndSettle();
    expect(telecom.last.method, 'setLauncherIcon');
    expect(telecom.last.arguments, {'style': 'default'});
    expect([selected(0), selected(1)], [true, false]);
  });
}
