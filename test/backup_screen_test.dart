import 'package:dialer/features/settings/backup_screen.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/widgets/one_ui_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = '/storage/emulated/0/Documents/One Dialer/One Dialer backup.zip';
  final calls = <MethodCall>[];
  var status = <String, Object?>{'interval': 0, 'path': null, 'last': 0, 'failed': false};

  setUp(() {
    calls.clear();
    status = {'interval': 0, 'path': null, 'last': 0, 'failed': false};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.syedarhamraza.dialer/telecom'),
      (call) async {
        calls.add(call);
        switch (call.method) {
          case 'chooseBackupFolder':
            status = {...status, 'path': path};
          case 'setAutoBackup':
            status = {...status, 'interval': (call.arguments as Map)['hours']};
        }
        return status;
      },
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BackupScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('auto backup picks the folder first, then shows its path and frequency', (tester) async {
    await pump(tester);
    expect(find.text('Back up now'), findsOneWidget);
    expect(find.text('Not backed up yet'), findsOneWidget);
    expect(find.text('Frequency'), findsNothing);

    await tester.tap(find.byType(OneUISwitch));
    await tester.pumpAndSettle();
    expect(calls.map((c) => c.method), containsAllInOrder(['chooseBackupFolder', 'setAutoBackup']));
    expect((calls.last.arguments as Map)['hours'], 24);
    expect(find.text(path), findsOneWidget);
    expect(find.text('Every day'), findsOneWidget);
  });

  testWidgets('cancelling the folder pick leaves auto backup off', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.syedarhamraza.dialer/telecom'),
      (call) async {
        calls.add(call);
        return call.method == 'chooseBackupFolder' ? null : status;
      },
    );
    await pump(tester);
    await tester.tap(find.byType(OneUISwitch));
    await tester.pumpAndSettle();
    expect(calls.map((c) => c.method), isNot(contains('setAutoBackup')));
    expect(find.text('Frequency'), findsNothing);
  });

  testWidgets('a failed backup asks for the folder again', (tester) async {
    status = {'interval': 72, 'path': path, 'last': 1, 'failed': true};
    await pump(tester);
    expect(find.text('Every 3 days'), findsOneWidget);
    expect(find.textContaining('The last backup failed'), findsOneWidget);
    expect(find.textContaining('Last backup:'), findsOneWidget);
  });
}
