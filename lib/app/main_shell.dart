import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/contacts/editor/contact_editor_screen.dart';
import '../features/in_call/call_controls.dart';
import '../features/keypad/keypad_screen.dart';
import '../features/recents/call_log_repository.dart';
import '../features/recents/recents_screen.dart';
import '../widgets/one_ui_floating_nav_bar.dart';
import '../widgets/one_ui_status_bar_scrim.dart';
import '../widgets/press_glow.dart';
import 'layout.dart';
import 'return_to_call_banner.dart';

/// A tab's selection actions (a docked `OneUIFloatingActionBar`). While set, the nav
/// bar morphs into them (OneSpend's `dockedContent`).
final ValueNotifier<Widget?> navDock = ValueNotifier(null);

/// Calls and Contacts under the floating nav bar, with the keypad as a sheet over
/// Calls. Tabs stay alive (IndexedStack) and the keypad stays offstage on Contacts,
/// so a half-typed number survives switching tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final _input = ValueNotifier('');
  final _keypadOpen = ValueNotifier(true);
  int _tab = 0;

  static const _items = [
    OneUINavItem(activeIcon: Icons.call_rounded, inactiveIcon: Icons.call_outlined, label: 'Calls'),
    OneUINavItem(activeIcon: Icons.people_alt_rounded, inactiveIcon: Icons.people_alt_outlined, label: 'Contacts'),
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
    // The missed-call notification opens Calls with the keypad down.
    TelecomBridge.instance.onOpenRecents = _openRecents;
    TelecomBridge.instance.consumeOpenRecents().then((open) {
      if (open) _openRecents();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tab == 0) CallLogRepository.instance.markMissedSeen();
  }

  void _select(int tab) {
    if (!mounted) return;
    setState(() => _tab = tab);
    if (tab == 0) CallLogRepository.instance.markMissedSeen();
  }

  void _openRecents() {
    _keypadOpen.value = false;
    _select(0);
  }

  void _dial(String number) {
    if (!mounted) return;
    _input.value = number;
    _keypadOpen.value = true;
    _select(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TelecomBridge.instance.onDialIntent = null;
    TelecomBridge.instance.onOpenRecents = null;
    _input.dispose();
    _keypadOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hosted like OneSpend's home shell: the bar floats over the tabs in a Stack (it
    // fills its parent's height), under a top status-bar scrim. The keypad sheet sits
    // over Calls, above the bar's baseline. Tabs pad themselves with navBarClearance().
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              // Scrolling Calls by hand drops the keypad so the list has the screen.
              NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null) _keypadOpen.value = false;
                  return false;
                },
                child: RecentsScreen(dialInput: _input, keypadOpen: _keypadOpen),
              ),
              const ContactsScreen(),
            ],
          ),
          Offstage(
            offstage: _tab != 0,
            child: KeypadScreen(input: _input, open: _keypadOpen, isActive: _tab == 0),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: OneUIStatusBarScrim()),
          const Positioned(top: 0, left: 0, right: 0, child: ReturnToCallBanner()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ListenableBuilder(
              listenable: Listenable.merge([navDock, _keypadOpen]),
              builder: (context, _) => OneUIFloatingNavBar(
                currentIndex: _tab,
                dockedContent: navDock.value,
                onTap: (index) {
                  Haptics.tap();
                  _select(index);
                },
                items: _items,
                trailing: navDock.value != null
                    ? null
                    : _tab == 1
                    ? _RoundAction(
                        key: const ValueKey('action'),
                        icon: Icons.add_rounded,
                        tooltip: 'Create contact',
                        onPressed: () => openContactEditor(context),
                      )
                    : _keypadOpen.value
                    ? null
                    : _RoundAction(
                        key: const ValueKey('action'),
                        icon: Icons.dialpad_rounded,
                        tooltip: 'Show keypad',
                        onPressed: () => _keypadOpen.value = true,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The green round button beside the nav bar, lit like the keypad's Call button.
class _RoundAction extends StatelessWidget {
  const _RoundAction({super.key, required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  static const _green = Color(0xFF5BB450);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: kFloatingNavBarHeight,
      child: PressGlow(
        glowColor: _green,
        child: Container(
          decoration: solidBody(_green, const CircleBorder(), glow: 0),
          foregroundDecoration: solidGlow(const CircleBorder()),
          child: FloatingActionButton(
            heroTag: null,
            tooltip: tooltip,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 0,
            highlightElevation: 0,
            onPressed: onPressed,
            // Switching tabs keeps the button and cross-fades its icon.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, key: ValueKey(icon), size: 34, weight: 300),
            ),
          ),
        ),
      ),
    );
  }
}
