import 'package:dialer/core/diagnostics/lag_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects completed slow frames, retaining bounded percentiles', () {
    final metrics = LagMetrics();
    expect(metrics.add(699, 1), false);
    expect(metrics.add(1, 700), true);
    for (var i = 0; i < 700; i++) {
      metrics.add(4, 8);
    }
    final summary = metrics.summary();
    expect(summary['frames'], 600);
    expect(summary['buildP95Ms'], 4);
    expect(summary['rasterP95Ms'], 8);
    expect(summary['rasterMaxMs'], 8);
  });

  test('render stall needs a frame requested and none drawn for 3 s', () {
    expect(renderStalled(now: 9000, pendingSince: null, lastFrameAt: 0), false);
    expect(renderStalled(now: 9000, pendingSince: 7000, lastFrameAt: 0), false);
    expect(renderStalled(now: 9000, pendingSince: 6000, lastFrameAt: 0), true);
    // Frames still arriving during a long animation are not a stall.
    expect(renderStalled(now: 9000, pendingSince: 1000, lastFrameAt: 8500), false);
  });
}
