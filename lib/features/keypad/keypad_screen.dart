import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../recents/call_log_repository.dart';
import '../contacts/editor/add_to_contacts.dart';
import '../settings/settings_screen.dart';
import 'speed_dial_screen.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/place_call.dart';
import '../../widgets/press_glow.dart';
import 't9.dart';
import '../search/search_screen.dart';
import '../in_call/call_controls.dart';

/// Samsung-style dial pad as a sheet over Calls: T9 contact search above while
/// typing, then the typed number, pill keys and one call button. Hidden, it leaves a
/// green dialpad button beside the nav bar.
class KeypadScreen extends StatefulWidget {
  const KeypadScreen({super.key, required this.input, required this.open, this.isActive = true});
  final bool isActive;

  /// The typed number; the shell also writes `tel:` links into it.
  final ValueNotifier<String> input;

  /// Whether the sheet is up; the shell opens it for `tel:` links.
  final ValueNotifier<bool> open;

  @override
  State<KeypadScreen> createState() => _KeypadScreenState();
}

/// Samsung's keypad sits on charcoal, not the pure black of the other tabs.
const keypadBackground = Color(0xFF161616);

const double _gap = 10;

class _KeypadScreenState extends State<KeypadScreen> {
  final _telecom = TelecomBridge.instance;
  final _menuKey = GlobalKey();
  bool _calling = false;

  void _show() => widget.open.value = true;

  void _hide() => widget.open.value = false;

  /// Scrolling the results drops the keys so the whole list shows.
  void _collapse() {
    if (widget.input.value.isNotEmpty && mounted) _hide();
  }

  void _type(String key) {
    HapticFeedback.lightImpact();
    _telecom.playTone(key);
    widget.input.value += key;
  }

