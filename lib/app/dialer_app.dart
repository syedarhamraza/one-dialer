import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
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
        pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: _GroupedSlide()}),
      ),
      scrollBehavior: OneUITheme.scrollBehavior,
      builder: (context, child) => DesignWidth(child: child!),
      home: const _SetupGate(),
    );
  }
}

/// The theme's slide, with each page's glass controls (`CallGlass`) sharing one backdrop
/// read, as the shell's tabs do: a separate read per button splits the GPU pass every frame.
class _GroupedSlide extends PageTransitionsBuilder {
  const _GroupedSlide();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => const CupertinoPageTransitionsBuilder().buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    BackdropGroup(child: child),
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
