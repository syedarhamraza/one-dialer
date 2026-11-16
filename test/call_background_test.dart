import 'dart:convert';
import 'dart:io';

import 'package:dialer/features/in_call/call_background.dart';
import 'package:dialer/features/in_call/call_screen_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('CallBackground.parse', () {
    test('reads colours and photo file names', () {
      expect(CallBackground.parse('color:ff2f80ed', '/d')?.colour, const Color(0xFF2F80ED));
      expect(CallBackground.parse('contact:', '/d'), const CallBackground.contactPhoto());
      expect(CallBackground.parse('contact:soft', '/d'), const CallBackground.contactPhoto(soft: true));
      // A contact's own Aurora: not following all calls, yet no colour or photo.
      expect(CallBackground.parse('auto:', '/d'), const CallBackground.auto());
      expect(
        resolveCallBackground(own: const CallBackground.auto(), all: const CallBackground.contactPhoto()),
        const CallBackground.auto(),
      );
      final photo = CallBackground.parse('photo:12-34.jpg', '/d')?.image;
      expect(photo, isA<FileImage>());
      expect((photo! as FileImage).file.path, '/d/12-34.jpg');
      expect(CallBackground.parse('photo:12-34.jpg', '/d')?.soft, isFalse);
      final soft = CallBackground.parse('soft:12-34.jpg', '/d');
      expect(soft?.soft, isTrue);
      expect((soft!.image! as FileImage).file.path, '/d/12-34.jpg');
    });

    test('treats missing and bad values as the default', () {
      for (final bad in [
        null,
        '',
        'color:zz',
        'photo:',
        'photo:../x.jpg',
        'photo:a/b.jpg',
        'soft:',
        'soft:../x.jpg',
        'gradient:1',
      ]) {
        expect(CallBackground.parse(bad, '/d'), isNull, reason: '$bad');
      }
    });
  });

  test("resolveCallBackground: the contact's own choice, else the one for all calls", () {
    const own = CallBackground.colour(Color(0xFFEF4444));
    const all = CallBackground.colour(Color(0xFF22C55E));
    const contactPhoto = CallBackground.contactPhoto();
    final photo = MemoryImage(Uint8List(1));
    expect(resolveCallBackground(own: own, all: all, callerPhoto: photo), own);
    expect(resolveCallBackground(all: all, callerPhoto: photo), all);
    expect(resolveCallBackground(), isNull);
    // "Contact's photo": the caller's photo, or the default tint without one.
    expect(resolveCallBackground(all: contactPhoto, callerPhoto: photo)?.image, photo);
    expect(resolveCallBackground(all: contactPhoto), isNull);
    expect(resolveCallBackground(all: const CallBackground.contactPhoto(soft: true), callerPhoto: photo)?.soft, isTrue);
    expect(resolveCallBackground(own: contactPhoto, all: all), isNull);
    expect(resolveCallBackground(own: own, all: contactPhoto, callerPhoto: photo), own);
  });

  test("photoTones: the main colours, not their average; grey stays grey", () {
    // 16x16: red on the left half, blue on the right.
    final rgba = Uint8List(16 * 16 * 4);
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        final i = (y * 16 + x) * 4;
        rgba.setAll(i, x < 8 ? [220, 30, 30, 255] : [30, 30, 220, 255]);
      }
    }
    final tones = photoTones(rgba, 16, 16).map(HSLColor.fromColor).toList();
    expect(tones, hasLength(5));
    // Both colours show, not their purple-brown average.
    expect(tones.where((t) => t.hue < 1 || t.hue > 359), isNotEmpty);
    expect(tones.where((t) => (t.hue - 240).abs() < 1), isNotEmpty);
    expect(tones.where((t) => t.hue > 20 && t.hue < 220), isEmpty);
    for (final tone in tones) {
      expect(tone.saturation, inInclusiveRange(.499, .621));
    }
    // A small vivid patch on a dull background still shows.
    final patch = Uint8List(16 * 16 * 4);
    for (var i = 0; i < 16 * 16; i++) {
      patch.setAll(i * 4, i < 40 ? [240, 90, 20, 255] : [110, 130, 100, 255]);
    }
    final patchHues = photoTones(patch, 16, 16).map((c) => HSLColor.fromColor(c).hue);
    expect(patchHues.where((h) => h > 10 && h < 40), isNotEmpty);
    final grey = photoTones(Uint8List.fromList(List.filled(4 * 4 * 4, 128)), 4, 4);
    expect(grey.map((c) => HSLColor.fromColor(c).saturation), everyElement(lessThan(.01)));
  });

  testWidgets('CallBackdrop draws a photo background, and the aurora without one or while it decodes', (tester) async {
    Future<void> pump(CallBackground? background) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CallBackdrop(seed: 'Test', background: background, child: const SizedBox.expand()),
      ),
    );
    final photo = find.byWidgetPredicate((w) => w is CustomPaint && '${w.painter.runtimeType}' == '_PhotoPainter');
    await pump(null);
    expect(photo, findsNothing);
    // A 1x1 PNG.
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );
    await pump(CallBackground.image(MemoryImage(png)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(photo, findsOneWidget);
    // Blur & dim: still the one painter, and the photo's tones don't apply over a photo.
    await pump(CallBackground.image(MemoryImage(png), soft: true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(photo, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a picked photo is kept while another background is used, and Photo brings it back', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final dir = await Directory.systemTemp.createTemp('call_bg_test');
    addTearDown(() => dir.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    final backgrounds = CallBackgrounds.instance;
    const scope = 'keep-test';
    await backgrounds.save(scope, photo: Uint8List.fromList([1, 2, 3]), soft: true);
    final picked = backgrounds.stored(scope)!.image! as FileImage;

    // Another choice: the photo's file and its Blur & dim stay, as the kept photo.
    await backgrounds.save(scope, colour: CallBackgrounds.swatches.first);
    expect(backgrounds.stored(scope)?.colour, CallBackgrounds.swatches.first);
    expect(picked.file.existsSync(), isTrue);
    expect(backgrounds.kept(scope), CallBackground.image(picked, soft: true));

    // Photo again: the same photo, no picker.
    expect(await backgrounds.useKeptPhoto(scope), isTrue);
    expect(backgrounds.stored(scope), CallBackground.image(picked, soft: true));

    // A new photo replaces it: the old file goes, Blur & dim stays.
    await backgrounds.save(scope, auto: true);
    await backgrounds.save(scope, photo: Uint8List.fromList([4]));
    expect(picked.file.existsSync(), isFalse);
    expect(backgrounds.stored(scope)?.soft, isTrue);
    expect(dir.listSync(recursive: true).whereType<File>(), hasLength(1));
  });
}
