import 'dart:collection';

/// A frame requested >=3 s ago with none drawn since: the raster thread or vsync
/// is stuck while Dart still runs, which neither slow-frame nor heartbeat checks see.
bool renderStalled({required int now, required int? pendingSince, required int lastFrameAt}) =>
    pendingSince != null && now - (pendingSince > lastFrameAt ? pendingSince : lastFrameAt) >= 3000;

/// A bounded window of completed frames. No frame production means no samples,
/// not a freeze: idle screens are intentionally excluded from this signal.
class LagMetrics {
  final _frames = Queue<(double, double)>();

  bool add(double buildMs, double rasterMs) {
    _frames.add((buildMs, rasterMs));
    if (_frames.length > 600) _frames.removeFirst();
    return buildMs >= 700 || rasterMs >= 700;
  }

  void clear() => _frames.clear();

  Map<String, Object> summary() {
    final builds = _frames.map((f) => f.$1).toList()..sort();
    final rasters = _frames.map((f) => f.$2).toList()..sort();
    double percentile(List<double> values, double p) => values.isEmpty ? 0 : values[((values.length - 1) * p).ceil()];
    return {
      'frames': _frames.length,
      for (final entry in {'build': builds, 'raster': rasters}.entries) ...{
        '${entry.key}P50Ms': percentile(entry.value, .50),
        '${entry.key}P95Ms': percentile(entry.value, .95),
        '${entry.key}P99Ms': percentile(entry.value, .99),
        '${entry.key}MaxMs': percentile(entry.value, 1),
      },
    };
  }
}
