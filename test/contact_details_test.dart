import 'dart:io';
import 'dart:ui' as ui;

import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/contacts/contact_details_screen.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/recents/call_log_repository.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      if (call.method == 'getSims' || call.method == 'getMessagingApps') return [];
      return null;
    });
    ContactsRepository.instance.contacts.value = const [
      DialerContact(id: '7', name: 'Wasif', numbers: ['03111234567', '03001234567'], labels: ['Mobile', 'Work']),
    ];
  });
  tearDown(() {
    ContactsRepository.instance.contacts.value = [];
    CallLogRepository.instance.calls.value = const [];
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        home: const ContactDetailsScreen(contactId: '7'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the top-bar buttons, Call and Message tiles and numbers', (tester) async {
    await pump(tester);
    for (final tip in ['Back', 'Add to favourites', 'Edit', 'More options']) {
      expect(find.byTooltip(tip), findsOneWidget, reason: tip);
    }
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('03111234567'), findsOneWidget);
    expect(find.text('03001234567'), findsOneWidget);
    expect(find.text('Ringtone'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Storage locations'), 200);
    expect(find.text('Storage locations'), findsOneWidget); // on the page, not in More
    expect(find.text('Call logs'), findsNothing); // no calls yet
  });

  testWidgets('Video is greyed out without Meet and opens Meet when the contact has it', (tester) async {
    await pump(tester);
    final video = find.widgetWithText(DetailsActionTile, 'Video');
    expect(tester.widget<DetailsActionTile>(video).onTap, isNull);

    final opened = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.syedarhamraza.dialer/telecom'),
      (call) async {
        opened.add(call);
        return switch (call.method) {
          'getMessagingApps' => [
            {
              'label': 'Meet',
              'dataId': 5,
              'mimeType': 'vnd.android.cursor.item/com.google.android.apps.tachyon.phone.meet',
            },
          ],
          'getSims' => [],
          _ => null,
        };
      },
    );
    await pump(tester);
    await tester.pumpWidget(const SizedBox()); // a fresh page loads the new apps
    await pump(tester);
    await tester.tap(video);
    expect(opened.where((c) => c.method == 'openContactData').single.arguments['dataId'], 5);
    expect(find.text('Meet'), findsNothing); // the Video tile, not a chat-app row
  });

  testWidgets('lists the latest three calls with View all', (tester) async {
    CallLogRepository.instance.calls.value = [
      for (var i = 0; i < 5; i++)
        CallLogEntry(id: i, number: '+92 311 1234567', type: CallType.outgoing, date: DateTime(2026, 10, 1 + i)),
      CallLogEntry(id: 9, number: '0399999999', type: CallType.missed, date: DateTime(2026, 10, 9)),
    ];
    await pump(tester);
    await tester.scrollUntilVisible(find.text('View all'), 200);
    expect(find.text('Call logs'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
    expect(find.textContaining('+92 311 1234567', findRichText: true), findsNWidgets(3));
    expect(find.textContaining('0399999999', findRichText: true), findsNothing);
  });

  const fontPath = String.fromEnvironment('PREVIEW_FONT');
  if (fontPath.isNotEmpty) {
    testWidgets('render contact details preview', (tester) async {
      await tester.runAsync(() async {
        for (final (family, file) in [
          ('Roboto', fontPath),
          ('MaterialIcons', '${File(fontPath).parent.path}/materialicons-regular.otf'),
        ]) {
          await (FontLoader(family)..addFont(File(file).readAsBytes().then(ByteData.sublistView))).load();
        }
      });
      tester.view.physicalSize = const Size(420, 933);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      CallLogRepository.instance.calls.value = [
        CallLogEntry(
          id: 1,
          number: '03111234567',
          type: CallType.outgoing,
          date: DateTime(2026, 10, 19, 9, 30),
          duration: const Duration(minutes: 3),
        ),
        CallLogEntry(id: 2, number: '03001234567', type: CallType.missed, date: DateTime(2026, 10, 18, 21, 5)),
      ];
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OneUITheme.darkTheme,
          home: RepaintBoundary(
            key: boundary,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(420, 933), padding: EdgeInsets.only(top: 24, bottom: 16)),
              child: const ContactDetailsScreen(contactId: '7'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(
          pixelRatio: 2,
        );
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/contact-details-preview.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
