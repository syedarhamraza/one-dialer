import 'dart:async';

import 'package:dialer/app/main_shell.dart';
import 'package:dialer/core/contacts/contacts_repository.dart';
import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/blocking/blocking_repository.dart';
import 'package:dialer/features/blocking/blocking_screen.dart';
import 'package:dialer/features/contacts/contact_picker_screen.dart';
import 'package:dialer/features/keypad/keypad_screen.dart';
import 'package:dialer/features/recents/call_details_screen.dart';
import 'package:dialer/features/recents/call_log.dart';
import 'package:dialer/features/recents/call_log_repository.dart';
import 'package:dialer/features/recents/recents_screen.dart';
import 'package:dialer/features/search/search_screen.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/one_ui_subpage.dart';
import 'package:dialer/widgets/round_header_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final native = <MethodCall>[];
  final repo = CallLogRepository.instance;
  Completer<void>? deletion;
  CallLogEntry call(int id, String number, {bool private = false, CallType type = CallType.incoming}) =>
      CallLogEntry(id: id, number: number, type: type, isPrivate: private, date: DateTime(2026, 10, 23));
  setUp(() {
    deletion = null;
    native.clear();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    ContactsRepository.instance.debugSetContacts([
      DialerContact(id: 'a', name: 'Alice', numbers: const ['111'], labels: const ['Mobile']),
      DialerContact(id: 'b', name: 'Bob', numbers: const ['222'], labels: const ['Mobile']),
    ]);
    BlockingRepository.instance.numbers.value = [];
    repo.calls.value = [];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in ['flutter_contacts', 'com.syedarhamraza.dialer/call_state']) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }
    messenger.setMockMethodCallHandler(const MethodChannel('com.syedarhamraza.dialer/telecom'), (c) async {
      native.add(c);
      if (c.method == 'deleteCalls') await deletion?.future;
      if (c.method == 'getBlocking') return <String, Object>{};
      return null;
    });
  });
  tearDown(() {
    repo.calls.value = [];
    ContactsRepository.instance.debugSetContacts([]);
    BlockingRepository.instance.numbers.value = [];
    navDock.value = null;
  });
  Future<void> open(WidgetTester tester, Widget screen, {bool reduced = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: OneUITheme.darkTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: Scaffold(body: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in DialerPrefs.displaySizes) {
    testWidgets('the Calls header pills stay on screen, apart and tappable at top buttons size $size', (tester) async {
      // The vivo's width, where the pills have the least room once they grow.
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      DialerPrefs.instance.headerSize.value = size;
      addTearDown(() => DialerPrefs.instance.headerSize.value = 1);
      repo.calls.value = [for (var i = 0; i < 30; i++) call(i, '9$i')];
      await open(tester, const RecentsScreen());
      final screen = tester.getRect(find.byType(RecentsScreen));
      final tabs = tester.getRect(find.byType(FilterTabs));
      for (final tip in ['Search', 'More options']) {
        final rect = tester.getRect(find.byTooltip(tip));
        expect(screen.contains(rect.topLeft) && screen.contains(rect.bottomRight), isTrue, reason: '$tip at $rect');
        expect(rect.overlaps(tabs), isFalse, reason: '$tip at $rect, tabs at $tabs');
      }
      // Scrolled, the small title shows only where the tabs leave it room.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final title = find.descendant(of: find.byType(HeaderTitle), matching: find.byType(Text));
      if (title.evaluate().isNotEmpty) {
        expect(tester.getRect(title).right, lessThan(tabs.left), reason: 'title under the tabs at $size');
      }
      // The test font draws every letter as a wide square, so only the smallest size leaves room for it.
      if (size == DialerPrefs.displaySizes.first) expect(title, findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
    });
  }

  for (final size in [DialerPrefs.displaySizes.first, DialerPrefs.displaySizes.last]) {
    testWidgets("a page's Back button follows top buttons size $size, not the App size", (tester) async {
      DialerPrefs.instance.headerSize.value = size;
      DialerPrefs.instance.displaySize.value = 1.3;
      addTearDown(() => DialerPrefs.instance.headerSize.value = DialerPrefs.instance.displaySize.value = 1);
      await open(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OneUISubpage(title: 'Page', builder: (_) => const []),
              ),
            ),
            child: const Text('Go'),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      // Painted size: 48 dp times the slider, with the App size divided back out.
      final rect = tester.getRect(find.byTooltip('Back'));
      expect(rect.width, moreOrLessEquals(48 * size / 1.3, epsilon: .5));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Page'), findsNothing);
    });
  }

  testWidgets('Calls search opens a page and Cancel closes it', (tester) async {
    await open(tester, const RecentsScreen());
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('both blocking search and picker filter locally and clear on Cancel or Back', (tester) async {
    BlockingRepository.instance.numbers.value = ['111', '222'];
    for (final page in [const BlockingScreen(), const ContactPickerScreen(title: 'Block contact')]) {
      await open(tester, page);
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      await tester.enterText(find.byType(TextField), '222');
      await tester.pumpAndSettle();
      expect(find.text('Bob'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Alice'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Alice'), findsOneWidget);
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Alice'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('hide blocked calls follows block-list changes and saved menu choice', (tester) async {
    repo.calls.value = [call(1, '111'), call(2, '222', type: CallType.blocked), call(3, '333')];
    await open(tester, const RecentsScreen());
    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
    BlockingRepository.instance.numbers.value = ['111'];
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Alice'), findsNothing);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show blocked calls'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(await DialerPrefs.instance.hideBlockedCalls(), false);
    await tester.pumpWidget(const SizedBox());
    await open(tester, const RecentsScreen());
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('Calls confirmation preserves selection on cancel and deletes group immediately on confirm', (
    tester,
  ) async {
    repo.calls.value = [call(1, '333'), call(2, '333')];
    deletion = Completer<void>();
    await open(tester, const MainShell());
    tester.widget<KeypadScreen>(find.byType(KeypadScreen)).open.value = false;
    await tester.pumpAndSettle();
    await tester.longPress(find.text('333 (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(native.where((c) => c.method == 'deleteCalls'), isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(repo.calls.value, isEmpty);
    expect(native.singleWhere((c) => c.method == 'deleteCalls').arguments, {
      'ids': [1, 2],
    });
    deletion!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('private call deletion targets just one record', (tester) async {
    final private = call(1, '', private: true, type: CallType.blocked);
    repo.calls.value = [private, call(2, '', private: true, type: CallType.blocked)];
    deletion = Completer<void>();
    await open(tester, CallDetailsScreen(call: private));
    await tester.tap(find.byTooltip('Delete call history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repo.calls.value.map((c) => c.id), [2]);
    expect(native.singleWhere((c) => c.method == 'deleteCalls').arguments, {
      'ids': [1],
    });
    deletion!.complete();
    await tester.pumpAndSettle();
  });
}
