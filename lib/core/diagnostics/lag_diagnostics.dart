import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../prefs/dialer_prefs.dart';
import 'lag_metrics.dart';

enum DiagnosticAction { keypad, backspace, tabCalls, tabContacts, contactsLoad, callLogLoad }

/// Names are allowlisted again at the native boundary; no user input is accepted.
const _actionNames = {
  DiagnosticAction.keypad: 'keypad',
  DiagnosticAction.backspace: 'backspace',
  DiagnosticAction.tabCalls: 'tab_calls',
  DiagnosticAction.tabContacts: 'tab_contacts',
  DiagnosticAction.contactsLoad: 'contacts_load',
  DiagnosticAction.callLogLoad: 'call_log_load',
};

/// Taps whose next second of frames is attached to the action in the report history.
const _userActions = {
  DiagnosticAction.keypad,
  DiagnosticAction.backspace,
  DiagnosticAction.tabCalls,
  DiagnosticAction.tabContacts,
};

/// The worst frames drawn in the second after a user action.
class _ActionWindow {
  _ActionWindow(this.name, this.startUs);
  final String name;
  final int startUs;
  int frames = 0;
  double buildMaxMs = 0;
  double rasterMaxMs = 0;
}

class LagDiagnostics with WidgetsBindingObserver {
  LagDiagnostics({
    MethodChannel? channel,
    Future<void> Function(Map<String, dynamic>)? upload,
    int Function()? monotonicMicros,
  }) : _channel = channel ?? const MethodChannel('com.syedarhamraza.dialer/diagnostics'),
       _upload = upload ?? uploadToFirebase,
       // FrameTiming timestamps use the engine's monotonic clock, the same one as Timeline.now.
       _nowUs = monotonicMicros ?? (() => Timeline.now);

