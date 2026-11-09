import 'dart:convert';
import 'dart:typed_data';

import 'package:dialer/features/in_call/call_background.dart';
import 'package:dialer/features/in_call/call_screen_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallBackground.parse', () {
    test('reads colours and photo file names', () {
      expect(CallBackground.parse('color:ff2f80ed', '/d')?.colour, const Color(0xFF2F80ED));
      expect(CallBackground.parse('contact:', '/d'), const CallBackground.contactPhoto());
      final photo = CallBackground.parse('photo:12-34.jpg', '/d')?.image;
      expect(photo, isA<FileImage>());
      expect((photo! as FileImage).file.path, '/d/12-34.jpg');
    });

    test('treats missing and bad values as the default', () {
      for (final bad in [null, '', 'color:zz', 'photo:', 'photo:../x.jpg', 'photo:a/b.jpg', 'gradient:1']) {
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
    expect(resolveCallBackground(own: contactPhoto, all: all), isNull);
    expect(resolveCallBackground(own: own, all: contactPhoto, callerPhoto: photo), own);
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
  });
}
