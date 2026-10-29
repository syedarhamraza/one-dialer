import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/features/contacts/contacts_widgets.dart';
import 'package:dialer/main.dart' as app;
import 'package:dialer/widgets/one_ui_floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Frame timings for each Settings › "Reduce visual effects" level, on a real phone in a
/// profile build. Run it as docs/performance.md says; results land in build/perf/.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Real frames at the display's rate, not the test's own pumps.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('frame timings per visual-effects level', (tester) async {
    app.main();
    await _settle(tester);
    final prefs = DialerPrefs.instance;
    final saved = prefs.visualEffects.value;
    final hz = tester.view.display.refreshRate;
    final results = <String, Object>{'refreshRate': hz};

    try {
      for (final level in const ['full', 'reduced', 'off']) {
        await prefs.setVisualEffects(level);
        await _settle(tester);
        final scenarios = <String, Object>{};
        Future<void> measure(String name, Future<void> Function() run) async {
          scenarios[name] = await _timed(hz, run);
        }

        final nav = find.byType(OneUIFloatingNavBar);
        Finder tab(IconData icon) => find.descendant(of: nav, matching: find.byIcon(icon));

        // The keypad opens with the app; hide it to reach the list.
        await _back(tester);
        await measure('calls_scroll', () => _flings(tester, find.byType(CustomScrollView).first));
        await measure('call_details', () async {
          await tester.tap(find.byTooltip('Call details').first);
          await _settle(tester);
          await _back(tester);
        });
        await measure('menu', () async {
          await tester.tap(find.byTooltip('More options'));
          await _settle(tester);
          await _back(tester);
        });
        await measure('keypad', () async {
          await tester.tap(find.byTooltip('Show keypad'));
          await _settle(tester);
          await _back(tester);
        });
        await measure('to_contacts', () async {
          await tester.tap(tab(Icons.people_alt_outlined));
          await _settle(tester);
        });
        await measure('contacts_scroll', () => _flings(tester, find.byType(CustomScrollView).last));
        await measure('contact_details', () async {
          await tester.tap(find.byType(ContactRow).first);
          await _settle(tester);
          await _back(tester);
        });
        await measure('to_calls', () async {
          await tester.tap(tab(Icons.call_outlined));
          await _settle(tester);
        });
        // Back to the launch state for the next level.
        await tester.tap(find.byTooltip('Show keypad'));
        await _settle(tester);
        results[level] = scenarios;
      }
    } finally {
      await prefs.setVisualEffects(saved);
    }
    binding.reportData = results;
  });
}

/// Six flings down, six back up.
Future<void> _flings(WidgetTester tester, Finder list) async {
  for (final dy in [for (var i = 0; i < 6; i++) -600.0, for (var i = 0; i < 6; i++) 600.0]) {
    await tester.fling(list, Offset(0, dy), 2500);
    await _settle(tester);
  }
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _settle(tester);
}

// Springs and the keypad slide finish well inside this; pumpAndSettle would wait on
// repeating animations.
Future<void> _settle(WidgetTester tester) => tester.pump(const Duration(milliseconds: 900));

/// Runs [run] and summarizes the frames it drew against the display's frame budget.
Future<Map<String, Object>> _timed(double hz, Future<void> Function() run) async {
  final frames = <FrameTiming>[];
  void collect(List<FrameTiming> timings) => frames.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collect);
  await run();
  // Timings arrive in batches; let the last one in.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  return summarize(frames.map((f) => (f.buildDuration, f.rasterDuration, f.totalSpan)).toList(), hz);
}

/// p50/p90/p95/p99 of build, raster and total ms, and the frames over budget (1000 / [hz] ms).
@visibleForTesting
Map<String, Object> summarize(List<(Duration, Duration, Duration)> frames, double hz) {
  final budget = 1000 / hz;
  Map<String, double> percentiles(Iterable<Duration> values) {
    final ms = [for (final v in values) v.inMicroseconds / 1000]..sort();
    double at(double p) => ms.isEmpty ? 0 : ms[((ms.length - 1) * p).round()];
    return {'p50': at(.5), 'p90': at(.9), 'p95': at(.95), 'p99': at(.99), 'max': at(1)};
  }

  return {
    'frames': frames.length,
    'budgetMs': budget,
    'build': percentiles(frames.map((f) => f.$1)),
    'raster': percentiles(frames.map((f) => f.$2)),
    'total': percentiles(frames.map((f) => f.$3)),
    'jankyBuild': frames.where((f) => f.$1.inMicroseconds / 1000 > budget).length,
    'jankyRaster': frames.where((f) => f.$2.inMicroseconds / 1000 > budget).length,
  };
}
