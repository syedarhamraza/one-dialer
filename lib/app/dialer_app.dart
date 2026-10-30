import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/diagnostics/lag_diagnostics.dart';
import '../core/prefs/dialer_prefs.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/blocking/blocking_repository.dart';
import '../features/recents/call_log_repository.dart';
import '../features/setup/setup_screen.dart';
import '../theme/one_ui_theme.dart';
import 'layout.dart';
import 'main_shell.dart';

class DialerApp extends StatelessWidget {
  const DialerApp({super.key});
  static final _diagnosticsObserver = DiagnosticsNavigatorObserver();

  @override
  Widget build(BuildContext context) {
    const transitions = PageTransitionsTheme(builders: {TargetPlatform.android: _GroupedSlide()});
    return ValueListenableBuilder(
      valueListenable: DialerPrefs.instance.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'One Dialer',
        navigatorObservers: [_diagnosticsObserver],
        debugShowCheckedModeBanner: false,
        theme: OneUITheme.lightTheme.copyWith(pageTransitionsTheme: transitions),
        darkTheme: OneUITheme.darkTheme.copyWith(pageTransitionsTheme: transitions),
        themeMode: switch (mode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        scrollBehavior: OneUITheme.scrollBehavior,
        // Status and navigation bar icons follow the page.
        builder: (context, child) => AnnotatedRegion(
          value: context.palette.isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
          child: DesignWidth(child: child!),
        ),
        home: const _SetupGate(),
      ),
    );
  }
}

/// Android's predictive back (the system back swipe drags the page), with each page's glass
/// controls (`CallGlass`) sharing one backdrop read, as the shell's tabs do: a separate read
/// per button splits the GPU pass every frame.
/// Extends the builder (not wraps it) so pages keep its 450 ms duration.
class _GroupedSlide extends PredictiveBackPageTransitionsBuilder {
  const _GroupedSlide();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => super.buildTransitions(route, context, animation, secondaryAnimation, BackdropGroup(child: child));
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
