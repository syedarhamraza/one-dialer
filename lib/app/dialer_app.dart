import 'package:flutter/material.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/blocking/blocking_repository.dart';
import '../features/recents/call_log_repository.dart';
import '../features/setup/setup_screen.dart';
import '../theme/one_ui_theme.dart';
import 'main_shell.dart';

class DialerApp extends StatelessWidget {
  const DialerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dialer',
      debugShowCheckedModeBanner: false,
      theme: OneUITheme.darkTheme,
      scrollBehavior: OneUITheme.scrollBehavior,
      home: const _SetupGate(),
    );
  }
}

/// Shows [SetupScreen] until the app is the default phone app (or the user skips it).
class _SetupGate extends StatefulWidget {
  const _SetupGate();

  @override
  State<_SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<_SetupGate> with WidgetsBindingObserver {
  bool? _isDefault; // null while checking
  bool _skipped = false;

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
    // Contacts and call-log access arrive with the role, so (re)start loading after each check.
    await ContactsRepository.instance.start();
    await CallLogRepository.instance.start();
    await BlockingRepository.instance.load();
    if (mounted) setState(() => _isDefault = isDefault);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_isDefault) {
      null => const Scaffold(),
      true => const MainShell(),
      false when _skipped => const MainShell(),
      false => SetupScreen(onDone: _check, onSkip: () => setState(() => _skipped = true)),
    };
  }
}
