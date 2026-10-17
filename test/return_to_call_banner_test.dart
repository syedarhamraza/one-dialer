import 'package:dialer/app/return_to_call_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const events = 'com.syedarhamraza.dialer/call_state';
  final nativeCalls = <MethodCall>[];

  setUp(() {
    nativeCalls.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(events), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_contacts'), (_) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (call) async {
      nativeCalls.add(call);
      return null;
    });
  });

  Future<void> emit(WidgetTester tester, List<Map<String, Object?>> calls) async {
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      events,
      const StandardMethodCodec().encodeSuccessEnvelope({'calls': calls}),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  Map<String, Object?> call(String state) => {
    'id': 'call-1',
    'state': state,
    'number': '5550100',
    'name': 'Alex Morgan',
    'connectTimeMillis': DateTime.now().subtract(const Duration(seconds: 5)).millisecondsSinceEpoch,
  };

  testWidgets('shows for an ongoing call, returns to it on tap, hides when calls end', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ReturnToCallBanner())));
    expect(find.bySemanticsLabel('Return to call'), findsNothing);

    await emit(tester, [call('ringing')]);
    expect(find.bySemanticsLabel('Return to call'), findsNothing);

    await emit(tester, [call('active')]);
    expect(find.bySemanticsLabel('Return to call'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('00:05'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Return to call'));
    expect(nativeCalls.map((c) => c.method), contains('showInCallScreen'));

    await emit(tester, []);
    expect(find.bySemanticsLabel('Return to call'), findsNothing);
    semantics.dispose();
  });
}