  static final instance = LagDiagnostics();
  final MethodChannel _channel;
  final Future<void> Function(Map<String, dynamic>) _upload;
  final int Function() _nowUs;
  final _windows = <_ActionWindow>[];
  Map<String, Object>? _shellSummary;
  int _pointerDowns = 0;
  final metrics = LagMetrics();
  final _clock = Stopwatch()..start();
  bool _enabled = false;
  bool _flushing = false;
  bool _beating = false;
  bool _manualPending = false;
  bool _resumed = false;
  int _resumedAt = 0;
  int _lastAutomatic = -600000;
  int _lastRenderStall = -600000;
  int _lastFrameAt = 0;
  int? _framePendingSince;
  Timer? _timer;
  String _screen = 'calls';
  String _tab = 'calls';
  int _routeDepth = 0;
  int _ticks = 0;
  Map<String, Object> _summary = {};

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args).timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  Future<void> start({required String engine, required bool enabled}) async {
    if (_enabled || !enabled) return;
    _enabled = await _invoke<bool>('register', {'enabled': true}) == true;
    if (!_enabled) return;
    _screen = engine == 'in_call' ? 'in_call' : 'calls';
    _tab = _screen;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addTimingsCallback(_frames);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
    didChangeAppLifecycleState(WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Flutter goes inactive when the window loses focus (the proximity screen-off in a call)
      // while Android still counts the activity resumed, so keep beating or native sees a DartStall.
      if (_resumed || WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive) unawaited(_heartbeat());
      if (!_resumed) return;
      if (++_ticks % 5 == 0) _summary = metrics.summary();
      _checkRender();
      if (_ticks % 5 == 0) unawaited(flush());
    });
    unawaited(flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _resumedAt = _clock.elapsedMilliseconds;
    _framePendingSince = null;
    metrics.clear();
    _summary = {};
    if (_resumed) {
      unawaited(_heartbeat());
      unawaited(flush());
    }
  }

  void screen(String name) {
    _tab = name;
    if (_routeDepth == 0) _screen = name;
  }

  void routeDepth(int depth) {
    // Walking to Help & feedback › Report lag pushes the tab's frames out of the 600-frame
    // window; keep what they were when the first page opened over the tabs.
    if (_routeDepth == 0 && depth > 0) _shellSummary = metrics.summary();
    _routeDepth = depth;
    _screen = depth > 0 ? 'subpage' : _tab;
  }

  void action(DiagnosticAction action, {Duration? elapsed}) {
    if (!_enabled) return;
    final name = _actionNames[action]!;
    unawaited(_invoke<void>('action', {'name': name, if (elapsed != null) 'elapsedMs': elapsed.inMilliseconds}));
    if (elapsed != null || !_userActions.contains(action) || _windows.length >= 8) return;
    final window = _ActionWindow(name, _nowUs());
    _windows.add(window);
    // FrameTimings arrive in batches up to a second late, so close the window after 2.5 s.
    Timer(const Duration(milliseconds: 2500), () => _closeWindow(window));
  }

  void _closeWindow(_ActionWindow window) {
    if (!_windows.remove(window) || !_enabled) return;
    unawaited(
      _invoke<void>('actionFrames', {
        'name': window.name,
        'frames': window.frames,
        'buildMaxMs': window.buildMaxMs,
        'rasterMaxMs': window.rasterMaxMs,
      }),
    );
  }

  @visibleForTesting
  void closeActionWindows() => List.of(_windows).forEach(_closeWindow);

  void _pointer(PointerEvent event) {
    if (event is PointerDownEvent) _pointerDowns++;
  }

  Future<void> _heartbeat() async {
    if (!_enabled || _beating) return;
    _beating = true;
    try {
      final prefs = DialerPrefs.instance;
      final views = PlatformDispatcher.instance.views;
      await _invoke<void>('heartbeat', {
        'screen': _screen,
        'visualEffects': prefs.visualEffects.value,
        'callEffects': prefs.callEffects.value,
        'glassDark': prefs.glassDark.value,
        'glassLight': prefs.glassLight.value,
        'callGlass': prefs.callGlass.value,
        'refreshRate': views.isEmpty ? 60.0 : views.first.display.refreshRate,
        'frames': _summary,
        if (_routeDepth > 0 && _shellSummary != null) 'shellFrames': _shellSummary,
        // Native compares this with the touches Android delivered (InputStall).
        'pointerDowns': _pointerDowns,
      });
    } finally {
      _beating = false;
    }
  }

  void _checkRender() {
    final now = _clock.elapsedMilliseconds;
    // A pre-warmed in-call engine has no surface (lifecycle null) and never draws.
    final shown = SchedulerBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _framePendingSince = shown && SchedulerBinding.instance.hasScheduledFrame ? (_framePendingSince ?? now) : null;
    if (now - _resumedAt < 5000 || now - _lastRenderStall < 600000) return;
    if (!renderStalled(now: now, pendingSince: _framePendingSince, lastFrameAt: _lastFrameAt)) return;
    _lastRenderStall = now;
    // Only an accepted report starts the cooldown; native may refuse (not resumed, rate limit).
    unawaited(_report('RenderStall').then((id) => id == null ? _lastRenderStall = -600000 : null));
  }

  @visibleForTesting
  void addTimings(List<FrameTiming> timings) => _frames(timings);

  void _frames(List<FrameTiming> timings) {
    _lastFrameAt = _clock.elapsedMilliseconds;
    for (final window in _windows) {
      for (final frame in timings) {
        final at = frame.timestampInMicroseconds(FramePhase.vsyncStart);
        if (at < window.startUs || at >= window.startUs + 1000000) continue;
        window.frames++;
        final build = frame.buildDuration.inMicroseconds / 1000;
        final raster = frame.rasterDuration.inMicroseconds / 1000;
        if (build > window.buildMaxMs) window.buildMaxMs = build;
        if (raster > window.rasterMaxMs) window.rasterMaxMs = raster;
      }
    }
    if (!_enabled || !_resumed || _clock.elapsedMilliseconds - _resumedAt < 5000) return;
    var severe = false;
    for (final frame in timings) {
      severe =
          metrics.add(frame.buildDuration.inMicroseconds / 1000, frame.rasterDuration.inMicroseconds / 1000) || severe;
    }
    if (severe && _clock.elapsedMilliseconds - _lastAutomatic >= 600000) {
      _lastAutomatic = _clock.elapsedMilliseconds;
      _summary = metrics.summary();
      unawaited(_report('SevereFrameDelay'));
    }
  }

  Future<String?> _report(String category) async {
    await _heartbeat();
    final id = await _invoke<String>('report', {'category': category});
    unawaited(flush());
    return id;
  }

  /// Null means unavailable or cooling down. Native enforcement spans both engines.
  Future<String?> reportLag() async {
    if (!_enabled || _manualPending) return null;
    _manualPending = true;
    try {
      _summary = metrics.summary();
      return await _report('UserReportedLag');
    } finally {
      _manualPending = false;
    }
  }

  /// Native claim leases serialize uploads across both engines. Ack only after
  /// Crashlytics accepts the event locally, not after a claimed network delivery.
  Future<void> flush() async {
    if (!_enabled || _flushing) return;
    _flushing = true;
    try {
      for (var i = 0; i < 20; i++) {
        final row = await _invoke<Map<Object?, Object?>>('claim');
        if (row == null) break;
        final id = row['id'];
        try {
          final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
          await _upload(payload);
          await _invoke<void>('ack', {'id': id});
        } catch (_) {
          await _invoke<void>('release', {'id': id});
          break;
        }
      }
    } catch (_) {
      // Diagnostics can never become a source of uncaught application errors.
    } finally {
      _flushing = false;
    }
  }

  @visibleForTesting
  static Future<void> uploadToFirebase(Map<String, dynamic> payload) async {
    final crashlytics = FirebaseCrashlytics.instance;
    // The event's information contains its immutable context. Global keys are
    // engine-prefixed and informational only: another engine cannot overwrite it.
    final engine = payload['engine'];
    await crashlytics.setCustomKey('lag_${engine}_report_id', payload['reportId'] as String);
    await crashlytics.setCustomKey('lag_${engine}_category', payload['category'] as String);
    final context = payload['context'] as Map<String, dynamic>? ?? {};
    for (final key in [
      'screen',
      'visualEffects',
      'callEffects',
      'glassDark',
      'glassLight',
      'callGlass',
      'refreshRate',
    ]) {
      await crashlytics.setCustomKey('lag_${engine}_$key', context[key] ?? 'unknown');
    }
    final category = payload['category'] as String;
    // The Java main stack, when there is one, stays in the JSON below.
    await crashlytics.recordError(
      _LagIncident(category),
      incidentTrace(category),
      reason: category,
      information: [jsonEncode(payload)],
      fatal: false,
    );
  }

  /// Crashlytics groups issues by stack, so each category gets a trace from its own function.
  @visibleForTesting
  static StackTrace incidentTrace(String category) => switch (category) {
    'SevereFrameDelay' => _severeFrameDelay(),
    'NativeMainStall' => _nativeMainStall(),
    'DartStall' => _dartStall(),
    'RenderStall' => _renderStall(),
    'InputStall' => _inputStall(),
    'UserReportedLag' => _userReportedLag(),
    _ => StackTrace.current,
  };

  @pragma('vm:never-inline')
  static StackTrace _severeFrameDelay() => StackTrace.current;
  @pragma('vm:never-inline')
  static StackTrace _nativeMainStall() => StackTrace.current;
  @pragma('vm:never-inline')
  static StackTrace _dartStall() => StackTrace.current;
  @pragma('vm:never-inline')
  static StackTrace _renderStall() => StackTrace.current;
  @pragma('vm:never-inline')
  static StackTrace _inputStall() => StackTrace.current;
  @pragma('vm:never-inline')
  static StackTrace _userReportedLag() => StackTrace.current;

  @visibleForTesting
  void dispose() {
    if (!_enabled) return;
    _enabled = false;
    _timer?.cancel();
    _windows.clear();
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.removeTimingsCallback(_frames);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointer);
    unawaited(_invoke<void>('register', {'enabled': false}));
  }

  /// Development-only hooks; no UI or release activation path.
  Future<void> simulate(String kind) async {
    if (kReleaseMode || !const bool.fromEnvironment('LAG_DIAGNOSTICS_TEST_HOOKS')) return;
    if (kind == 'native') await _invoke<void>('testNativeStall');
    if (kind == 'dart') {
      final stop = Stopwatch()..start();
      while (stop.elapsedMilliseconds < 4000) {
        /* Intentional test-only stall. */
      }
    }
    if (kind == 'frame') {
      metrics.add(701, 1);
      _summary = metrics.summary();
      await _report('SevereFrameDelay');
    }
  }
}

class _LagIncident implements Exception {
  const _LagIncident(this.category);
  final String category;
  @override
  String toString() => category;
}

/// Route names/arguments can contain contact identifiers; record depth only.
class DiagnosticsNavigatorObserver extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];
  void _update() => LagDiagnostics.instance.routeDepth((_routes.length - 1).clamp(0, 100));
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
    _update();
  }
}
