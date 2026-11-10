import 'package:dialer/l10n/app_localizations.dart';
import 'package:dialer/widgets/place_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a call Android refuses says so instead of doing nothing', (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    const channel = MethodChannel('com.syedarhamraza.dialer/telecom');
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'placeCall' || call.method == 'callBack') throw PlatformException(code: 'NO_PERMISSION');
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    late BuildContext page;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            page = context;
            return const Scaffold();
          },
        ),
      ),
    );

    // A SIM is named, so no contact or SIM lookup runs first.
    expect(await tester.runAsync(() => placeCall(page, '0300 1234567', simId: 'sim1')), isFalse);
    await tester.pump();
    expect(find.text("Couldn't place the call"), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // the toast leaves by itself
    await tester.pumpAndSettle();

    expect(await tester.runAsync(() => callBackRow(page, 7)), isFalse);
    await tester.pump();
    expect(find.text("Couldn't place the call"), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
