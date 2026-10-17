import 'package:dialer/features/keypad/whatsapp_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('com.syedarhamraza.dialer/telecom');
  const app = {'package': 'com.whatsapp', 'label': 'WhatsApp'};
  const business = {'package': 'com.whatsapp.w4b', 'label': 'WhatsApp Business'};
  final calls = <MethodCall>[];
  Map<String, Object?> discovery = {};
  bool launchFails = false;
  setUp(() {
    calls.clear();
    launchFails = false;
    discovery = {
      'apps': [app],
      'actions': [],
      'hasContactsPermission': true,
      'internationalNumber': '+923331234567',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getWhatsAppCalls') return discovery;
      if (call.method == 'startWhatsAppCall' && launchFails) throw PlatformException(code: 'FAILED');
      return null;
    });
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openWhatsAppVoiceCall(context, '03331234567'),
              child: const Text('WhatsApp'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
  }

  test('service codes and pause/wait are not WhatsApp numbers', () {
    for (final number in ['', '+', '*123#', '123,4', '123;4']) {
      expect(isWhatsAppNumber(number), isFalse);
    }
    expect(isWhatsAppNumber('+92 (333) 1234567'), isTrue);
  });
  testWidgets('single available action hands off exact number', (tester) async {
    discovery['actions'] = [app];
    await open(tester);
    expect(calls.last.method, 'startWhatsAppCall');
    expect(calls.last.arguments, {'number': '03331234567', 'package': 'com.whatsapp'});
  });
  testWidgets('both apps require a choice before launching', (tester) async {
    discovery['apps'] = [app, business];
    discovery['actions'] = [app, business];
    await open(tester);
    expect(calls.length, 1);
    await tester.tap(find.text('WhatsApp Business'));
    await tester.pumpAndSettle();
    expect(calls.last.arguments['package'], 'com.whatsapp.w4b');
  });
  testWidgets('fallback opens chat only after user selects it', (tester) async {
    await open(tester);
    expect(calls.length, 1);
    await tester.tap(find.text('Open WhatsApp chat'));
    await tester.pumpAndSettle();
    expect(calls.last.method, 'openWhatsAppChat');
    expect(calls.last.arguments['number'], '+923331234567');
  });
  testWidgets('unknown country code requires international input', (tester) async {
    discovery['internationalNumber'] = null;
    await open(tester);
    await tester.tap(find.text('Open WhatsApp chat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '03331234567');
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
    expect(calls.length, 1);
    expect(find.text('Enter +, country code, and phone number'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '+923331234567');
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
    expect(calls.last.method, 'openWhatsAppChat');
  });
  testWidgets('missing permission explains why direct calling is unavailable', (tester) async {
    discovery['hasContactsPermission'] = false;
    await open(tester);
    expect(find.textContaining('Contacts access is needed'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls.length, 1);
  });
  testWidgets('missing app produces a message', (tester) async {
    discovery['apps'] = [];
    await open(tester);
    expect(find.text('WhatsApp is not installed.'), findsOneWidget);
  });
  testWidgets('stale call action offers chat instead of failing silently', (tester) async {
    discovery['actions'] = [app];
    launchFails = true;
    await open(tester);
    expect(find.text('WhatsApp calling unavailable'), findsOneWidget);
    expect(calls.where((call) => call.method == 'openWhatsAppChat'), isEmpty);
  });
}
