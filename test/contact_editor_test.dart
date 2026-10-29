import 'dart:async';

import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/contacts/editor/contact_editor_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_contacts');
  const telecom = MethodChannel('com.syedarhamraza.dialer/telecom');
  late Completer<Object?> accounts;
  late Object? contactResult;
  late List<MethodCall> writes;
  var failAccounts = false;
  Object? defaultAccount;

  setUp(() {
    accounts = Completer<Object?>.sync();
    contactResult = {
      'id': '7',
      'name': {'first': 'Test', 'last': 'Contact'},
    };
    writes = [];
    failAccounts = false;
    defaultAccount = null;
    // Where a new contact can be saved comes from our own bridge (the phone, SIMs, Google).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(telecom, (call) async {
      if (call.method != 'getContactAccounts') return null;
      if (failAccounts) throw PlatformException(code: 'unavailable');
      return accounts.future;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'accounts.getDefault':
          return defaultAccount;
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(telecom, null);
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
  // The header pills; the confirmation dialog's own Cancel comes later in the tree.
  Finder cancelPill() => find.widgetWithText(TextButton, 'Cancel').first;
  bool canSave(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Done')).onPressed != null;

  testWidgets('Add renders immediately and preserves typing while accounts load', (tester) async {
    await open(tester);
    expect(nameField(), findsOneWidget);
    await tester.enterText(nameField(), 'Typed while loading');
    expect(canSave(tester), isFalse);
    accounts.complete(<Object?>[]);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Typed while loading'), findsOneWidget);
    expect(canSave(tester), isTrue);
  });

  testWidgets('Add rising like the keypad slides up, focuses Name, and slides back down', (tester) async {
    accounts.complete(<Object?>[]);
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme.copyWith(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => openContactEditor(context, rise: true), child: const Text('Open editor')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final rising = tester.getTopLeft(find.byType(ContactEditorScreen)).dy;
    expect(rising, greaterThan(0)); // still on its way up from below
    expect(rising, lessThan(screenHeight));
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(ContactEditorScreen)).dy, 0);
    expect(tester.testTextInput.isVisible, isTrue);

    tester.widget<TextButton>(cancelPill()).onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20)); // the drop starts on this frame
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getTopLeft(find.byType(ContactEditorScreen)).dy, greaterThan(0)); // going back down
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
  });

  /// Android's predictive back, as the engine sends it.
  Future<void> backGesture(WidgetTester tester, String method, [double progress = 0]) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.backGesture.name,
      SystemChannels.backGesture.codec.encodeMethodCall(
        MethodCall(method, {
          'touchOffset': [5.0, 300.0],
          'progress': progress,
          'swipeEdge': 0,
        }),
      ),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('a rising Add follows the back swipe down, and settles back on cancel', (tester) async {
    accounts.complete(<Object?>[]);
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme.copyWith(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => openContactEditor(context, rise: true), child: const Text('Open editor')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    double top() => tester.getTopLeft(find.byType(ContactEditorScreen)).dy;

    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', .3);
    expect(top(), greaterThan(0));
    await backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(top(), 0);

    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', .3);
    await backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
  });

  testWidgets('back swipe pops an unchanged editor, and asks once something is typed', (tester) async {
    accounts.complete(<Object?>[]);
    await open(tester);
    await tester.pumpAndSettle();
    bool canPop() => tester.widget<PopScope<Object?>>(find.byWidgetPredicate((w) => w is PopScope)).canPop;
    expect(canPop(), isTrue);
    await tester.enterText(nameField(), 'Ann');
    await tester.pump();
    expect(canPop(), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save your changes or discard them?'), findsOneWidget);
    await tester.binding.handlePopRoute(); // closes the dialog
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), '');
    await tester.pump();
    expect(canPop(), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
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
    await tester.tap(cancelPill());
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

  testWidgets('confirmation offers Save only once accounts have loaded', (tester) async {
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    await tester.tap(cancelPill());
    await tester.pumpAndSettle();
    expect(find.text('Discard'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    await tester.binding.handlePopRoute(); // closes the dialog
    await tester.pumpAndSettle();
    accounts.complete(<Object?>[]);
    await tester.pumpAndSettle();
    await tester.tap(cancelPill());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
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
    final form = find.byType(ListView);
    final before = tester.getBottomLeft(form).dy;
    tester.widget<TextButton>(cancelPill()).onPressed!();
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getBottomLeft(form).dy, before);
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('confirmation Cancel preserves edits and repeated Cancel opens one dialog', (tester) async {
    accounts.complete(<Object?>[]);
    await open(tester);
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), 'Keep these edits');
    final cancel = tester.widget<TextButton>(cancelPill()).onPressed!;
    cancel();
    cancel();
    await tester.pumpAndSettle();
    expect(find.text('Save your changes or discard them?'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('Keep these edits'), findsOneWidget);
    expect(writes, isEmpty);
  });

  testWidgets('saving a number that is already saved asks first', (tester) async {
    ContactsRepository.instance.debugSetContacts([
      DialerContact(id: 'a', name: 'Alice', numbers: const ['555 0100'], labels: const ['Mobile']),
    ]);
    addTearDown(() => ContactsRepository.instance.debugSetContacts([]));
    accounts.complete([
      {'name': 'test@example.com', 'type': 'com.google'},
    ]);
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5550100 is already saved as Alice'), findsOneWidget);
    await tester.tap(find.text('Cancel').last); // the dialog's, over the editor's
    await tester.pumpAndSettle();
    expect(writes, isEmpty);
    expect(find.byType(ContactEditorScreen), findsOneWidget);
  });

  testWidgets('Save returns the created id and uses the resolved account once', (tester) async {
    accounts.complete([
      {'name': 'test@example.com', 'type': 'com.google'},
    ]);
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    final save = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Done')).onPressed!;
    save();
    save();
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
    await tester.tap(cancelPill());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(ContactEditorScreen), findsNothing);
    expect(find.text('7'), findsOneWidget);
    expect(writes.single.method, 'crud.update');
  });

  for (final cloud in [true, false]) {
    testWidgets('Save to offers This device and SIM only without a cloud default (cloud: $cloud)', (tester) async {
      if (cloud) defaultAccount = {'id': '', 'name': 'test@example.com', 'type': 'com.google'};
      accounts.complete([
        {'name': null, 'type': null},
        {'name': 'USIM4', 'type': 'USIM Account'},
        {'name': 'test@example.com', 'type': 'com.google'},
      ]);
      await open(tester);
      await tester.pumpAndSettle();
      expect(find.text('Save to test@example.com'), findsOneWidget);
      await tester.tap(find.text('Save to test@example.com'));
      await tester.pumpAndSettle();
      expect(find.text('This device'), cloud ? findsNothing : findsOneWidget);
      expect(find.text('SIM card'), cloud ? findsNothing : findsOneWidget);
    });
  }

  testWidgets('failed account loading keeps Save disabled and allows retry', (tester) async {
    failAccounts = true;
    await open(tester, number: '5550100');
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load accounts"), findsOneWidget);
    expect(canSave(tester), isFalse);
    accounts = Completer<Object?>.sync()..complete(<Object?>[]);
    failAccounts = false;
    await tester.tap(find.text("Couldn't load accounts"));
    await tester.pumpAndSettle();
    expect(find.text('5550100'), findsOneWidget);
    expect(canSave(tester), isTrue);
  });
}
