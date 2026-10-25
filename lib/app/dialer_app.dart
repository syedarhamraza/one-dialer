import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/gestures.dart' show HorizontalDragGestureRecognizer;
import 'package:flutter/material.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/blocking/blocking_repository.dart';
import '../features/recents/call_log_repository.dart';
import '../features/setup/setup_screen.dart';
import '../theme/one_ui_theme.dart';
import 'layout.dart';
import 'main_shell.dart';

class DialerApp extends StatelessWidget {
  const DialerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Dialer',
      debugShowCheckedModeBanner: false,
      theme: OneUITheme.darkTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: GroupedSlide()}),
      ),
      scrollBehavior: OneUITheme.scrollBehavior,
      builder: (context, child) => DesignWidth(child: child!),
      home: const _SetupGate(),
    );
  }
}

/// The theme's slide, with each page's glass controls (`CallGlass`) sharing one backdrop
/// read, as the shell's tabs do: a separate read per button splits the GPU pass every frame.
class GroupedSlide extends PageTransitionsBuilder {
  const GroupedSlide();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => CupertinoPageTransition(
    primaryRouteAnimation: animation,
    secondaryRouteAnimation: secondaryAnimation,
    linearTransition: route.popGestureInProgress,
    child: _SwipeBack(
      route: route,
      child: BackdropGroup(child: child),
    ),
  );
}

/// ColorOS swipe back: a rightward drag from anywhere on the page pulls it off and pops it.
/// Replaces Cupertino's 20 dp edge strip, which Android's own back gesture takes first.
class _SwipeBack extends StatefulWidget {
  const _SwipeBack({required this.route, required this.child});
  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_SwipeBack> createState() => _SwipeBackState();
}

class _SwipeBackState extends State<_SwipeBack> {
  late final _drag = HorizontalDragGestureRecognizer(debugOwner: this)
    ..onStart = _start
    ..onUpdate = _update
    ..onEnd = _end
    ..onCancel = _cancel;
  double? _value; // the route's animation value while dragging

  @override
  void dispose() {
    _drag.dispose();
    // Disposed mid-drag (the route went away): end the user gesture the navigator is holding.
    final navigator = _value == null ? null : widget.route.navigator;
    if (navigator != null) WidgetsBinding.instance.addPostFrameCallback((_) => navigator.didStopUserGesture());
    super.dispose();
  }

  void _start(DragStartDetails _) {
    _value = 1;
    widget.route.handleStartBackGesture(progress: 1);
  }

  void _update(DragUpdateDetails details) {
    if (_value == null) return;
    _value = (_value! - details.primaryDelta! / context.size!.width).clamp(0.0, 1.0);
    widget.route.handleUpdateBackGestureProgress(progress: _value!);
  }

  void _end(DragEndDetails details) {
    if (_value == null) return;
    // Cupertino's thresholds: a fling of a screen width per second, else past half.
    final velocity = details.velocity.pixelsPerSecond.dx / context.size!.width;
    final pop = velocity.abs() >= 1 ? velocity > 0 : _value! < .5;
    _value = null;
    pop ? widget.route.handleCommitBackGesture() : widget.route.handleCancelBackGesture();
  }

  void _cancel() {
    if (_value == null) return;
    _value = null;
    widget.route.handleCancelBackGesture();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      if (widget.route.isCurrent && widget.route.popGestureEnabled) _drag.addPointer(event);
    },
    child: widget.child,
  );
}

/// Shows [SetupScreen] until the app is the default phone app.
class _SetupGate extends StatefulWidget {
  const _SetupGate();

  @override
  State<_SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<_SetupGate> with WidgetsBindingObserver {
  bool? _isDefault; // null while checking

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(); // the role can be changed in Settings
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    final isDefault = await TelecomBridge.instance.isDefaultDialer();
    if (!mounted || isDefault == _isDefault) return;
    // Contacts and call-log access arrive with the role. The tabs listen to the
    // repositories, so the shell shows right away and fills in as data arrives.
    ContactsRepository.instance.start();
    CallLogRepository.instance.start();
    BlockingRepository.instance.load();
    setState(() => _isDefault = isDefault);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_isDefault) {
      null => const Scaffold(),
      true => const MainShell(),
      false => SetupScreen(onDone: _check),
    };
  }
}
