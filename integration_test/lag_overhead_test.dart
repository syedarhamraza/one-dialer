import 'dart:async';
import 'dart:ui';

import 'package:dialer/core/diagnostics/lag_diagnostics.dart';
import 'package:dialer/core/diagnostics/lag_metrics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('profile overhead on a fixed animation', (tester) async {
    expect(kProfileMode, true);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Animation())));
    final results = <Map<String, Object>>[];
    await tester.runAsync(() async {
      for (final enabled in [false, true, false, true]) {
        final monitor = LagDiagnostics(upload: (_) async {});
        await monitor.start(engine: 'main', enabled: enabled);
        await Future<void>.delayed(const Duration(seconds: 6));
        final metrics = LagMetrics();
        void collect(List<FrameTiming> frames) {
          for (final frame in frames) {
            metrics.add(frame.buildDuration.inMicroseconds / 1000, frame.rasterDuration.inMicroseconds / 1000);
          }
        }
        WidgetsBinding.instance.addTimingsCallback(collect);
        await Future<void>.delayed(const Duration(seconds: 10));
        WidgetsBinding.instance.removeTimingsCallback(collect);
        results.add({'enabled': enabled, ...metrics.summary()});
        monitor.dispose();
      }
    });
    binding.reportData = {'scenario': 'fixed_rotation', 'runs': results};
  }, timeout: const Timeout(Duration(minutes: 3)));
}

class _Animation extends StatefulWidget {
  const _Animation();
  @override
  State<_Animation> createState() => _AnimationState();
}

class _AnimationState extends State<_Animation> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Center(child: RotationTransition(
    turns: _controller,
    child: const SizedBox(width: 120, height: 120, child: ColoredBox(color: Colors.green)),
  ));
}
