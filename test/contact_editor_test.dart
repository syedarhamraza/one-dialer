import 'dart:async';

import 'package:dialer/features/contacts/editor/contact_editor_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/one_ui_cancel_save_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_contacts');
  late Completer<Object?> accounts;
  late Object? contactResult;
  late List<MethodCall> writes;
  var failAccounts = false;

  setUp(() {
    accounts = Completer<Object?>.sync();
    contactResult = {
      'id': '7',
      'name': {'first': 'Test', 'last': 'Contact'},
    };
    writes = [];
    failAccounts = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'accounts.getAll':
          if (failAccounts) throw PlatformException(code: 'unavailable');
          return accounts.future;
        case 'accounts.getDefault':
          return null;
        case 'groups.getAll':
        case 'groups.getOf':
          return <Object?>[];
        case 'crud.get':
          return contactResult;
        case 'crud.create':
          writes.add(call);
          return 'saved-contact';
        case 'crud.update':
          writes.add(call);
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> open(WidgetTester tester, {String? contactId, String? number}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme.copyWith(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await openContactEditor(context, contactId: contactId, number: number);
                if (context.mounted && result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                }
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pump();
    await tester.pump();
  }

  Finder nameField() => find.byType(TextFormField).first;

  testWidgets('Add renders immediately and preserves typing while accounts load', (tester) async {
    await open(tester);
    expect(nameField(), findsOneWidget);
    await tester.enterText(nameField(), 'Typed while loading');
    expect(tester.widget<OneUIFloatingCancelSavePill>(find.byType(OneUIFloatingCancelSavePill)).canSave, isFalse);
    accounts.complete(<Object?>[]);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Typed while loading'), findsOneWidget);
    expect(tester.widget<OneUIFloatingCancelSavePill>(find.byType(OneUIFloatingCancelSavePill)).canSave, isTrue);
  });

  testWidgets('Add waits for entry animation before focusing Name', (tester) async {
    accounts.complete(<Object?>[]);
    await open(tester);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('Edit keeps a loading state until entry completes', (tester) async {
    await open(tester, contactId: '7');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Test Contact'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Test Contact'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('closing during load does not restore focus or pop the previous page', (tester) async {
    await open(tester);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.binding.handlePopRoute();
    await tester.binding.handlePopRoute();
    accounts.complete(<Object?>[]);
    await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
    expect(find.byType(ContactEditorScreen), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supplied number stays dirty and does not open keyboard', (tester) async {
    accounts.complete(<Object?>[]);
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    expect(find.text('5550100'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Save your changes or discard them?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
  });
  testWidgets('slow account loading defers focus until ready', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    accounts.complete(<Object?>[]);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('confirmation Save becomes available when pending accounts resolve', (tester) async {
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(TextButton, 'Save');
    expect(tester.widget<TextButton>(save).onPressed, isNull);
    accounts.complete(<Object?>[]);
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(save).onPressed, isNotNull);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('saved-contact'), findsOneWidget);
  });

  testWidgets('late loading does not steal focus from another field', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    final phone = find.byType(TextFormField).at(1);
    await tester.tap(phone);
    await tester.pump();
    accounts.complete(<Object?>[]);
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.descendant(of: phone, matching: find.byType(EditableText)));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('Edit can close before its contact query returns', (tester) async {
    final pending = Completer<Object?>.sync();
    contactResult = pending.future;
    await open(tester, contactId: '7');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    pending.complete({
      'id': '7',
      'name': {'first': 'Late'},
    });
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing freezes keyboard insets without delaying the pop', (tester) async {
    accounts.complete(<Object?>[]);
    await open(tester);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final pill = find.byType(OneUIFloatingCancelSavePill);
    final before = tester.getBottomLeft(pill).dy;
    tester.widget<OneUIFloatingCancelSavePill>(pill).onCancel();
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getBottomLeft(pill).dy, before);
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('confirmation Cancel preserves edits and repeated Cancel opens one dialog', (tester) async {
    accounts.complete(<Object?>[]);
    await open(tester);
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), 'Keep these edits');
    final pill = tester.widget<OneUIFloatingCancelSavePill>(find.byType(OneUIFloatingCancelSavePill));
    pill.onCancel();
    pill.onCancel();
    await tester.pumpAndSettle();
    expect(find.text('Save your changes or discard them?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Keep these edits'), findsOneWidget);
    expect(writes, isEmpty);
  });

  testWidgets('Save returns the created id and uses the resolved account once', (tester) async {
    accounts.complete([
      {'id': '', 'name': 'test@example.com', 'type': 'com.google'},
    ]);
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    final pill = tester.widget<OneUIFloatingCancelSavePill>(find.byType(OneUIFloatingCancelSavePill));
    pill.onSave!();
    pill.onSave!();
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
    expect(find.text('saved-contact'), findsOneWidget);
    expect(writes, hasLength(1));
    expect(writes.single.arguments['account']['name'], 'test@example.com');
  });

  testWidgets('confirmation Save updates the existing contact and returns its id', (tester) async {
    await open(tester, contactId: '7');
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), 'Changed name');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
    expect(find.text('7'), findsOneWidget);
    expect(writes.single.method, 'crud.update');
  });

  testWidgets('failed account loading keeps Save disabled and allows retry', (tester) async {
    failAccounts = true;
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load accounts"), findsOneWidget);
    expect(tester.widget<OneUIFloatingCancelSavePill>(find.byType(OneUIFloatingCancelSavePill)).canSave, isFalse);
    accounts = Completer<Object?>.sync()..complete(<Object?>[]);
    failAccounts = false;
    await tester.tap(find.text("Couldn't load accounts"));
    await tester.pumpAndSettle();
    expect(find.text('5550100'), findsOneWidget);
    expect(tester.widget<OneUIFloatingCancelSavePill>(find.byType(OneUIFloatingCancelSavePill)).canSave, isTrue);
  });
}
