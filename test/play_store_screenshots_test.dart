import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dialer/app/main_shell.dart';
import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/in_call/call_controls.dart';
import 'package:dialer/features/in_call/in_call_screen.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/recents/call_log_repository.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Exports the Play Store phone screenshots (1080 × 1920, captioned) and the 1024 × 500 feature
/// graphic to `docs/play/`, rendered from the real screens with made-up contacts and calls.
/// Re-run after UI changes:
/// `flutter test test/play_store_screenshots_test.dart --dart-define=PREVIEW_FONT=<Flutter SDK>/bin/cache/artifacts/material_fonts/roboto-regular.ttf`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  const events = 'com.syedarhamraza.dialer/call_state';
  const phone = Size(420, 933); // the vivo the app is designed on (DesignWidth)
  final now = DateTime.now();

  final people = [
    ('Alex Morgan', '555-0100'),
    ('Alicia Chen', '555-0101'),
    ('Ben Carter', '555-0102'),
    ('Chloe Rivera', '555-0103'),
    ('Daniel Kim', '555-0104'),
    ('Emma Wilson', '555-0105'),
    ('Ethan Brooks', '555-0106'),
    ('Grace Patel', '555-0107'),
    ('Hannah Lee', '555-0108'),
    ('Isaac Nguyen', '555-0109'),
    ('Liam Foster', '555-0110'),
    ('Mia Johnson', '555-0111'),
    ('Noah Davis', '555-0112'),
    ('Olivia Martin', '555-0113'),
    ('Sophia Turner', '555-0114'),
  ];

  var consumeDial = '';
  var consumeRecents = false;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(events), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      switch (call.method) {
        case 'getSims':
          return [];
        case 'consumeDialNumber':
          return consumeDial.isEmpty ? null : consumeDial;
        case 'consumeOpenRecents':
          return consumeRecents;
        case 'getQuickReplies':
          return ["I'll call you back", "Can't talk right now"];
      }
      return null;
    });
    ContactsRepository.instance.debugSetContacts([
      for (final (i, (name, number)) in people.indexed)
        DialerContact(id: '$i', name: name, numbers: [number], labels: const ['Mobile']),
    ]);
    var id = 0;
    CallLogEntry entry(String number, CallType type, Duration ago, {int seconds = 0, bool isNew = false}) =>
        CallLogEntry.fromMap({
          'id': id++,
          'number': number,
          'type': type.name,
          'date': now.subtract(ago).millisecondsSinceEpoch,
          'duration': seconds,
          'isNew': isNew,
        });
    CallLogRepository.instance.calls.value = [
      entry('555-0105', CallType.missed, const Duration(minutes: 12), isNew: true),
      entry('555-0100', CallType.outgoing, const Duration(minutes: 48), seconds: 324),
      entry('555-0100', CallType.incoming, const Duration(hours: 1, minutes: 5), seconds: 95),
      entry('555-0198', CallType.incoming, const Duration(hours: 2, minutes: 20), seconds: 41),
      entry('555-0107', CallType.outgoing, const Duration(hours: 3), seconds: 610),
      entry('555-0102', CallType.missed, const Duration(hours: 5)),
      entry('555-0111', CallType.incoming, const Duration(hours: 26), seconds: 188),
      entry('555-0103', CallType.outgoing, const Duration(hours: 28), seconds: 72),
      entry('555-0108', CallType.incoming, const Duration(hours: 30), seconds: 455),
      entry('555-0113', CallType.outgoing, const Duration(hours: 50), seconds: 230),
      entry('555-0104', CallType.rejected, const Duration(hours: 53)),
      entry('555-0110', CallType.incoming, const Duration(hours: 75), seconds: 64),
    ];
  });

  tearDown(() {
    ContactsRepository.instance.debugSetContacts([]);
    CallLogRepository.instance.calls.value = [];
  });

  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
    await (FontLoader('Roboto')..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView))).load();
    await (FontLoader('MaterialIcons')..addFont(
          File('${File(fontPath).parent.path}/materialicons-regular.otf').readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });

  Future<void> save(WidgetTester tester, GlobalKey boundary, String name) async {
    // Text with no font family (the nav bar's labels) gets the system font on a phone but the
    // test engine's box font here; give the settled paragraphs Roboto, as Android would.
    for (final p in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
      final span = p.text;
      if (span is TextSpan && span.style != null && span.style!.fontFamily == null) {
        p.text = TextSpan(
          text: span.text,
          style: span.style!.copyWith(fontFamily: 'Roboto'),
          children: span.children,
        );
      }
    }
    await tester.pump();
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final file = File('docs/play/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(_rgbPng(rgba!.buffer.asUint8List(), image.width, image.height));
      image.dispose();
    });
  }

  /// Pumps [home] as a phone screen inside a captioned store frame.
  Future<GlobalKey> frame(
    WidgetTester tester,
    String title,
    String subtitle,
    Widget home, {
    bool wallpaper = false,
    bool feature = false,
  }) async {
    tester.view.physicalSize = feature ? const Size(1024, 500) : const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(const SizedBox()); // a fresh screen state for every shot
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: OneUITheme.darkTheme,
        scrollBehavior: OneUITheme.scrollBehavior,
        builder: (context, child) => RepaintBoundary(
          key: boundary,
          child: _StoreFrame(
            title: title,
            subtitle: subtitle,
            wallpaper: wallpaper,
            feature: feature,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: phone,
                padding: const EdgeInsets.only(top: 36, bottom: 16),
                viewPadding: const EdgeInsets.only(top: 36, bottom: 16),
                devicePixelRatio: 3,
              ),
              child: child!,
            ),
          ),
        ),
        home: home,
      ),
    );
    await tester.pump();
    return boundary;
  }

  void emit(WidgetTester tester, String state) {
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      events,
      const StandardMethodCodec().encodeSuccessEnvelope({
        'calls': [
          {
            'id': 'call-1',
            'state': state,
            'number': '555-0100',
            'name': 'Alex Morgan',
            'isHd': true,
            'connectTimeMillis': now.subtract(const Duration(minutes: 3, seconds: 27)).millisecondsSinceEpoch,
          },
        ],
        'audio': {
          'muted': false,
          'route': 'speaker',
          'supportedRoutes': ['earpiece', 'speaker'],
        },
      }),
      (_) {},
    );
  }

  testWidgets('export Play Store screenshots', skip: fontPath.isEmpty, (tester) async {
    await loadFonts(tester);

    consumeRecents = true;
    var boundary = await frame(
      tester,
      'Your calls at a glance',
      'Recents grouped by day, with missed calls up top',
      const MainShell(),
    );
    await tester.pumpAndSettle();
    await save(tester, boundary, '1-recents');
    consumeRecents = false;

    consumeDial = '2539';
    boundary = await frame(
      tester,
      'Type a name or number',
      'Smart dialing finds contacts as you type',
      const MainShell(),
    );
    await tester.pumpAndSettle();
    await save(tester, boundary, '2-keypad');
    consumeDial = '';

    boundary = await frame(tester, 'All your contacts', 'Find anyone fast, from A to Z', const MainShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contacts').last);
    await tester.pumpAndSettle();
    await save(tester, boundary, '3-contacts');

    boundary = await frame(
      tester,
      'A call screen that glows',
      'Swipe to answer, in a glow tinted to each caller',
      const InCallScreen(),
      wallpaper: true,
    );
    emit(tester, 'ringing');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await save(tester, boundary, '4-incoming');

    boundary = await frame(
      tester,
      'Everything during a call',
      'Speaker, mute, keypad, hold and more',
      const InCallScreen(),
      wallpaper: true,
    );
    emit(tester, 'active');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await save(tester, boundary, '5-in-call');

    boundary = await frame(
      tester,
      'One Dialer',
      'A clean phone app that glows',
      const InCallScreen(),
      wallpaper: true,
      feature: true,
    );
    emit(tester, 'ringing');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await save(tester, boundary, 'feature-graphic');
    await tester.pumpWidget(const SizedBox());
  });
}

