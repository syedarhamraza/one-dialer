import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/keypad/keypad_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.syedarhamraza.dialer/telecom');
  final nativeCalls = <MethodCall>[];
  setUp(() {
    nativeCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      if (call.method == 'getSims') return [];
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
  tearDown(() => ContactsRepository.instance.contacts.value = []);

  testWidgets('floating button and Android Back restore the typed number', (tester) async {
    final input = ValueNotifier('0333');
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Scaffold(body: KeypadScreen(input: input)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show keypad'));
    await tester.pumpAndSettle();
    expect(input.value, '0333');
    expect(find.byTooltip('Show keypad'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show keypad'), findsNothing);
    expect(input.value, '0333');
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
          theme: OneUITheme.darkTheme,
          home: RepaintBoundary(
            key: boundary,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(393, 852), padding: EdgeInsets.only(top: 24, bottom: 16)),
              child: Scaffold(body: KeypadScreen(input: input)),
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
      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pumpAndSettle();
      await capture('keypad-results-preview');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scrolling expands results; selecting restores keypad without calling', (tester) async {
    final input = ValueNotifier('0333');
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Scaffold(body: KeypadScreen(input: input)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show keypad'), findsOneWidget);
    expect(input.value, '0333');
    await tester.tap(find.text('Contact 0'));
    await tester.pumpAndSettle();
    expect(input.value, '03331234500');
    expect(find.byTooltip('Show keypad'), findsNothing);
    expect(find.byTooltip('WhatsApp voice call'), findsOneWidget);
    expect(nativeCalls.where((call) => call.method == 'placeCall'), isEmpty);
  });

  testWidgets('empty and service-code input disable WhatsApp', (tester) async {
    final input = ValueNotifier('');
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Scaffold(body: KeypadScreen(input: input)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final number in ['', '+', '*123#', '123,4', '123;4']) {
      input.value = number;
      await tester.pumpAndSettle();
      final button = tester.widget<IconButton>(
        find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'WhatsApp voice call'),
      );
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('inactive collapsed keypad does not block route back', (tester) async {
    final input = ValueNotifier('0333');
    final active = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: ValueListenableBuilder<bool>(
          valueListenable: active,
          builder: (_, isActive, child) => Scaffold(
            body: KeypadScreen(input: input, isActive: isActive),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(tester.widget<PopScope>(find.byWidgetPredicate((w) => w is PopScope)).canPop, isFalse);
    active.value = false;
    await tester.pumpAndSettle();
    expect(tester.widget<PopScope>(find.byWidgetPredicate((w) => w is PopScope)).canPop, isTrue);
    input.value = '+923331234567';
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show keypad'), findsNothing);
  });

  testWidgets('two SIM actions fit a compact screen and keep their routing', (tester) async {
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
        theme: OneUITheme.darkTheme,
        home: Scaffold(body: KeypadScreen(input: ValueNotifier('03331234567'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel('Call with Work'));
    await tester.pumpAndSettle();
    expect(nativeCalls.singleWhere((call) => call.method == 'placeCall').arguments['simId'], 'sim2');
  });

  testWidgets('compact keypad fits with larger text and action ordering', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: KeypadScreen(input: ValueNotifier('0333'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.byTooltip('WhatsApp voice call')).dx,
      lessThan(tester.getCenter(find.bySemanticsLabel('Call')).dx),
    );
  });
}
