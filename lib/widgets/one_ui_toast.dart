import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/one_ui_theme.dart';

/// Brief, text-only feedback, drawn in-app in the style of the One UI toast.
///
/// (Android's own toast is not used: since Android 12 it always shows the app's
/// icon beside the message.)
///
/// Toasts never carry actions: offer Undo inline instead (see the design doc).
/// Only toast what the screen doesn't already show: errors, and results you
/// can't see (e.g. "Backup saved").
class OneUIToast {
  static const MethodChannel _device = MethodChannel('onespend/device');

  static OverlayEntry? _currentEntry;

  /// Android API level, fetched once (null off Android or before it arrives).
  static int? _sdkInt;
  static bool _sdkRequested = false;

  /// Overrides the Android version check in tests (e.g. 33 to mimic Android 13).
  @visibleForTesting
  static int? debugSdkInt;

  static int? get _androidSdk => debugSdkInt ?? _sdkInt;

  /// Call once at startup so [copied] knows the Android version in time.
  static Future<void> init() async {
    if (_sdkRequested || kIsWeb || !Platform.isAndroid) return;
    _sdkRequested = true;
    try {
      _sdkInt = await _device.invokeMethod<int>('sdkInt');
    } catch (_) {
      _sdkInt = null;
    }
  }

  /// Shows [message]. [long] keeps it up longer.
  static void show(BuildContext context, String message, {bool long = false}) {
    _show(context, message, long ? const Duration(milliseconds: 3500) : const Duration(milliseconds: 2000));
  }

  /// Confirms a copy to the clipboard. Android 13+ already shows its own
  /// clipboard confirmation, so ours is skipped there to avoid a double message.
  static void copied(BuildContext context, String message) {
    final sdk = _androidSdk;
    if (sdk != null && sdk >= 33) return;
    show(context, message);
  }

  static void _show(BuildContext context, String message, Duration duration) {
    dismiss();

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _OneUIToastWidget(
        message: message,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            _currentEntry?.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Dismisses the toast on screen immediately.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// The One UI toast: a solid dark-grey capsule with plain white text, centred
/// just above the nav bar, that fades in with a slight rise.
class _OneUIToastWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  const _OneUIToastWidget({required this.message, required this.duration, required this.onDismiss});

  @override
  State<_OneUIToastWidget> createState() => _OneUIToastWidgetState();
}

class _OneUIToastWidgetState extends State<_OneUIToastWidget> with SingleTickerProviderStateMixin {
  /// Above the floating nav bar (8 inset + 60 bar) with a 12px gap.
  static const double _bottom = 80.0;

  static const Color _background = Color(0xFF333336);

  Timer? _dismissTimer;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _dismissTimer = Timer(widget.duration, () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (mounted) widget.onDismiss();
      });
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottom = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom + 24.0
        : mediaQuery.padding.bottom + _bottom;

    return Positioned(
      left: 32,
      right: 32,
      bottom: bottom,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(_fade),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                      color: OneUITheme.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
