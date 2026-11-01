import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/in_call/call_controls.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/call_glass.dart';
import 'package:dialer/widgets/one_ui_glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../integration_test/perf_test.dart' show summarize;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final prefs = DialerPrefs.instance;

  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
  tearDown(() {
    prefs.visualEffects.value = 'full';
    prefs.callEffects.value = 'full';
    prefs.glassDark.value = 'soft';
    prefs.glassLight.value = 'soft';
  });

  test('glass styles are saved, reloaded, and unknown values are ignored', () async {
    await prefs.setGlassDark('soft');
    await prefs.setGlassLight('classic');
    prefs.glassDark.value = 'bold';
    prefs.glassLight.value = 'bold';
    await prefs.loadAppearance();
    expect(prefs.glassDark.value, 'soft');
    expect(prefs.glassLight.value, 'classic');

    await prefs.setGlassLight('fancy');
    prefs.glassLight.value = 'bold';
    await prefs.loadAppearance();
    expect(prefs.glassLight.value, 'bold');
  });

  testWidgets('each glass style resolves to its look in each theme', (tester) async {
    Future<({double opacity, GlassEdges edges})> look(Brightness brightness, {double classic = 1}) async {
      late ({double opacity, GlassEdges edges}) result;
      await tester.pumpWidget(
        // A plain Theme: MaterialApp would animate between brightnesses.
        Theme(
          data: ThemeData(brightness: brightness),
          child: Builder(
            builder: (context) {
              result = mainGlass(context, classicOpacity: classic);
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    prefs.glassDark.value = 'classic';
    expect(await look(Brightness.dark, classic: .75), (opacity: .75, edges: GlassEdges.callScreen));
    prefs.glassDark.value = 'soft';
    expect(await look(Brightness.dark), (opacity: .5, edges: const GlassEdges(strength: 2)));
    prefs.glassDark.value = 'bold';
    expect(await look(Brightness.dark), (opacity: .5, edges: const GlassEdges(strength: 3, bottomLip: 3, lip: 2)));
    prefs.glassLight.value = 'classic';
    expect(await look(Brightness.light), (opacity: 1.0, edges: GlassEdges.callScreen));
  });

  test('the level is saved, reloaded, and unknown values are ignored', () async {
    await prefs.setVisualEffects('reduced');
    prefs.visualEffects.value = 'full';
    await prefs.loadAppearance();
    expect(prefs.visualEffects.value, 'reduced');

    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({'visual_effects': 'fancy'});
    await prefs.loadAppearance();
    expect(prefs.visualEffects.value, 'reduced');
  });

  test('low-end phones default to reduced until a level is saved', () async {
    const channel = MethodChannel('com.syedarhamraza.dialer/telecom');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async => call.method == 'isLowEndDevice');
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await prefs.loadAppearance();
    await prefs.loadCallEffects();
    expect((prefs.visualEffects.value, prefs.callEffects.value), ('reduced', 'reduced'));

    await prefs.setVisualEffects('full');
    await prefs.setCallEffects('full');
    await prefs.loadAppearance();
    await prefs.loadCallEffects();
    expect((prefs.visualEffects.value, prefs.callEffects.value), ('full', 'full'));
  });

  test('each level is told apart in one place', () {
    final fx = OneUIEffectsController.instance;
    for (final (level, full, off) in [('full', true, false), ('reduced', false, false), ('off', false, true)]) {
      prefs.visualEffects.value = level;
      expect((fx.isFull, fx.isOff), (full, off), reason: level);
    }
  });

  testWidgets('glass switches live: call glass, One UI fill over a blur, then solid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: BackdropGroup(
          child: Column(
            children: [
              const SizedBox(width: 48, height: 48, child: CallGlass(child: SizedBox())),
              OneUIGlassSurface(width: 120, height: 48, child: const SizedBox()),
            ],
          ),
        ),
      ),
    );
    final fx = OneUIEffectsController.instance;
    Finder oneUI(Color c) => find.byWidgetPredicate((w) => w is ColoredBox && w.color == c);
    expect(find.byType(BackdropFilter), findsNWidgets(2));
    expect(oneUI(fx.floatingColor), findsNothing);

    prefs.visualEffects.value = 'reduced';
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNWidgets(2));
    expect(oneUI(fx.floatingColor), findsOneWidget);

    prefs.visualEffects.value = 'off';
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(oneUI(fx.floatingColor.withValues(alpha: 1)), findsOneWidget);
  });

  test('the benchmark counts frames over the display budget', () {
    Duration ms(int v) => Duration(milliseconds: v);
    final frames = [
      for (final v in [2, 4, 6, 9, 20]) (ms(v), ms(v), ms(v)),
    ];
    final at120 = summarize(frames, 120);
    expect(at120['jankyRaster'], 2); // 9 and 20 ms are over 8.33
    expect(summarize(frames, 60)['jankyBuild'], 1);
    expect((at120['raster']! as Map)['p50'], 6);
    expect((at120['raster']! as Map)['max'], 20);
  });

  testWidgets('the call screen follows its own setting, live', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: CallEffects(
          child: const SizedBox.square(dimension: 60, child: CallFrost(radius: null, child: SizedBox())),
        ),
      ),
    );
    Finder fill(Color c) => find.byWidgetPredicate(
      (w) => w is DecoratedBox && w.decoration is ShapeDecoration && (w.decoration as ShapeDecoration).color == c,
    );
    expect(find.byType(CallBodyArtwork), findsOneWidget);

    // The app's own setting doesn't touch the call screen.
    prefs.visualEffects.value = 'off';
    await tester.pump();
    expect(find.byType(CallBodyArtwork), findsOneWidget);

    prefs.callEffects.value = 'reduced';
    await tester.pump();
    expect(find.byType(CallBodyArtwork), findsNothing);
    expect(fill(callFrostFill), findsOneWidget);

    prefs.callEffects.value = 'off';
    await tester.pump();
    expect(fill(callSolidFill), findsOneWidget);
    expect(glassBody(const Color(0xFF2FAE52), const CircleBorder(), flat: true).shadows, isNull);
  });
}
