import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../core/diagnostics/lag_diagnostics.dart';
import '../core/telecom/telecom_bridge.dart';
import '../features/contacts/contact_details_screen.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/contacts/editor/contact_editor_screen.dart';
import '../features/keypad/keypad_screen.dart';
import '../features/recents/call_log_repository.dart';
import '../features/recents/recents_screen.dart';
import '../widgets/one_ui_floating_nav_bar.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/press_glow.dart';
import 'layout.dart';
import 'return_to_call_banner.dart';
import '../l10n/l10n.dart';

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
  final _backdrop = BackdropKey();

  /// Built once, so switching tabs (a rebuild of this shell) doesn't rebuild the Calls list.
  // Scrolling Calls by hand drops the keypad so the list has the screen.
  late final Widget _calls = NotificationListener<ScrollStartNotification>(
    onNotification: (n) {
      if (n.dragDetails != null) _keypadOpen.value = false;
      return false;
    },
    child: RecentsScreen(dialInput: _input, keypadOpen: _keypadOpen),
  );

  List<OneUINavItem> _items(BuildContext context) => [
    OneUINavItem(activeIcon: Icons.call_rounded, inactiveIcon: Icons.call_outlined, label: context.l10n.navCalls),
    OneUINavItem(
      activeIcon: Icons.people_alt_rounded,
      inactiveIcon: Icons.people_alt_outlined,
      label: context.l10n.navContacts,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A cold start opens on Calls without a resume event or a tab tap.
    CallLogRepository.instance.markMissedSeen();
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
    // The Contacts icon, and contacts other apps ask us to show, edit or add.
    TelecomBridge.instance.onContactAction = _contactAction;
    TelecomBridge.instance.consumeContactAction().then((action) {
      if (action != null) _contactAction(action);
    });
  }

  void _contactAction(Map<Object?, Object?> action) {
    if (!mounted) return;
    _keypadOpen.value = false;
    _select(1);
    final id = action['id'] as String?;
    switch (action['kind']) {
      case 'view' when id != null:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ContactDetailsScreen(contactId: id)));
      case 'edit' when id != null:
        openContactEditor(context, contactId: id);
      case 'insert':
        openContactEditor(context, number: action['phone'] as String?, name: action['name'] as String?, rise: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tab == 0) CallLogRepository.instance.markMissedSeen();
  }

  void _select(int tab) {
    LagDiagnostics.instance.screen(tab == 0 ? 'calls' : 'contacts');
    LagDiagnostics.instance.action(tab == 0 ? DiagnosticAction.tabCalls : DiagnosticAction.tabContacts);
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
    TelecomBridge.instance.onContactAction = null;
    _input.dispose();
    _keypadOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hosted like OneSpend's home shell: the bar floats over the tabs in a Stack (it
    // fills its parent's height); each tab draws its own top scrim. The keypad sheet sits
    // over Calls, above the bar's baseline. Tabs pad themselves with navBarClearance().
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // The tabs' glass controls and the keypad sheet don't overlap, so their blurs share
          // one backdrop read instead of one each. The nav bar, drawn over the keypad, keeps
          // its own (it must blur the sheet too). Reduced visual effects joins them all in the
          // page's one read: the nav bar then blurs Calls under the sheet, which the sheet's own
          // blur of the same Calls already matches. The key changes, not the tree, so the tabs
          // keep their state.
          ListenableBuilder(
            listenable: OneUIEffectsController.instance,
            builder: (context, tabs) => BackdropGroup(
              backdropKey: OneUIEffectsController.instance.isFull
                  ? _backdrop
                  : BackdropGroup.of(context)?.backdropKey ?? _backdrop,
              child: tabs!,
            ),
            child: Stack(
              children: [
                IndexedStack(index: _tab, children: [_calls, const ContactsScreen()]),
                Offstage(
                  offstage: _tab != 0,
                  child: KeypadScreen(input: _input, open: _keypadOpen, isActive: _tab == 0),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StreamBuilder(
              stream: TelecomBridge.instance.callState,
              builder: (context, calls) => ListenableBuilder(
                listenable: Listenable.merge([navDock, _keypadOpen]),
                builder: (context, _) => OneUIFloatingNavBar(
                  currentIndex: _tab,
                  dockedContent: navDock.value,
                  onTap: (index) {
                    Haptics.tap();
                    _select(index);
                  },
                  items: _items(context),
                  leading: ongoingCall(calls.data) == null
                      ? null
                      : _RoundAction(
                          key: const ValueKey('call'),
                          // The handset with sound waves: an ongoing call, not a call key.
                          icon: Icons.phone_in_talk_rounded,
                          tooltip: context.l10n.returnToCall,
                          onPressed: TelecomBridge.instance.showInCallScreen,
                        ),
                  trailing: navDock.value != null
                      ? null
                      : _tab == 1
                      ? _RoundAction(
                          key: const ValueKey('action'),
                          icon: Icons.add_rounded,
                          tooltip: context.l10n.createContact,
                          // New contact rises from the bottom, like the keypad sheet.
                          onPressed: () => openContactEditor(context, rise: true),
                        )
                      : _keypadOpen.value
                      ? null
                      : _RoundAction(
                          key: const ValueKey('action'),
                          icon: Icons.dialpad_rounded,
                          tooltip: context.l10n.showKeypad,
                          onPressed: () => _keypadOpen.value = true,
                        ),
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

  static const _green = OneUITheme.dialGreen;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: kFloatingNavBarHeight,
      child: LitButton(
        color: _green,
        shape: const CircleBorder(),
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
            child: Icon(icon, key: ValueKey(icon), size: icon == Icons.add_rounded ? 42 : 34, weight: 300),
          ),
        ),
      ),
    );
  }
}