/// The store page around a phone screen: a caption on black with the app's green glow.
class _StoreFrame extends StatelessWidget {
  const _StoreFrame({
    required this.title,
    required this.subtitle,
    required this.wallpaper,
    required this.feature,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool wallpaper;

  /// The 1024 × 500 feature graphic: icon and name on the left, the phone cut off on the right.
  final bool feature;
  final Widget child;

  Widget _phone() => Container(
    width: 420,
    height: 933,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(44),
      border: Border.all(color: const Color(0xFF2C2F33), width: 3),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(44),
      child: DecoratedBox(
        decoration: wallpaper
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2A4A), Color(0xFF3A1F5C), Color(0xFF0E3B33)],
                ),
              )
            : const BoxDecoration(color: Colors.black),
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (feature) return _feature();
    return Material(
      color: Colors.black,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 1.2),
            radius: 1.2,
            colors: [Color(0x662FAE52), Color(0x1A2FAE52), Color(0x002FAE52)],
            stops: [0, .5, 1],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 110),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 68,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 36, color: Color(0xFFB0B4BA)),
            ),
            const SizedBox(height: 80),
            Expanded(
              child: FittedBox(alignment: Alignment.topCenter, child: _phone()),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _feature() => Material(
    color: Colors.black,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.55, .2),
          radius: 1.1,
          colors: [Color(0x552FAE52), Color(0x142FAE52), Color(0x002FAE52)],
          stops: [0, .5, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 72,
            top: 0,
            bottom: 0,
            width: 520,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: solidBody(answerGreen, _iconShape, glow: .45, blur: 40),
                  foregroundDecoration: solidGlow(_iconShape),
                  child: const Icon(Icons.call_rounded, color: Colors.white, size: 88),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 26, color: Color(0xFFB0B4BA), height: 1.3),
                ),
              ],
            ),
          ),
          // The whole phone, tilted a little.
          Positioned(
            right: 110,
            top: 14,
            width: 212,
            height: 471,
            child: Transform.rotate(angle: .06, child: FittedBox(child: _phone())),
          ),
        ],
      ),
    ),
  );

  static const _iconShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32)));
}

/// Play takes only JPEG or 24-bit PNG (no alpha) for screenshots and the feature graphic, and
/// dart:ui's PNG has alpha: encode the opaque frame as RGB.
List<int> _rgbPng(Uint8List rgba, int width, int height) {
  final rows = BytesBuilder();
  for (var y = 0; y < height; y++) {
    rows.addByte(0); // no filter
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      rows.add(rgba.sublist(i, i + 3));
    }
  }
  List<int> chunk(String type, List<int> data) {
    final body = [...type.codeUnits, ...data];
    return [..._u32(data.length), ...body, ..._u32(_crc32(body))];
  }

  return [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    ...chunk('IHDR', [..._u32(width), ..._u32(height), 8, 2, 0, 0, 0]), // 8-bit RGB
    ...chunk('IDAT', ZLibCodec(level: 9).encode(rows.takeBytes())),
    ...chunk('IEND', const []),
  ];
}

List<int> _u32(int v) => [v >> 24 & 0xFF, v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF];

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = crc & 1 == 1 ? 0xEDB88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
