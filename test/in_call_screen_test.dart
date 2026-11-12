import 'dart:io';
import 'dart:ui' as ui;

import 'package:dialer/app/layout.dart';
import 'package:dialer/features/in_call/in_call_screen.dart';
import 'package:dialer/features/in_call/incoming_controls.dart';
import 'package:dialer/features/in_call/call_screen_widgets.dart';
import 'package:dialer/widgets/one_ui_floating_modal.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// A call control by its spoken name (the call screen shows no tooltips).
Finder control(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label),
  matching: find.byType(IconButton),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final nativeCalls = <MethodCall>[];
  const events = 'com.syedarhamraza.dialer/call_state';
  const codec = StandardMethodCodec();
  var meet = false;
  setUp(() {
    nativeCalls.clear();
    meet = false;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
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
      if (call.method == 'canMeetCall') return meet;
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
    // The controls' entrance clock starts on the frame after they appear.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(412, 915),
    double textScale = 1,
    bool reduceMotion = false,
    bool scaled = false,
    GlobalKey? boundary,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        scrollBehavior: OneUITheme.scrollBehavior,
        // Scaled previews capture the whole screen, so the boundary goes above the scaling.
        builder: scaled
            ? (context, child) => RepaintBoundary(
                key: boundary,
                child: DesignWidth(child: child!),
              )
            : null,
        home: Builder(
          builder: (context) => RepaintBoundary(
            key: scaled ? null : boundary,
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
    expect(find.byKey(const ValueKey('swipe-Answer')), findsOneWidget);
    expect(find.byKey(const ValueKey('swipe-Decline')), findsOneWidget);
    expect(find.text('SMS reply'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a dragged Answer ball flies into the End pill once Telecom connects', (tester) async {
    await open(tester);
    await emit(tester, [call('ringing')]);
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('swipe-Answer'))));
    await gesture.moveBy(const Offset(-20, -20));
    await gesture.moveBy(const Offset(-90, -90));
    await gesture.up();
    await tester.pump();
    expect(nativeCalls.where((c) => c.method == 'answer'), hasLength(1));
    final ball = find.byKey(const ValueKey('answer-flight'));
    expect(ball, findsOneWidget);
    // Let it glide to the top of its travel, where it waits for Telecom.
    await tester.pump(const Duration(milliseconds: 300));
    final released = tester.getRect(ball);

    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      events,
      codec.encodeSuccessEnvelope({
        'calls': [call('active')],
        'audio': {
          'muted': false,
          'route': 'earpiece',
          'supportedRoutes': ['earpiece', 'speaker'],
        },
      }),
      (_) {},
    );
    // Lay out the connected controls, then start the flight clock.
    await tester.pump();
    await tester.pump();
    // Small steps: the ball aims at the End pill's last painted place, which rises in as it flies.
    Future<void> fly(int ms) async {
      for (var i = 0; i < ms; i += 25) {
        await tester.pump(const Duration(milliseconds: 25));
      }
    }

    await fly(200);
    final end = find.ancestor(of: control('End call'), matching: find.byType(AnimatedOpacity)).first;
    double endOpacity() => tester.widget<AnimatedOpacity>(end).opacity;
    final to = tester.getRect(end);
    double down() => (tester.getRect(ball).center.dy - released.center.dy) / (to.center.dy - released.center.dy);
    double across() => (tester.getRect(ball).center.dx - released.center.dx) / (to.center.dx - released.center.dx);
    // 200 ms in, as in the ColorOS 17 recording: most of the way down, about half way across (it
    // curves in from above), and the real pill waits for it.
    expect(down(), closeTo(.82, .05));
    expect(across(), closeTo(.57, .05));
    expect(endOpacity(), 0);
    // It dips just past the pill (3%) and eases back; across never overshoots.
    await fly(200);
    expect(down(), inInclusiveRange(1.0, 1.05));
    expect(across(), lessThan(1));

    // The flight has landed within 800 ms.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(ball, findsNothing);
    expect(endOpacity(), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dragging Answer fades Decline and the SMS pill in step with the ball', (tester) async {
    await open(tester);
    await emit(tester, [call('ringing')]);
    final answer = find.byKey(const ValueKey('swipe-Answer'));
    final rest = tester.getCenter(answer).dy;
    final gesture = await tester.startGesture(tester.getCenter(answer));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // A straight line with the ball's height, gone at 75% of its travel.
    final faded = 1 - (rest - tester.getCenter(answer).dy) / (SwipeUpButton.size * 2.08 * .75);
    expect(faded, inExclusiveRange(.2, .8));
    double opacityAbove(Finder child, int nth) =>
        tester.widgetList<Opacity>(find.ancestor(of: child, matching: find.byType(Opacity))).elementAt(nth).opacity;
    // The ball's own Opacity (hidden while it flies) is nearer than the fade's.
    expect(opacityAbove(find.byKey(const ValueKey('swipe-Decline')), 1), closeTo(faded, .01));
    expect(opacityAbove(find.text('SMS reply'), 0), closeTo(faded, .01));
    await gesture.cancel();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('on a scaled narrow phone the Answer ball starts its flight where it was let go', (tester) async {
    await open(tester, size: const Size(360, 780), scaled: true);
    await emit(tester, [call('ringing')]);
    final answer = find.byKey(const ValueKey('swipe-Answer'));
    final gesture = await tester.startGesture(tester.getCenter(answer));
    await gesture.moveBy(const Offset(-20, -20));
    await gesture.moveBy(const Offset(-90, -90));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final letGo = tester.getRect(answer);
    await gesture.up();
    await tester.pump();
    final flight = tester.getRect(find.byKey(const ValueKey('answer-flight')));
    expect(flight.center.dx, closeTo(letGo.center.dx, 2));
    expect(flight.center.dy, closeTo(letGo.center.dy, 2));
    expect(flight.width, closeTo(letGo.width, 2));
    await tester.pumpWidget(const SizedBox());
  });

  // Common phone widths (dp), a tablet and landscape. Portrait phones up to the scale-up cap keep the
  // vivo's proportions; everything must lay out without overflow, ringing and connected.
  const sizes = [
    Size(320, 640), Size(360, 780), Size(384, 854), Size(393, 873), Size(412, 915), //
    Size(420, 933), Size(448, 998), Size(480, 1040), Size(800, 1280), Size(780, 360),
  ];
  testWidgets('the call screen keeps the vivo proportions across screen sizes', (tester) async {
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isNotEmpty) {
      await tester.runAsync(() async {
        await (FontLoader('Roboto')..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView))).load();
        await (FontLoader('MaterialIcons')..addFont(
              File('${File(fontPath).parent.path}/materialicons-regular.otf').readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      });
    }
    double? vivoRatio;
    for (final size in sizes) {
      final boundary = GlobalKey();
      await open(tester, size: size, scaled: true, boundary: boundary);
      await emit(tester, [call('ringing')]);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull, reason: 'ringing at $size');
      await emit(tester, [call('active')]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'connected at $size');
      final ratio = tester.getRect(control('End call')).width / size.width;
      if (size.width == DesignWidth.width) vivoRatio = ratio;
      if (fontPath.isNotEmpty) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(
            pixelRatio: 2,
          );
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/call-previews/sizes/${size.width.toInt()}x${size.height.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      final portraitPhone = size.height > size.width && size.width <= DesignWidth.width * DesignWidth.maxScale;
      if (portraitPhone && vivoRatio != null) {
        expect(ratio, closeTo(vivoRatio, .005), reason: 'End keeps the vivo proportion at $size');
      }
    }
    // Phones narrower than the vivo come first in the list; check them against its ratio too.
    for (final size in sizes.where((s) => s.width < DesignWidth.width)) {
      await open(tester, size: size, scaled: true);
      await emit(tester, [call('active')]);
      await tester.pumpAndSettle();
      expect(tester.getRect(control('End call')).width / size.width, closeTo(vivoRatio!, .005), reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Add call takes the third slot and opens the dialer; More holds the rest', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Add call'));
    expect(nativeCalls.where((c) => c.method == 'openDialer'), hasLength(1));
    await tester.tap(control('More'));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsOneWidget);
    // No Google Meet: Video stays in the menu, greyed out, and does nothing.
    expect(find.text('Video call (Meet)'), findsOneWidget);
    await tester.tap(find.text('Video call (Meet)'));
    await tester.pumpAndSettle();
    expect(nativeCalls.where((c) => c.method == 'meetCall'), isEmpty);
    expect(find.text('Video call (Meet)'), findsOneWidget); // The menu stayed open.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Video call hands the number to Google Meet when it is installed', (tester) async {
    meet = true;
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video call (Meet)'));
    await tester.pumpAndSettle();
    expect(nativeCalls.where((c) => c.method == 'meetCall').single.arguments['number'], '5550100');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a long press shows no tooltip, but screen readers keep the names', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.longPress(control('Mute'));
    await tester.pumpAndSettle();
    expect(find.byType(Tooltip), findsNothing);
    expect(find.bySemanticsLabel('Mute'), findsOneWidget);
    expect(find.bySemanticsLabel('End call'), findsOneWidget);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the status line shows HD and the SIM inline, with a plain timer and no chips', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    await emit(tester, [call('active')]);
    // Two SIMs (Personal, Work): the call's SIM shows as a mark beside HD and the timer.
    expect(find.bySemanticsLabel('Work'), findsOneWidget);
    expect(find.bySemanticsLabel('HD call'), findsOneWidget);
    // No chip row and no green live dot.
    expect(find.text('Phone call'), findsNothing);
    expect(find.text('HD'), findsOneWidget); // only the glyph's superscript
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == const Color(0xFF5BD69A),
      ),
      findsNothing,
    );
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the backdrop is a gradient aurora, never the wallpaper', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    expect(nativeCalls.map((c) => c.method), isNot(contains('getWallpaperBackdrop')));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient is RadialGradient,
      ),
      findsWidgets,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('formatted number, location and end reasons come from Telecom', (tester) async {
    await open(tester);
    await emit(tester, [
      {...call('active'), 'formattedNumber': '+44 20 7183 8750', 'location': 'United Kingdom'},
    ]);
    // As on ColorOS, the number and the city sit on lines of their own.
    expect(find.text('+44 20 7183 8750'), findsOneWidget);
    expect(find.text('United Kingdom'), findsOneWidget);
    await emit(tester, [
      {...call('disconnected'), 'disconnectCode': 'busy'},
    ]);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Line busy'), findsOneWidget);
    await emit(tester, [
      {
        ...call('disconnected', id: 'other'),
        'disconnectCode': 'error',
        'disconnectLabel': 'No service',
        'connectTimeMillis': 0,
      },
    ]);
    expect(find.text('No service'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('More takes a note; with two calls Merge takes Add call\'s place', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Note'));
    await tester.pumpAndSettle();
    expect(find.text('Call note'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Send the invoice');
    await tester.pump(const Duration(milliseconds: 500)); // Saved while typing.
    final notes = await DialerPrefs.instance.callNotes('5550100');
    expect(notes.single.$2, 'Send the invoice');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing); // Still on the call screen.
    await emit(tester, [
      {...call('active'), 'canMerge': true},
      call('holding', id: 'held'),
    ]);
    await tester.pumpAndSettle();
    expect(control('Add call'), findsNothing);
    expect(control('Merge'), findsOneWidget);
    await tester.tap(control('More'));
    await tester.pumpAndSettle();
    expect(find.text('Edit note'), findsOneWidget);
    await tester.tap(find.text('Add call'));
    await tester.pumpAndSettle();
    expect(nativeCalls.where((c) => c.method == 'openDialer'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(412, 915), const Size(320, 568), const Size(700, 360)]) {
    testWidgets('with the keypad open, the last row sits a little over a row-gap above the bottom row at $size', (
      tester,
    ) async {
      await open(tester, size: size);
      await emit(tester, [call('active')]);
      await tester.tap(control('Dial pad'));
      await tester.pumpAndSettle();
      Rect key(String digit) => tester.getRect(find.byKey(ValueKey('morph-key-$digit')));
      final rowGap = key('4').top - key('1').bottom;
      // The row's circles: the End pill is shorter and centred on them.
      final footerGap = tester.getRect(control('Dial pad')).top - key('0').bottom;
      expect(footerGap, inInclusiveRange(rowGap - 1, rowGap + 11));
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('controls rise in when the call screen opens', (tester) async {
    await open(tester);
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'com.syedarhamraza.dialer/call_state',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'calls': [call('dialing')],
        'audio': {
          'muted': false,
          'route': 'earpiece',
          'supportedRoutes': ['earpiece'],
        },
      }),
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    double fade() =>
        tester.widget<Opacity>(find.ancestor(of: control('End call'), matching: find.byType(Opacity)).last).opacity;
    expect(fade(), lessThan(1));
    await tester.pump(const Duration(milliseconds: 600));
    expect(fade(), 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a long typed number keeps its latest digits in view, on one line', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.bySemanticsLabel('${i % 10}'));
    }
    await tester.pumpAndSettle();
    final typed = find.byKey(const ValueKey('typed-digits'));
    final text = tester.widget<Text>(typed).data!;
    final paragraph = tester.renderObject<RenderParagraph>(typed);
    expect(text, endsWith('6789'));
    expect(paragraph.didExceedMaxLines, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('typed digits show above the keypad, under the caller name', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('4'));
    await tester.tap(find.bySemanticsLabel('2'));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget); // Still the title.
    expect(tester.getRect(find.text('42')).bottom, lessThanOrEqualTo(tester.getRect(find.bySemanticsLabel('1')).top));
    expect(tester.getRect(find.text('42')).top, greaterThan(tester.getRect(find.text('Alex Morgan')).bottom));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('42'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mute and route changes light their buttons, with no status pills', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    expect(find.text('Muted'), findsNothing);
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'com.syedarhamraza.dialer/call_state',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'calls': [call('active')],
        'audio': {
          'muted': true,
          'route': 'speaker',
          'supportedRoutes': ['earpiece', 'speaker'],
        },
      }),
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Speaker on'), findsNothing);
    expect(find.text('Muted'), findsNothing);
    expect(tester.widget<IconButton>(control('Mute')).isSelected, isTrue);
    expect(tester.widget<IconButton>(control('Speaker')).isSelected, isTrue);
    await tester.pumpWidget(const SizedBox());
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
    await tester.tap(control('Mute'));
    await tester.tap(control('End call'));
    expect(nativeCalls.any((c) => c.method == 'setMuted' && c.arguments['muted'] == true), isTrue);
    expect(nativeCalls.any((c) => c.method == 'hangUp' && c.arguments['id'] == 'call-1'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('connected controls are flat and End call has comfortable bottom clearance', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    final mute = tester.widget<IconButton>(control('Mute'));
    expect(mute.style!.backgroundColor!.resolve({}), Colors.transparent); // The body is painted behind.
    expect(mute.style!.side?.resolve({}), anyOf(isNull, BorderSide.none));
    expect(tester.getSize(control('Mute')), const Size(76, 76));
    expect(tester.getSize(control('Speaker')), const Size(76, 76));
    expect(tester.getBottomLeft(control('End call')).dy, lessThanOrEqualTo(915 - 48));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a call waiting for a SIM asks once: a pick goes to Telecom, no pick ends the call', (tester) async {
    await open(tester, reduceMotion: true);
    await emit(tester, [call('selectPhoneAccount')]);
    await tester.pumpAndSettle();
    expect(find.text('SIM 1 · Personal'), findsOneWidget);
    // Telecom repeats the state while it waits; the menu must not stack.
    await emit(tester, [call('selectPhoneAccount')]);
    await tester.pumpAndSettle();
    expect(find.text('SIM 2 · Work'), findsOneWidget);
    await tester.tap(find.text('SIM 2 · Work'));
    await tester.pumpAndSettle();
    final picks = nativeCalls.where((c) => c.method == 'selectSim').toList();
    expect(picks.single.arguments, {'id': 'call-1', 'simId': 'sim2'});
    expect(nativeCalls.any((c) => c.method == 'hangUp'), isFalse);

    await emit(tester, [call('selectPhoneAccount', id: 'call-2')]);
    await tester.pumpAndSettle();
    expect(find.text('SIM 1 · Personal'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4)); // outside the menu
    await tester.pumpAndSettle();
    expect(nativeCalls.any((c) => c.method == 'hangUp' && c.arguments['id'] == 'call-2'), isTrue);
    expect(nativeCalls.where((c) => c.method == 'selectSim'), hasLength(1));

    // The call ends from outside while the menu is up: it must not wait for the next call.
    await emit(tester, [call('selectPhoneAccount', id: 'call-3')]);
    await tester.pumpAndSettle();
    expect(find.text('SIM 1 · Personal'), findsOneWidget);
    await emit(tester, []);
    await tester.pumpAndSettle();
    expect(find.text('SIM 1 · Personal'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('audio output and quick replies use floating sheets', (tester) async {
    await open(tester, reduceMotion: true); // The ringing hint loops, which pumpAndSettle can't outwait.
    await emit(tester, [call('active')], bluetooth: true);
    await tester.tap(control('Speaker'));
    await tester.pumpAndSettle();
    // The app's own floating menu, the current route checked.
    expect(find.byType(OneUIFloatingModal), findsNothing);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    await tester.tap(find.text('Bluetooth'));
    await tester.pumpAndSettle();
    expect(nativeCalls.any((c) => c.method == 'setAudioRoute' && c.arguments['route'] == 'bluetooth'), isTrue);
    await emit(tester, [call('ringing', id: 'call-2')]);
    await tester.tap(find.text('SMS reply'));
    await tester.pumpAndSettle();
    expect(find.text('Custom'), findsOneWidget); // the ColorOS SMS reply card
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
    expect(find.text('SMS reply'), findsNothing);
    await emit(tester, [call('active', conference: true)]);
    expect(find.text('Conference call'), findsOneWidget);
    await emit(tester, [call('disconnected', conference: true)]);
    // The empty snapshot as the screen closes keeps the summary: "Call ended" shows once.
    await emit(tester, []);
    expect(find.textContaining('Call ended'), findsOneWidget);
    expect(control('End call'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dialing, held calls, capabilities and selected controls reflect Telecom state', (tester) async {
    await open(tester);
    await emit(tester, [call('dialing')]);
    expect(find.textContaining('Calling'), findsOneWidget);
    expect(tester.widget<IconButton>(control('Hold')).onPressed, isNull);
    expect(control('Merge'), findsNothing); // One call: the slot holds Add call.
    expect(control('Add call'), findsOneWidget);
    await emit(tester, [
      {...call('active'), 'canHold': true, 'canMerge': true},
      call('holding', id: 'held'),
    ]);
    await tester.tap(control('Hold'));
    await tester.tap(control('Merge'));
    expect(find.text('On hold'), findsOneWidget); // The held call's card.
    await tester.tap(find.text('Switch'));
    expect(nativeCalls.any((c) => c.method == 'hold' && c.arguments['id'] == 'call-1'), isTrue);
    expect(nativeCalls.any((c) => c.method == 'merge' && c.arguments['id'] == 'call-1'), isTrue);
    expect(nativeCalls.any((c) => c.method == 'unhold' && c.arguments['id'] == 'held'), isTrue);
    await emit(tester, [call('holding')]);
    expect(find.text('On hold'), findsOneWidget);
    expect(tester.widget<IconButton>(control('Resume')).isSelected, isTrue);
    await tester.tap(control('Resume'));
    expect(nativeCalls.last.method, 'unhold');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DTMF stops on release and Back restores controls', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
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
    expect(control('Mute'), findsOneWidget);
    await emit(tester, [call('active', id: 'new-call')]);
    // The Dial pad toggle is back to unlit.
    expect(tester.widget<IconButton>(control('Dial pad')).isSelected, isFalse);
    expect(find.text('5'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('actions recede while keypad rises and the bottom row stays anchored', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    final panel = find.byKey(const ValueKey('call-upper-panel'));
    final actions = find.byKey(const ValueKey('receding-call-actions'));
    double muteFade() =>
        tester.widget<Opacity>(find.ancestor(of: control('Mute'), matching: find.byType(Opacity)).first).opacity;
    expect(muteFade(), 1);
    final height = tester.getSize(panel).height;
    final end = tester.getRect(control('End call'));
    final speaker = tester.getRect(control('Speaker'));
    await tester.tap(control('Dial pad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));
    // Actions fade out in place; keys fade in.
    expect(muteFade(), lessThan(1));
    double fade(String digit) => tester.widget<Opacity>(find.byKey(ValueKey('keypad-fade-$digit'))).opacity;
    // Bottom row first, and in each row the middle key leads its neighbours.
    expect(fade('0'), greaterThan(fade('2')));
    expect(fade('0'), greaterThan(fade('*')));
    expect(fade('0'), inExclusiveRange(0, 1));
    final middle = tester.getTopLeft(find.byKey(const ValueKey('morph-key-1')));
    expect(tester.getSize(panel).height, greaterThan(height));
    expect(tester.getRect(control('End call')), end);
    expect(tester.getRect(control('Speaker')), speaker);
    // Upper-panel touches are ignored in flight, but ending the call is always available.
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('morph-key-5'))));
    expect(nativeCalls.where((c) => c.method == 'playDtmf'), isEmpty);
    await tester.tap(control('End call'));
    expect(nativeCalls.last.method, 'hangUp');
    final endCenter = tester.getCenter(control('End call'));
    // The spring's tail is longer than the old fixed curve; let it come to rest.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final settled = tester.getTopLeft(find.byKey(const ValueKey('morph-key-1')));
    expect(settled.dx, middle.dx);
    expect(actions, findsNothing);
    expect(fade('8'), 1);
    // Once tapped, End call draws in to a circle around the same centre (the glass press spring
    // may still be a fraction of a pixel from rest).
    expect(tester.getCenter(control('End call')), within(distance: .5, from: endCenter));
    expect(endCenter, within(distance: .5, from: end.center));
    expect(tester.getRect(control('Speaker')), speaker);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(412, 915), const Size(320, 568), const Size(700, 360)]) {
    testWidgets('closing reverses the key cascade and restores actions at $size', (tester) async {
      await open(tester, size: size);
      await emit(tester, [call('active')]);
      final panel = find.byKey(const ValueKey('call-upper-panel'));
      await tester.tap(control('Dial pad'));
      await tester.pumpAndSettle();
      final height = tester.getSize(panel).height;
      final end = tester.getRect(control('End call'));
      final speaker = tester.getRect(control('Speaker'));
      await tester.tap(control('Dial pad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      double fade(String digit) => tester.widget<Opacity>(find.byKey(ValueKey('keypad-fade-$digit'))).opacity;
      // Reverse the opening order: top row leaves before the bottom row.
      expect(fade('2'), lessThan(fade('0')));
      expect(fade('0'), inExclusiveRange(0, 1));
      expect(tester.widget<CallHeader>(find.byType(CallHeader)).keypadProgress, lessThan(1));
      // Closing must block DTMF throughout the reversed cascade.
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('morph-key-5'))));
      expect(nativeCalls.where((c) => c.method == 'playDtmf'), isEmpty);
      await tester.pump(const Duration(milliseconds: 160));
      final muteOpacity = find.ancestor(of: control('Mute'), matching: find.byType(Opacity)).first;
      final opacity = tester.widget<Opacity>(muteOpacity).opacity;
      expect(opacity, inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 32));
      expect(tester.widget<Opacity>(muteOpacity).opacity, greaterThan(opacity));
      expect(tester.getRect(control('End call')), end);
      expect(tester.getRect(control('Speaker')), speaker);
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).height, lessThan(height));
      expect(tester.widget<Opacity>(muteOpacity).opacity, 1);
      await tester.tap(control('Mute'));
      expect(nativeCalls.last.method, 'setMuted');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('call controls survive density and orientation changes with the keypad open', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1400, 720);
    tester.view.devicePixelRatio = 2;
    await tester.pumpAndSettle();
    expect(control('End call'), findsOneWidget);
    expect(find.byKey(const ValueKey('morph-key-5')), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
    await tester.tap(control('Dial pad'));
    await tester.pumpAndSettle();
    await tester.tap(control('Mute'));
    expect(nativeCalls.last.method, 'setMuted');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reopening during the fade preserves key opacity and transform', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
    await tester.pumpAndSettle();
    await tester.tap(control('Dial pad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final key = find.byKey(const ValueKey('keypad-fade-5'));
    final opacity = tester.widget<Opacity>(key).opacity;
    final transform = tester
        .widget<Transform>(find.descendant(of: key, matching: find.byType(Transform)).first)
        .transform;
    await tester.tap(control('Dial pad'));
    await tester.pump();
    expect(tester.widget<Opacity>(key).opacity, opacity);
    expect(
      tester.widget<Transform>(find.descendant(of: key, matching: find.byType(Transform)).first).transform,
      transform,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(key).opacity, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('closing mid-entrance fades the keys out instead of dropping them', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    double fade(String digit) => tester.widget<Opacity>(find.byKey(ValueKey('keypad-fade-$digit'))).opacity;
    await tester.tap(control('Dial pad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final shown = fade('0');
    final progress = tester.widget<CallHeader>(find.byType(CallHeader)).keypadProgress;
    expect(shown, greaterThan(.5));
    await tester.tap(control('Dial pad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Still on its way out, not gone in a frame.
    expect(fade('0'), inExclusiveRange(.3, shown + .01));
    expect(tester.widget<CallHeader>(find.byType(CallHeader)).keypadProgress, lessThan(progress));
    await tester.pumpAndSettle();
    expect(control('Mute'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rapid toggles reverse from the current geometry without a jump', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    final panel = find.byKey(const ValueKey('call-upper-panel'));
    final start = tester.getSize(panel).height;
    await tester.tap(control('Dial pad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final before = tester.getSize(panel).height;
    await tester.tap(control('Dial pad'));
    await tester.pump();
    expect(tester.getSize(panel).height, before);
    // Closing starts immediately and stays continuous when reversed again.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 140));
    final reversing = tester.getSize(panel).height;
    expect(reversing, lessThan(before));
    await tester.tap(control('Dial pad'));
    await tester.pump();
    expect(tester.getSize(panel).height, reversing);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('5'), findsOneWidget);
    expect(tester.widget<Opacity>(find.byKey(const ValueKey('keypad-fade-5'))).opacity, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.getSize(panel).height, start);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tones cancel on pointer cancellation, hiding, and changing calls', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
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
    await tester.tap(control('Dial pad'));
    await tester.pumpAndSettle();
    final changed = await press();
    await emit(tester, [call('active', id: 'replacement')]);
    expect(nativeCalls.last.method, 'stopDtmf');
    expect(nativeCalls.last.arguments['id'], 'call-1');
    await changed.up();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('enabling reduced motion during closing immediately restores controls', (tester) async {
    await open(tester);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
    await tester.pumpAndSettle();
    await tester.tap(control('Dial pad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await open(tester, reduceMotion: true);
    expect(tester.widget<CallHeader>(find.byType(CallHeader)).keypadProgress, 0);
    expect(find.byKey(const ValueKey('morph-key-5')), findsNothing);
    final opacity = find.ancestor(of: control('Mute'), matching: find.byType(Opacity)).first;
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    await tester.tap(control('Mute'));
    expect(nativeCalls.last.method, 'setMuted');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a reply selected after the ringing call changes cannot reject it', (tester) async {
    await open(tester, reduceMotion: true);
    await emit(tester, [call('ringing')]);
    await tester.tap(find.text('SMS reply'));
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
      expect(tester.getBottomLeft(find.byKey(const ValueKey('swipe-Decline'))).dy, lessThan(size.height));
      await emit(tester, [call('active')]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(control('End call')).dy, lessThan(size.height));
      final footerPosition = tester.getRect(control('End call'));
      await tester.tap(control('Dial pad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      // Within half a pixel: the glass press spring can still be settling.
      expect(tester.getCenter(control('End call')), within(distance: .5, from: footerPosition.center));
      await tester.pumpAndSettle();
      expect(tester.getCenter(control('End call')), within(distance: .5, from: footerPosition.center));
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(control('End call')).dy, lessThan(size.height));
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('reduced motion disables call transitions and ended calls have no actions', (tester) async {
    await open(tester, reduceMotion: true);
    await emit(tester, [call('active')]);
    await tester.tap(control('Dial pad'));
    await tester.pump();
    expect(find.bySemanticsLabel('5'), findsOneWidget);
    await emit(tester, [call('disconnected')]);
    expect(find.textContaining(RegExp(r'^Call ended · 00:0\d$')), findsOneWidget);
    expect(control('End call'), findsNothing);
    expect(control('Mute'), findsNothing);
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

      Future<void> captureClose(String name) async {
        await tester.tap(control('Dial pad'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 220));
        await capture('$name-close-fade', settle: false);
        await tester.pump(const Duration(milliseconds: 160));
        final actions = find.ancestor(of: control('Mute'), matching: find.byType(Opacity)).first;
        expect(tester.widget<Opacity>(actions).opacity, inExclusiveRange(0, 1));
        await capture('$name-close-actions', settle: false);
        await capture('$name-closed');
      }

      for (final state in ['ringing', 'dialing', 'active']) {
        await emit(tester, [call(state)]);
        // Ringing and dialing loop their hints, so capture them mid-animation.
        if (state != 'active') await tester.pump(const Duration(milliseconds: 900));
        await capture(state, settle: state == 'active');
      }
      await emit(tester, [
        {
          ...call('ringing', id: 'foreign'),
          'name': 'Priya Shah',
          'formattedNumber': '+44 20 7183 8750',
          'location': 'United Kingdom',
        },
      ]);
      await tester.pump(const Duration(milliseconds: 600));
      await capture('ringing-tint', settle: false);
      await emit(tester, [call('ringing', id: 'private', private: true)]);
      await tester.pump(const Duration(milliseconds: 600));
      await capture('ringing-private', settle: false);
      await emit(tester, [call('active', id: 'call-1')]);
      await tester.tap(control('Dial pad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      await capture('midpoint', settle: false);
      await capture('keypad');
      await captureClose('normal');
      await open(tester, boundary: boundary, size: const Size(320, 568), textScale: 1.5);
      await emit(tester, [call('active', id: 'compact')]);
      await tester.tap(control('Dial pad'));
      await capture('compact-keypad');
      await captureClose('compact');
      await open(tester, boundary: boundary, size: const Size(700, 360), textScale: 1.5);
      await emit(tester, [call('active', id: 'landscape')]);
      await tester.tap(control('Dial pad'));
      await capture('landscape-keypad');
      await captureClose('landscape');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
