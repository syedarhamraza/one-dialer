import 'package:flutter/material.dart';

import '../core/telecom/telecom_bridge.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/keypad/keypad_screen.dart';
import '../features/recents/call_log_repository.dart';
import '../features/recents/recents_screen.dart';
import '../widgets/one_ui_floating_nav_bar.dart';

/// A tab's selection actions; while set, the nav bar morphs into them (OneSpend's
/// `dockedContent`), like Samsung's Delete / Share bar.
final ValueNotifier<Widget?> navDock = ValueNotifier(null);

/// The three Samsung tabs under the floating nav bar. Tabs stay alive (IndexedStack)
/// so a half-typed number survives switching tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final _input = ValueNotifier('');
  int _tab = 0;

  static const _items = [
    OneUINavItem(activeIcon: Icons.dialpad_rounded, inactiveIcon: Icons.dialpad_rounded, label: 'Keypad'),
    OneUINavItem(activeIcon: Icons.watch_later_rounded, inactiveIcon: Icons.watch_later_outlined, label: 'Recents'),
    OneUINavItem(activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded, label: 'Contacts'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // `tel:` links open on the keypad with the number filled in.
    TelecomBridge.instance.onDialIntent = _dial;
    TelecomBridge.instance.consumeDialNumber().then((n) {
      if (n != null) _dial(n);
    });
    // The missed-call notification opens Recents.
    TelecomBridge.instance.onOpenRecents = () => _select(1);
    TelecomBridge.instance.consumeOpenRecents().then((open) {
      if (open) _select(1);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tab == 1) CallLogRepository.instance.markMissedSeen();
  }

  void _select(int tab) {
    if (!mounted) return;
    setState(() => _tab = tab);
    if (tab == 1) CallLogRepository.instance.markMissedSeen();
  }

  void _dial(String number) {
    if (!mounted) return;
    _input.value = number;
    _select(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TelecomBridge.instance.onDialIntent = null;
    TelecomBridge.instance.onOpenRecents = null;
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The nav bar floats over the tabs (OneSpend's bar fills its parent's height, so it
    // can't be a Scaffold.bottomNavigationBar); tabs pad themselves with navBarClearance().
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              KeypadScreen(input: _input),
              const RecentsScreen(),
              const ContactsScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<Widget?>(
              valueListenable: navDock,
              builder: (context, dock, _) =>
                  OneUIFloatingNavBar(currentIndex: _tab, items: _items, onTap: _select, dockedContent: dock),
            ),
          ),
        ],
      ),
    );
  }
}
