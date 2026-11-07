import 'package:dialer/app/layout.dart';
import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/keypad/keypad_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.syedarhamraza.dialer/telecom');
  final nativeCalls = <MethodCall>[];
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    nativeCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      if (call.method == 'getSims') return [];
      if (call.method == 'formatAsYouType') {
        final n = call.arguments['number'] as String;
        return n.length > 4 ? '${n.substring(0, 4)} ${n.substring(4)}' : n;
      }
      return null;
    });
    ContactsRepository.instance.contacts.value = List.generate(
      20,
      (i) => DialerContact(
        id: '$i',
        name: 'Contact $i',
        numbers: ['033312345${i.toString().padLeft(2, '0')}'],
        labels: const ['Mobile'],
      ),
    );
  });
  tearDown(() {
    ContactsRepository.instance.contacts.value = [];
    DialerPrefs.instance.simChoice.value = 'buttons';
  });

  testWidgets('keys keep the vivo proportions on a narrower phone', (tester) async {
    Future<Size> keyRatio(Size screen) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OneUITheme.darkTheme,
          builder: (context, child) => DesignWidth(child: child!),
          home: Scaffold(
            body: KeypadScreen(open: ValueNotifier(true), input: ValueNotifier('')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final key = tester.getRect(find.bySemanticsLabel('5, long-press for speed dial'));
      return Size(key.width / screen.width, key.height / screen.width);
    }

    final vivo = await keyRatio(const Size(420, 933));
    final s25 = await keyRatio(const Size(360, 780));
    expect(s25.width, closeTo(vivo.width, .005));
    expect(s25.height, closeTo(vivo.height, .005));
  });

  testWidgets('Back and the dialpad pill hide the keys; reopening keeps the number', (tester) async {
    final input = ValueNotifier('0333');
    final open = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: open, input: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(open.value, isFalse);
    open.value = true;
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Hide keypad'));
    await tester.pumpAndSettle();
    expect(open.value, isFalse);
    open.value = true;
    await tester.pumpAndSettle();
    expect(input.value, '0333');
  });

  testWidgets('the first digit keeps the keypad sheet, so a key press is not cut off', (tester) async {
    final input = ValueNotifier('');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: ValueNotifier(true), input: input),
        ),
      ),
    );
    final sheet = tester.element(find.byKey(const ValueKey('keypad-panel')));
    input.value = '5';
    await tester.pump();
    expect(tester.element(find.byKey(const ValueKey('keypad-panel'))), same(sheet));
  });

  // Optional real-font render for visual review, without a connected Android device.
  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  if (fontPath.isNotEmpty) {
    testWidgets('render keypad reference previews', (tester) async {
      await tester.runAsync(() async {
        final loader = FontLoader('Roboto')
          ..addFont(File(fontPath).readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
        await loader.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            File('${File(fontPath).parent.path}/materialicons-regular.otf')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)),
          );
        await icons.load();
      });
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final input = ValueNotifier('+');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OneUITheme.darkTheme,
          home: RepaintBoundary(
            key: boundary,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(393, 852), padding: EdgeInsets.only(top: 24, bottom: 16)),
              child: Scaffold(
                body: KeypadScreen(open: ValueNotifier(true), input: input),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(
            pixelRatio: 2,
          );
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('keypad-preview');
      input.value = '0333';
      await tester.pumpAndSettle();
      await tester.drag(find.text('Contact 0'), const Offset(0, -80));
      await tester.pumpAndSettle();
      await capture('keypad-results-preview');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scrolling expands results; selecting restores keypad without calling', (tester) async {
    final input = ValueNotifier('0333');
    final open = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: open, input: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('Contact 0'), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(open.value, isFalse);
    expect(input.value, '0333');
    await tester.tap(find.text('Contact 0'));
    await tester.pumpAndSettle();
    expect(input.value, '03331234500');
    expect(open.value, isTrue);
    expect(find.byTooltip('WhatsApp voice call'), findsNothing);
    expect(find.bySemanticsLabel('Call'), findsOneWidget);
    expect(nativeCalls.where((call) => call.method == 'placeCall'), isEmpty);
  });

  test('field offsets skip the grouping spaces', () {
    expect(dialableOf('+92 311-935'), '+92311935');
    expect(rawIndex('0333 333', 6), 5);
    expect(fieldOffset('0333 333', 4), 4);
    expect(fieldOffset('0333 333', 5), 6);
    expect(fieldOffset('0333 333', 0), 0);
  });

  testWidgets('the number is grouped; keys and holds type at the tapped cursor', (tester) async {
    final input = ValueNotifier('');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(body: KeypadScreen(open: ValueNotifier(true), input: input)),
      ),
    );
    await tester.pumpAndSettle();
    // Untapped, keys add at the end.
    for (final d in '0333333'.split('')) {
      await tester.tap(find.text(d).last);
    }
    await tester.pumpAndSettle();
    expect(input.value, '0333333');
    expect(find.text('0333 333'), findsOneWidget);
    // Tap the number, put the cursor after "0333", then type and hold.
    await tester.tap(find.byType(TextField));
    await tester.pump();
    tester.widget<TextField>(find.byType(TextField)).controller!.selection = const TextSelection.collapsed(offset: 4);
    await tester.pump();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();
    expect(input.value, '03331333');
    await tester.longPress(find.text('*'));
    await tester.pumpAndSettle();
    expect(input.value, '03331,333');
  });

  testWidgets('typing and clearing leave the keys at the same position', (tester) async {
    final input = ValueNotifier('');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: ValueNotifier(true), input: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final call = find.bySemanticsLabel('Call');
    final before = tester.getCenter(call);
    input.value = '0333';
    await tester.pumpAndSettle();
    expect(tester.getCenter(call), before);
    input.value = '';
    await tester.pumpAndSettle();
    expect(tester.getCenter(call), before);
    expect(find.byTooltip('WhatsApp voice call'), findsNothing);
  });

  testWidgets('keypad slides down and back up through intermediate positions', (tester) async {
    final open = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: open, input: ValueNotifier('0333')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey('keypad-panel'));
    final opened = tester.getTopLeft(panel).dy;
    await tester.drag(find.text('Contact 0'), const Offset(0, -40));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final closing = tester.getTopLeft(panel).dy;
    expect(closing, greaterThan(opened));
    await tester.pumpAndSettle();
    final closed = tester.getTopLeft(panel).dy;
    expect(closed, greaterThan(closing));
    open.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final opening = tester.getTopLeft(panel).dy;
    expect(opening, lessThan(closed));
    expect(opening, greaterThan(opened));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel).dy, opened);
  });

  testWidgets('inactive keypad does not block route back', (tester) async {
    final open = ValueNotifier(true);
    final active = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: ValueListenableBuilder<bool>(
          valueListenable: active,
          builder: (_, isActive, child) => Scaffold(
            body: KeypadScreen(open: open, input: ValueNotifier(''), isActive: isActive),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    PopScope<Object?> scope() => tester.widget<PopScope<Object?>>(find.byWidgetPredicate((w) => w is PopScope));
    expect(scope().canPop, isFalse);
    active.value = false;
    await tester.pumpAndSettle();
    expect(scope().canPop, isTrue);
    active.value = true;
    open.value = false;
    await tester.pumpAndSettle();
    expect(scope().canPop, isTrue);
  });

  testWidgets('ask mode: one call button offers both SIMs and routes the selected SIM', (tester) async {
    DialerPrefs.instance.simChoice.value = 'menu';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      if (call.method == 'getSims') {
        return [
          {'id': 'sim1', 'label': 'Personal', 'isDefault': false},
          {'id': 'sim2', 'label': 'Work', 'isDefault': false},
        ];
      }
      return null;
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: ValueNotifier(true), input: ValueNotifier('03331234567')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Call'), findsOneWidget);
    expect(find.text('Work'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Call'));
    await tester.pumpAndSettle();
    expect(find.text('SIM 1 · Personal'), findsOneWidget);
    await tester.tap(find.text('SIM 2 · Work'));
    await tester.pumpAndSettle();
    expect(nativeCalls.singleWhere((call) => call.method == 'placeCall').arguments['simId'], 'sim2');
  });

  testWidgets('cancelling SIM selection preserves the number and places no call', (tester) async {
    DialerPrefs.instance.simChoice.value = 'menu';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      if (call.method == 'getSims') {
        return [
          {'id': 'sim1', 'label': 'Personal', 'isDefault': false},
          {'id': 'sim2', 'label': 'Work', 'isDefault': false},
        ];
      }
      return null;
    });
    final input = ValueNotifier('5551234567');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: ValueNotifier(true), input: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Call'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(input.value, '5551234567');
    expect(nativeCalls.where((call) => call.method == 'placeCall'), isEmpty);
  });

  testWidgets('two Call buttons call on their own SIM without asking', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      if (call.method == 'getSims') {
        return [
          {'id': 'sim1', 'label': 'Personal', 'isDefault': false},
          {'id': 'sim2', 'label': 'Work', 'isDefault': false},
        ];
      }
      return null;
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: ValueNotifier(true), input: ValueNotifier('03331234567')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Call with SIM 1, Personal'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Call with SIM 2, Work'));
    await tester.pumpAndSettle();
    expect(find.text('SIM 1 · Personal'), findsNothing);
    expect(nativeCalls.singleWhere((call) => call.method == 'placeCall').arguments['simId'], 'sim2');
  });

  testWidgets('system default SIM calls without showing a chooser', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      if (call.method == 'getSims') {
        return [
          {'id': 'sim1', 'label': 'Personal', 'isDefault': true},
          {'id': 'sim2', 'label': 'Work', 'isDefault': false},
        ];
      }
      return null;
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: ValueNotifier(true), input: ValueNotifier('5551234567')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Call'));
    await tester.pumpAndSettle();
    expect(find.text('SIM 2 · Work'), findsNothing);
    expect(nativeCalls.singleWhere((call) => call.method == 'placeCall').arguments['number'], '5551234567');
  });

  testWidgets('keypad hides and reopens cleanly in landscape', (tester) async {
    final open = ValueNotifier(true);
    tester.view.physicalSize = const Size(700, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: KeypadScreen(open: open, input: ValueNotifier('0333')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(open.value, isFalse);
    open.value = true;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact keypad fits with larger text and action ordering', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: KeypadScreen(open: ValueNotifier(true), input: ValueNotifier('0333')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getCenter(find.bySemanticsLabel('Call')).dx, 160);
  });
}
