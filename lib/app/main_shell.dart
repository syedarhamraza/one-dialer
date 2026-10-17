import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/prefs/dialer_prefs.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/keypad/keypad_screen.dart';
import '../features/recents/call_log_repository.dart';
import '../features/recents/recents_screen.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_floating_nav_bar.dart';
import '../widgets/one_ui_glass_surface.dart';
import 'layout.dart';

/// A tab's selection actions (a docked `OneUIFloatingActionBar`). While set, the
/// OneSpend nav bar morphs into them; the package tab bar swaps to a bar of them.
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
  bool _oneSpendNav = true;

  static const _items = [
    OneUINavItem(activeIcon: Icons.dialpad_rounded, inactiveIcon: Icons.dialpad_rounded, label: 'Keypad'),
    OneUINavItem(activeIcon: Icons.watch_later_rounded, inactiveIcon: Icons.watch_later_outlined, label: 'Recents'),
    OneUINavItem(activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded, label: 'Contacts'),
  ];

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
    DialerPrefs.instance.changes.addListener(_loadNavStyle);
    _loadNavStyle();
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

  Future<void> _loadNavStyle() async {
    final oneSpend = await DialerPrefs.instance.oneSpendNavBar();
    if (mounted && oneSpend != _oneSpendNav) setState(() => _oneSpendNav = oneSpend);
  }

  @override
  void dispose() {
    DialerPrefs.instance.changes.removeListener(_loadNavStyle);
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
                builder: (context, dock, _) => _oneSpendNav
                    // A: one glass capsule that morphs between the tabs and the actions.
                    ? OneUIFloatingNavBar(currentIndex: _tab, items: _items, onTap: _select, dockedContent: dock)
                    : _packageTabBar(context, dock),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// B: the package's tab bar. It stays mounted (faded, not painted) while a bar of
  /// the selection actions springs in over it.
  Widget _packageTabBar(BuildContext context, Widget? dock) {
    return Stack(
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
                // Highest tier everywhere: premium indicator and track, high-quality masking.
                quality: GlassQuality.premium,
                backgroundQuality: GlassQuality.premium,
                maskingQuality: MaskingQuality.high,
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(animation), child: child),
          ),
          child: dock == null
              ? const SizedBox.shrink()
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OneUIGlassSurface(
                      elevation: OneUIGlassElevation.navbar,
                      height: kFloatingNavBarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: dock,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
