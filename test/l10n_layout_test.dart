import 'dart:io';
import 'dart:ui' as ui;

import 'package:dialer/app/layout.dart';
import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/features/blocking/blocking_screen.dart';
import 'package:dialer/features/contacts/contacts_screen.dart';
import 'package:dialer/features/contacts/manage_contacts_screen.dart';
import 'package:dialer/features/in_call/in_call_screen.dart';
import 'package:dialer/features/keypad/keypad_screen.dart';
import 'package:dialer/features/keypad/speed_dial_screen.dart';
import 'package:dialer/features/recents/recents_screen.dart';
import 'package:dialer/features/recordings/recordings_screen.dart';
import 'package:dialer/features/settings/about_screen.dart';
import 'package:dialer/features/settings/backup_screen.dart';
import 'package:dialer/features/settings/call_background_screen.dart';
import 'package:dialer/features/settings/call_recording_screen.dart';
import 'package:dialer/features/settings/call_settings_pages.dart';
import 'package:dialer/features/settings/dialing_settings_screen.dart';
import 'package:dialer/features/settings/display_settings_screen.dart';
import 'package:dialer/features/settings/glass_settings_screen.dart';
import 'package:dialer/features/settings/help_feedback_screen.dart';
import 'package:dialer/features/settings/quick_replies_screen.dart';
import 'package:dialer/features/settings/settings_screen.dart';
import 'package:dialer/features/settings/vip_calls_screen.dart';
import 'package:dialer/features/setup/setup_screen.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'real_font.dart';

/// Every page in every language on a tall (360×780) and a short (320×640) phone, laid out as the
/// app is at 420 dp and scaled, in a real
/// font (Roboto from the Flutter SDK, which covers Cyrillic and Turkish), so a long German or
/// Russian label that overflows fails here. `--dart-define=L10N_PREVIEWS=true` also writes each
/// page to `build/l10n-previews/<locale>/` to look at clipped or crowded labels.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const previews = bool.fromEnvironment('L10N_PREVIEWS');
  const events = 'com.syedarhamraza.dialer/call_state';

  setUpAll(loadRealFont);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(events), (_) async => null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (_) async => 1, // granted
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (call) async {
      if (call.method.startsWith('permissions.')) return 'granted';
      return null;
    });
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      return switch (call.method) {
        'getSims' => [
          {'id': 'a', 'label': 'SIM 1'},
          {'id': 'b', 'label': 'SIM 2'},
        ],
        'getBlocking' || 'getCallSettings' => <String, Object?>{},
        'getRecorderSettings' => <String, Object?>{'retentionDays': 0},
        'getQuickReplies' => ['0300 1234567'],
        'hasScreeningRole' || 'canMeetCall' => false,
        'listRecordings' => <Object?>[],
        'formatAsYouType' => (call.arguments as Map)['number'],
        _ => null,
      };
    });
    ContactsRepository.instance.contacts.value = [
      for (var i = 0; i < 6; i++)
        DialerContact(id: '$i', name: 'Contact $i', numbers: ['030012345$i$i'], labels: const ['Mobile']),
    ];
  });
  tearDown(() => ContactsRepository.instance.contacts.value = []);

  final pages = <String, Widget Function()>{
    'setup': () => SetupScreen(onDone: () {}),
    'keypad': () => Scaffold(body: KeypadScreen(open: ValueNotifier(true), input: ValueNotifier('0300'))),
    'recents': () => const Scaffold(body: RecentsScreen()),
    'contacts': () => const Scaffold(body: ContactsScreen()),
    'settings': () => const SettingsScreen(),
    'display': () => const DisplaySettingsScreen(),
    'glass': () => const GlassSettingsScreen(),
    'dialing': () => const DialingSettingsScreen(),
    'sims': () => const SimSettingsScreen(),
    'keypad-settings': () => const KeypadSettingsScreen(),
    'incoming': () => const IncomingCallRemindersScreen(),
    'answer-buttons': () => const AnswerButtonsScreen(),
    'answer-end': () => const AnswerEndCallsScreen(),
    'call-background': () => const CallBackgroundScreen(scope: 'all'),
    'quick-replies': () => const QuickRepliesScreen(),
    'vip': () => const VipCallsScreen(),
    'blocking': () => const BlockingScreen(),
    'recording': () => const CallRecordingScreen(),
    'recordings': () => const RecordingsScreen(),
    'language': () => const LanguageScreen(),
    'contacts-settings': () => const ContactsSettingsScreen(),
    'manage-contacts': () => const ManageContactsScreen(),
    'speed-dial': () => const SpeedDialScreen(),
    'backup': () => const BackupScreen(),
    'help': () => const HelpFeedbackScreen(),
    'about': () => const AboutScreen(),
    'call-active': () => const InCallScreen(),
    'call-ringing': () => const InCallScreen(),
  };

  Future<void> emitCall(WidgetTester tester, String state) async {
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      events,
      const StandardMethodCodec().encodeSuccessEnvelope({
        'calls': [
          {
            'id': 'call-1',
            'state': state,
            'number': '03001234567',
            'name': 'Alex Morgan',
            'simId': 'b',
            'isHd': true,
            'connectTimeMillis': DateTime.now().millisecondsSinceEpoch,
          },
        ],
        'audio': {
          'muted': false,
          'route': 'earpiece',
          'supportedRoutes': ['earpiece', 'speaker', 'bluetooth'],
        },
      }),
      (_) {},
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final locale in AppLocalizations.supportedLocales) {
    for (final size in const [Size(360, 780), Size(320, 640)]) {
      for (final MapEntry(key: name, value: page) in pages.entries) {
        testWidgets('${locale.languageCode} $name fits at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: OneUITheme.darkTheme,
              scrollBehavior: OneUITheme.scrollBehavior,
              // As both engines do: laid out at the vivo's 420 dp and scaled to the screen.
              builder: (context, child) => DesignWidth(child: child!),
              home: RepaintBoundary(key: boundary, child: page()),
            ),
          );
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
          if (name.startsWith('call-')) await emitCall(tester, name == 'call-active' ? 'active' : 'ringing');
          if (previews && size.width == 360) {
            await tester.runAsync(() async {
              final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
              final png = await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File('build/l10n-previews/${locale.languageCode}/$name.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(png!.buffer.asUint8List());
              image.dispose();
            });
          }
          expect(tester.takeException(), isNull);
          // Leave no timers running between pages.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        });
      }
    }
  }
}