  /// Long-press: 0 types "+", 2–9 call their speed dial (or offer to assign one).
  Future<void> _longPress(String digit) async {
    if (digit == '0') {
      widget.input.value += '+';
      return;
    }
    if (!DialerPrefs.speedDialDigits.contains(digit) || widget.input.value.isNotEmpty) return;
    HapticFeedback.mediumImpact();
    final entry = await DialerPrefs.instance.speedDial(digit);
    if (entry != null) {
      if (mounted) await placeCall(context, entry.$2);
      return;
    }
    if (!mounted) return;
    final assign = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No speed dial number'),
        content: Text('Assign a contact to key $digit?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Assign')),
        ],
      ),
    );
    if (assign == true && mounted) _openSpeedDial();
  }

  void _openSpeedDial() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpeedDialScreen()));

  void _backspace() {
    final text = widget.input.value;
    if (text.isNotEmpty) widget.input.value = text.substring(0, text.length - 1);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = data?.text?.replaceAll(RegExp(r'[^0-9+*#,;]'), '') ?? '';
    if (digits.isNotEmpty) widget.input.value += digits;
  }

  Future<void> _call() async {
    if (_calling) return;
    final number = widget.input.value;
    if (number.isEmpty) {
      // Like Samsung: an empty call button fills in the last dialled number.
      widget.input.value = CallLogRepository.instance.lastDialled ?? '';
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _calling = true);
    try {
      final called = await placeCall(context, number);
      if (called && widget.input.value == number) widget.input.value = '';
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not place the call.')));
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  void _openMenu() {
    final typing = widget.input.value.isNotEmpty;
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _menuKey,
      width: 250,
      items: [
        if (typing) ...[
          OneUIFloatingMenuItem(
            label: widget.open.value ? 'Hide keypad' : 'Show keypad',
            onTap: () => widget.open.value = !widget.open.value,
          ),
          OneUIFloatingMenuItem(label: 'Add 2-sec pause', onTap: () => widget.input.value += ','),
          OneUIFloatingMenuItem(label: 'Add wait', onTap: () => widget.input.value += ';'),
          OneUIFloatingMenuItem(label: 'Send message', onTap: () => _telecom.sendSms(widget.input.value)),
        ],
        OneUIFloatingMenuItem(label: 'Speed dial numbers', onTap: _openSpeedDial),
        OneUIFloatingMenuItem(
          label: 'Settings',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.input, widget.open]),
      builder: (context, _) {
        final number = widget.input.value;
        final open = widget.open.value;
        return PopScope(
          canPop: !open || !widget.isActive,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && open && widget.isActive) _hide();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final clearance = navBarClearance(context);
              final keyHeight = ((constraints.maxHeight - clearance) * 0.08).clamp(44.0, 60.0);
              // Handle, number, five rows of keys and their gaps, then the nav bar.
              final sheetHeight = 24 + (number.isEmpty ? 0 : 64) + keyHeight * 5 + _gap * 4 + 12 + clearance;
              return Stack(
                children: [
                  // Nothing typed: no backdrop, so Calls shows and takes taps.
                  if (number.isNotEmpty)
                    Positioned.fill(
                      child: ColoredBox(
                        color: keypadBackground,
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  spacing: 16,
                                  children: [
                                    OneUIHeaderAction(
                                      icon: Icons.add_rounded,
                                      size: 28,
                                      tooltip: 'Add to Contacts',
                                      onTap: () => showAddToContacts(context, number),
                                    ),
                                    OneUIHeaderAction(
                                      icon: Icons.search_rounded,
                                      size: 26,
                                      tooltip: 'Search',
                                      onTap: () => openSearch(context),
                                    ),
                                    OneUIHeaderAction(
                                      actionKey: _menuKey,
                                      icon: Icons.more_vert_rounded,
                                      size: 26,
                                      tooltip: 'More options',
                                      onTap: _openMenu,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ValueListenableBuilder<List<DialerContact>>(
                                  valueListenable: ContactsRepository.instance.contacts,
                                  builder: (context, contacts, _) => _Results(
                                    matches: t9Search(number, contacts),
                                    expanded: !open,
                                    bottomPadding: open ? sheetHeight : clearance,
                                    onScroll: _collapse,
                                    onPick: (m) {
                                      widget.input.value = m.number;
                                      _show();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedSlide(
                      offset: Offset(0, open ? 0 : 1),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: IgnorePointer(
                        ignoring: !open,
                        child: ExcludeSemantics(
                          excluding: !open,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                            child: DecoratedBox(
                              key: const ValueKey('keypad-panel'),
                              decoration: const BoxDecoration(
                                color: OneUITheme.surfaceCard,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              // Scrolls only when a small or landscape screen can't fit it.
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _Handle(onHide: _hide),
                                    if (number.isNotEmpty) _NumberDisplay(number: number, onPaste: _paste),
                                    _Keypad(onKey: _type, onLongPress: _longPress, keyHeight: keyHeight),
                                    const SizedBox(height: _gap),
                                    _CallRow(
                                      keyHeight: keyHeight,
                                      onHide: _hide,
                                      onCall: _calling ? null : _call,
                                      onBackspace: _backspace,
                                      onClear: () => widget.input.value = '',
                                    ),
                                    SizedBox(height: 12 + clearance),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!open)
                    Positioned(
                      right: 16,
                      bottom: MediaQuery.paddingOf(context).bottom + kNavBarVerticalPadding,
                      child: SizedBox.square(
                        dimension: kFloatingNavBarHeight,
                        child: PressGlow(
                          glowColor: const Color(0xFF08AB60),
                          child: Container(
                            decoration: solidBody(const Color(0xFF08AB60), const CircleBorder()),
                            foregroundDecoration: solidGlow(const CircleBorder()),
                            child: FloatingActionButton(
                              tooltip: 'Show keypad',
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 0,
                              highlightElevation: 0,
                              onPressed: _show,
                              child: const Icon(Icons.dialpad_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.matches,
    required this.onPick,
    required this.onScroll,
    required this.expanded,
    required this.bottomPadding,
  });

  final List<T9Match> matches;
  final ValueChanged<T9Match> onPick;
  final VoidCallback onScroll;
  final bool expanded;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (notification) {
        if (notification.dragDetails != null && !expanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onScroll());
        }
        return false;
      },
      child: ListView.builder(
        key: ValueKey(expanded),
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding),
        itemCount: matches.length,
        itemBuilder: (context, i) => _ResultTile(match: matches[i], onTap: () => onPick(matches[i])),
      ),
    );
  }
}

/// Samsung's T9 row: avatar and name on the left, the number on the right, matched part in blue.
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.match, required this.onTap});

  final T9Match match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = match.entry.name;
    return InkWell(
      onTap: onTap,
      borderRadius: OneUITheme.cardBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            LetterAvatar(
              name: name,
              photo: switch (match.entry) {
                DialerContact(:final thumbnail) => thumbnail,
                _ => null,
              },
              size: 40,
            ),
            const SizedBox(width: 16),
            // Unsaved numbers (from Recents) are named by their number; show it once.
            if (name == match.number)
              Expanded(
                child: _highlighted(
                  name,
                  match.numberRange,
                  const TextStyle(fontSize: 18, color: OneUITheme.textPrimary),
                ),
              )
            else ...[
              Expanded(
                child: _highlighted(
                  name,
                  match.nameRange,
                  const TextStyle(fontSize: 18, color: OneUITheme.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _highlighted(
                    match.number,
                    match.numberRange,
                    const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _highlighted(String text, (int, int)? range, TextStyle style) {
    if (range == null) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    final (start, end) = range;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(color: OneUITheme.accentBlue, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NumberDisplay extends StatelessWidget {
  const _NumberDisplay({required this.number, required this.onPaste});

  final String number;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: number.isEmpty ? 'Number, empty. Long-press to paste' : 'Number $number',
      child: GestureDetector(
        onLongPress: onPaste,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Text(
                    number,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's grab handle: tap or drag down to hide the keys.
class _Handle extends StatelessWidget {
  const _Handle({required this.onHide});
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    // The dialpad pill is the accessible way to hide the keys.
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onHide,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 0) onHide();
      },
      child: SizedBox(
        height: 24,
        width: double.infinity,
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: OneUITheme.textSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey, required this.onLongPress, required this.keyHeight});
  final double keyHeight;

  final ValueChanged<String> onKey;
  final ValueChanged<String> onLongPress;

  static const _keys = [
    ('1', 'VM'),
    ('2', 'ABC'),
    ('3', 'DEF'),
    ('4', 'GHI'),
    ('5', 'JKL'),
    ('6', 'MNO'),
    ('7', 'PQRS'),
    ('8', 'TUV'),
    ('9', 'WXYZ'),
    ('*', ''),
    ('0', '+'),
    ('#', ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        spacing: _gap,
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              spacing: _gap,
              children: [
                for (final (digit, letters) in _keys.sublist(row * 3, row * 3 + 3))
                  Expanded(
                    child: _Pill(
                      height: keyHeight,
                      label: switch (digit) {
                        '0' => '0, long-press for plus',
                        '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9' => '$digit, long-press for speed dial',
                        _ => digit,
                      },
                      onTap: () => onKey(digit),
                      onLongPress: () => onLongPress(digit),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            digit,
                            style: TextStyle(
                              fontSize: digit == '*' ? 30 : 26,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: OneUITheme.textPrimary,
                            ),
                          ),
                          if (letters == 'VM')
                            const Icon(Icons.voicemail_rounded, size: 12, color: OneUITheme.textSecondary)
                          else if (letters.isNotEmpty)
                            Text(letters, style: const TextStyle(fontSize: 10, color: OneUITheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One flat stadium key; the digits and the dialpad, call and delete buttons all use it.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.height,
    required this.label,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.color = OneUITheme.surfacePill,
    this.lit = false,
  });

  final double height;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color color;

  /// Lit like the call screen's solid buttons: shaded body, coloured glow, light from below.
  final bool lit;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onTap != null,
    excludeSemantics: true,
    child: PressGlow(
      glowColor: lit ? color : null,
      child: Container(
        decoration: lit ? solidBody(color, const StadiumBorder()) : null,
        foregroundDecoration: lit ? solidGlow(const StadiumBorder()) : null,
        child: _ink(),
      ),
    ),
  );

  Widget _ink() => Material(
    color: lit ? Colors.transparent : color,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.15),
      child: SizedBox(
        height: height,
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    ),
  );
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.keyHeight,
    required this.onHide,
    required this.onCall,
    required this.onBackspace,
    required this.onClear,
  });

  final double keyHeight;
  final VoidCallback onHide;
  final VoidCallback? onCall;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: _gap,
        children: [
          Expanded(
            child: _Pill(
              height: keyHeight,
              label: 'Hide keypad',
              onTap: onHide,
              child: const Icon(Icons.dialpad_rounded, color: OneUITheme.textPrimary, size: 26),
            ),
          ),
          Expanded(
            child: _Pill(
              height: keyHeight,
              label: 'Call',
              color: answerGreen,
              lit: true,
              onTap: onCall,
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 30),
            ),
          ),
          Expanded(
            child: _Pill(
              height: keyHeight,
              label: 'Delete, long-press to clear',
              onTap: onBackspace,
              onLongPress: onClear,
              child: const Icon(Icons.backspace_rounded, color: OneUITheme.textSecondary, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
