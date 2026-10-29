import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/theme/one_ui_theme.dart';
import 'package:dialer/widgets/call_glass.dart';
import 'package:dialer/widgets/one_ui_glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../integration_test/perf_test.dart' show summarize;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final prefs = DialerPrefs.instance;

  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
  tearDown(() => prefs.visualEffects.value = 'full');

  test('the level is saved, reloaded, and unknown values are ignored', () async {
    await prefs.setVisualEffects('reduced');
    prefs.visualEffects.value = 'full';
    await prefs.loadAppearance();
    expect(prefs.visualEffects.value, 'reduced');

    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({'visual_effects': 'fancy'});
    await prefs.loadAppearance();
    expect(prefs.visualEffects.value, 'reduced');
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
}
