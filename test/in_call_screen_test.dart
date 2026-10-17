import 'dart:io';
import 'dart:ui' as ui;

import 'package:dialer/features/in_call/in_call_screen.dart';
import 'package:dialer/features/in_call/call_screen_widgets.dart';
import 'package:dialer/widgets/one_ui_floating_modal.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final nativeCalls = <MethodCall>[];
  const events = 'com.syedarhamraza.dialer/call_state';
  const codec = StandardMethodCodec();
  setUp(() {
    nativeCalls.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(events), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (call) async {
      if (call.method.startsWith('permissions.')) return 'denied';
      return null;
    });
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      nativeCalls.add(call);
      if (call.method == 'getSims') {
        return [
          {'id': 'sim1', 'label': 'Personal'},
          {'id': 'sim2', 'label': 'Work'},
        ];
      }
      if (call.method == 'getQuickReplies') return ["I'll call you back", "Can't talk right now"];
      return null;
    });
  });

  Map<String, Object?> call(String state, {String id = 'call-1', bool private = false, bool conference = false}) => {
    'id': id,
    'state': state,
    'number': '5550100',
    'name': 'Alex Morgan',
    'simId': 'sim2',
    'isPrivate': private,
    'isConference': conference,
    'isHd': true,
    'connectTimeMillis': DateTime.now().subtract(const Duration(seconds: 5)).millisecondsSinceEpoch,
  };

  Future<void> emit(WidgetTester tester, List<Map<String, Object?>> calls, {bool bluetooth = false}) async {
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      events,
      codec.encodeSuccessEnvelope({
        'calls': calls,
        'audio': {
          'muted': false,
          'route': 'earpiece',
          'supportedRoutes': ['earpiece', 'speaker', if (bluetooth) 'bluetooth'],
        },
      }),
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(412, 915),
    double textScale = 1,
    bool reduceMotion = false,
    GlobalKey? boundary,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        scrollBehavior: OneUITheme.scrollBehavior,
        home: Builder(
          builder: (context) => RepaintBoundary(
            key: boundary,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reduceMotion),
              child: const InCallScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('incoming layout fits a compact screen and labels both swipe actions', (tester) async {
    await open(tester, size: const Size(320, 568));
    await emit(tester, [call('ringing')]);
    expect(tester.takeException(), isNull);
    expect(find.text('Answer'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
  });

  testWidgets('connected timer ticks without another Telecom event', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    final time = find.textContaining(RegExp(r'^00:\d\d$'));
    final before = tester.widget<Text>(time).data;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100)));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<Text>(time).data, isNot(before));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mute and End call still target Telecom', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(find.byTooltip('Mute'));
    await tester.tap(find.byTooltip('End call'));
    expect(nativeCalls.any((c) => c.method == 'setMuted' && c.arguments['muted'] == true), isTrue);
    expect(nativeCalls.any((c) => c.method == 'hangUp' && c.arguments['id'] == 'call-1'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('connected controls are flat and End call has comfortable bottom clearance', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    final mute = tester.widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Mute'));
    expect(mute.style!.backgroundColor!.resolve({}), const Color(0xFF344850));
    expect(mute.style!.side?.resolve({}), anyOf(isNull, BorderSide.none));
    expect(tester.getSize(find.byTooltip('Mute')), const Size(76, 76));
    expect(tester.getSize(find.byTooltip('Speaker')), const Size(76, 76));
    expect(tester.getBottomLeft(find.byTooltip('End call')).dy, lessThanOrEqualTo(915 - 48));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('audio output and quick replies use floating sheets', (tester) async {
    await open(tester);
    await emit(tester, [call('active')], bluetooth: true);
    await tester.tap(find.byTooltip('Speaker'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIFloatingModal), findsOneWidget);
    await tester.tap(find.text('Bluetooth'));
    await tester.pumpAndSettle();
    expect(nativeCalls.any((c) => c.method == 'setAudioRoute' && c.arguments['route'] == 'bluetooth'), isTrue);
    await emit(tester, [call('ringing', id: 'call-2')]);
    await tester.tap(find.text('Decline with message'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIFloatingModal), findsOneWidget);
    await tester.tap(find.text("I'll call you back"));
    await tester.pumpAndSettle();
    expect(nativeCalls.any((c) => c.method == 'rejectWithMessage' && c.arguments['id'] == 'call-2'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('private calls hide number and replies; conference and ended states render', (tester) async {
    await open(tester);
    await emit(tester, [call('ringing', private: true)]);
    expect(find.text('Private number'), findsOneWidget);
    expect(find.text('5550100'), findsNothing);
    expect(find.text('Decline with message'), findsNothing);
    await emit(tester, [call('active', conference: true)]);
    expect(find.text('Conference call'), findsOneWidget);
    await emit(tester, []);
    expect(find.text('Call ended'), findsOneWidget);
    expect(find.byTooltip('End call'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dialing, held calls, capabilities and selected controls reflect Telecom state', (tester) async {
    await open(tester);
    await emit(tester, [call('dialing')]);
    expect(find.text('Calling…'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Hold')).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Merge')).onPressed,
      isNull,
    );
    await emit(tester, [
      {...call('active'), 'canHold': true, 'canMerge': true},
      call('holding', id: 'held'),
    ]);
    await tester.tap(find.byTooltip('Hold'));
    await tester.tap(find.byTooltip('Merge'));
    await tester.tap(find.text('Swap'));
    expect(nativeCalls.any((c) => c.method == 'hold' && c.arguments['id'] == 'call-1'), isTrue);
    expect(nativeCalls.any((c) => c.method == 'merge' && c.arguments['id'] == 'call-1'), isTrue);
    expect(nativeCalls.any((c) => c.method == 'unhold' && c.arguments['id'] == 'held'), isTrue);
    await emit(tester, [call('holding')]);
    expect(find.text('On hold'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Resume')).isSelected,
      isTrue,
    );
    await tester.tap(find.byTooltip('Resume'));
    expect(nativeCalls.last.method, 'unhold');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DTMF stops on release and Back restores controls', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pumpAndSettle();
    final key = find.bySemanticsLabel('5');
    final gesture = await tester.startGesture(tester.getCenter(key));
    await tester.pump(const Duration(milliseconds: 150));
    expect(nativeCalls.any((c) => c.method == 'playDtmf' && c.arguments['digit'] == '5'), isTrue);
    await gesture.up();
    await tester.pump();
    expect(nativeCalls.last.method, 'stopDtmf');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mute'), findsOneWidget);
    await emit(tester, [call('active', id: 'new-call')]);
    expect(find.byTooltip('Hide keypad'), findsNothing);
    expect(find.text('5'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('actions recede while keypad rises and the bottom row stays anchored', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    final panel = find.byKey(const ValueKey('call-upper-panel'));
    final actions = find.byKey(const ValueKey('receding-call-actions'));
    expect(tester.widget<Transform>(actions).transform.storage[0], 1);
    final height = tester.getSize(panel).height;
    final end = tester.getRect(find.byTooltip('End call'));
    final speaker = tester.getRect(find.byTooltip('Speaker'));
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));
    expect(tester.widget<Transform>(actions).transform.storage[0], lessThan(1));
    final keySpring = find.byKey(const ValueKey('keypad-spring-8'));
    expect(tester.widget<Transform>(keySpring).transform.storage[0], inExclusiveRange(1.025, 1.05));
    final keyFade = find.ancestor(of: keySpring, matching: find.byType(Opacity)).first;
    expect(tester.widget<Opacity>(keyFade).opacity, inExclusiveRange(0, 1));
    final middle = tester.getTopLeft(find.byKey(const ValueKey('morph-key-1')));
    expect(tester.getSize(panel).height, greaterThan(height));
    expect(tester.getRect(find.byTooltip('End call')), end);
    expect(tester.getRect(find.byTooltip('Speaker')), speaker);
    // Upper-panel touches are ignored in flight, but ending the call is always available.
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('morph-key-5'))));
    expect(nativeCalls.where((c) => c.method == 'playDtmf'), isEmpty);
    await tester.tap(find.byTooltip('End call'));
    expect(nativeCalls.last.method, 'hangUp');
    await tester.pump(const Duration(milliseconds: 210));
    final settled = tester.getTopLeft(find.byKey(const ValueKey('morph-key-1')));
    expect(settled.dy - middle.dy, inExclusiveRange(0, 8));
    expect(actions, findsNothing);
    expect(tester.widget<Transform>(keySpring).transform.storage[0], 1);
    expect(tester.getRect(find.byTooltip('End call')), end);
    expect(tester.getRect(find.byTooltip('Speaker')), speaker);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rapid toggles reverse from the current geometry without a jump', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    final panel = find.byKey(const ValueKey('call-upper-panel'));
    final start = tester.getSize(panel).height;
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final before = tester.getSize(panel).height;
    await tester.tap(find.byTooltip('Hide keypad'));
    await tester.pump();
    expect(tester.getSize(panel).height, before);
    await tester.pump(const Duration(milliseconds: 35));
    final reversing = tester.getSize(panel).height;
    expect(reversing, lessThan(before));
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pump();
    expect(tester.getSize(panel).height, reversing);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('5'), findsOneWidget);
    expect(tester.widget<Transform>(find.byKey(const ValueKey('keypad-spring-5'))).transform.storage[0], 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.getSize(panel).height, start);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tones cancel on pointer cancellation, hiding, and changing calls', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pumpAndSettle();
    Future<TestGesture> press() async {
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('morph-key-5'))));
      await tester.pump(const Duration(milliseconds: 120));
      expect(nativeCalls.last.method, 'playDtmf');
      return gesture;
    }

    final cancelled = await press();
    await cancelled.cancel();
    await tester.pump();
    expect(nativeCalls.last.method, 'stopDtmf');
    expect(find.text('5'), findsNWidgets(2)); // Entered digits and the key.
    final hidden = await press();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(nativeCalls.last.method, 'stopDtmf');
    await hidden.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pumpAndSettle();
    final changed = await press();
    await emit(tester, [call('active', id: 'replacement')]);
    expect(nativeCalls.last.method, 'stopDtmf');
    expect(nativeCalls.last.arguments['id'], 'call-1');
    await changed.up();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a reply selected after the ringing call changes cannot reject it', (tester) async {
    await open(tester);
    await emit(tester, [call('ringing')]);
    await tester.tap(find.text('Decline with message'));
    await tester.pumpAndSettle();
    await emit(tester, [call('active')]);
    await tester.tap(find.text("I'll call you back"));
    await tester.pumpAndSettle();
    expect(nativeCalls.where((c) => c.method == 'rejectWithMessage'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(320, 568), const Size(700, 360), const Size(412, 915)]) {
    testWidgets('controls stay reachable at $size with enlarged text', (tester) async {
      await open(tester, size: size, textScale: 1.5);
      await emit(tester, [call('ringing')]);
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(find.text('Decline')).dy, lessThan(size.height));
      await emit(tester, [call('active')]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(find.byTooltip('End call')).dy, lessThan(size.height));
      final footerPosition = tester.getRect(find.byTooltip('End call'));
      await tester.tap(find.byTooltip('Keypad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      expect(tester.getRect(find.byTooltip('End call')), footerPosition);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byTooltip('End call')), footerPosition);
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(find.byTooltip('End call')).dy, lessThan(size.height));
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('reduced motion disables call transitions and ended calls have no actions', (tester) async {
    await open(tester, reduceMotion: true);
    await emit(tester, [call('active')]);
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pump();
    expect(find.bySemanticsLabel('5'), findsOneWidget);
    await emit(tester, [call('disconnected')]);
    expect(find.text('Call ended'), findsOneWidget);
    expect(find.byTooltip('End call'), findsNothing);
    expect(find.byTooltip('Mute'), findsNothing);
    expect(find.byType(CallBackdrop), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  if (fontPath.isNotEmpty) {
    testWidgets('render One UI call previews with real fonts', (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('Roboto')
          ..addFont(File(fontPath).readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            File('${File(fontPath).parent.path}/materialicons-regular.otf')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)),
          );
        await icons.load();
      });
      final boundary = GlobalKey();
      await open(tester, boundary: boundary);
      Future<void> capture(String name, {bool settle = true}) async {
        if (settle) await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(
            pixelRatio: 2,
          );
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/call-previews/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      for (final state in ['ringing', 'dialing', 'active']) {
        await emit(tester, [call(state)]);
        await capture(state);
      }
      await tester.tap(find.byTooltip('Keypad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      await capture('midpoint', settle: false);
      await capture('keypad');
      await open(tester, boundary: boundary, size: const Size(320, 568), textScale: 1.5);
      await emit(tester, [call('active', id: 'compact')]);
      await tester.tap(find.byTooltip('Keypad'));
      await capture('compact-keypad');
      await open(tester, boundary: boundary, size: const Size(700, 360), textScale: 1.5);
      await emit(tester, [call('active', id: 'landscape')]);
      await tester.tap(find.byTooltip('Keypad'));
      await capture('landscape-keypad');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
