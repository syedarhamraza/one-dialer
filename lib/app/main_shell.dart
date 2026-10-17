import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/telecom/telecom_bridge.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/keypad/keypad_screen.dart';
import '../features/recents/call_log_repository.dart';
import '../features/recents/recents_screen.dart';
import '../theme/one_ui_theme.dart';
import 'layout.dart';

/// A tab's selection actions (a `OneUIFloatingActionBar`); while set, it replaces the
/// nav bar, like Samsung's Delete / Share bar.
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

  static const double _tabWidth = 96;

  static const _tabs = [
    GlassTab(icon: Icon(Icons.dialpad_rounded), label: 'Keypad'),
    GlassTab(icon: Icon(Icons.watch_later_outlined), activeIcon: Icon(Icons.watch_later_rounded), label: 'Recents'),
    GlassTab(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Contacts'),
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
            // Like Samsung, the bar slides away while a number is being typed on the keypad.
            child: ValueListenableBuilder<String>(
              valueListenable: _input,
              builder: (context, number, navBar) => AnimatedSlide(
                offset: _tab == 0 && number.isNotEmpty ? const Offset(0, 1.5) : Offset.zero,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: navBar,
              ),
              child: ValueListenableBuilder<Widget?>(
                valueListenable: navDock,
                // The glass bar stays mounted under the selection bar (faded out, not
                // painted), so leaving selection mode doesn't rebuild its shaders.
                builder: (context, dock, _) => Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    IgnorePointer(
                      ignoring: dock != null,
                      child: AnimatedOpacity(
                        opacity: dock == null ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: SafeArea(
                          top: false,
                          child: GlassTabBar.bottom(
                            tabs: _tabs,
                            selectedIndex: _tab,
                            onTabSelected: _select,
                            // Standard: premium's multi-pass dispersion is barely visible over black and costs every frame.
                            quality: GlassQuality.standard,
                            barHeight: kFloatingNavBarHeight,
                            verticalPadding: kNavBarVerticalPadding,
                            tabWidth: _tabWidth,
                            // The package left-aligns a fixed-width pill; centre it like Samsung's.
                            horizontalPadding: (MediaQuery.sizeOf(context).width - _tabWidth * _tabs.length) / 2,
                            selectedIconColor: OneUITheme.textPrimary,
                            selectedLabelColor: OneUITheme.textPrimary,
                            unselectedIconColor: OneUITheme.navbar3dInactiveIcon,
                            unselectedLabelColor: OneUITheme.navbar3dInactiveText,
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: dock),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
