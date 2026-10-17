import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:math' as math;

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
import 't9.dart';
import '../search/search_screen.dart';

/// Samsung-style dial pad: T9 contact search above, the typed number, the keypad and
/// one call button, with SIM selection when required.
class KeypadScreen extends StatefulWidget {
  const KeypadScreen({super.key, required this.input, this.isActive = true});
  final bool isActive;

  /// The typed number; the shell also writes `tel:` links into it.
  final ValueNotifier<String> input;

  @override
  State<KeypadScreen> createState() => _KeypadScreenState();
}

/// Samsung's keypad sits on charcoal, not the pure black of the other tabs.
const keypadBackground = Color(0xFF161616);

class _KeypadScreenState extends State<KeypadScreen> {
  final _telecom = TelecomBridge.instance;
  final _menuKey = GlobalKey();
  bool _collapsed = false;
  bool _calling = false;

  void _collapse() {
    if (!_collapsed && widget.input.value.isNotEmpty && mounted) setState(() => _collapsed = true);
  }

  @override
  void initState() {
    super.initState();
    widget.input.addListener(_inputChanged);
  }

  void _inputChanged() {
    if (_collapsed && mounted) setState(() => _collapsed = false);
  }

  @override
  void didUpdateWidget(covariant KeypadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      oldWidget.input.removeListener(_inputChanged);
      widget.input.addListener(_inputChanged);
    }
  }

  @override
  void dispose() {
    widget.input.removeListener(_inputChanged);
    super.dispose();
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
            label: _collapsed ? 'Show keypad' : 'Hide keypad',
            onTap: () => setState(() => _collapsed = !_collapsed),
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
    return ColoredBox(
      color: keypadBackground,
      child: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<String>(
          valueListenable: widget.input,
          builder: (context, number, _) {
            // Reserve the same space whether the navigation bar is visible or hidden.
            final bottomSpace = navBarClearance(context) + 8;
            final collapsed = _collapsed && number.isNotEmpty;
            return PopScope(
              canPop: !collapsed || !widget.isActive,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && collapsed && widget.isActive) setState(() => _collapsed = false);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = math.max(constraints.maxHeight, bottomSpace + 480);
                  final keyHeight = ((height - bottomSpace - 220) / 5).clamp(56.0, 84.0);
                  final panelHeight = 88 + keyHeight * 4 + 8 + 72 + bottomSpace;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(end: collapsed ? 1.0 : 0.0),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    builder: (context, progress, child) => SingleChildScrollView(
                      physics: collapsed ? const NeverScrollableScrollPhysics() : null,
                      child: SizedBox(
                        height: height - (height - constraints.maxHeight) * progress,
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    spacing: 16,
                                    children: [
                                      if (number.isNotEmpty)
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
                                      matches: number.isEmpty ? const [] : t9Search(number, contacts),
                                      expanded: collapsed,
                                      onScroll: _collapse,
                                      onPick: (m) {
                                        setState(() => _collapsed = false);
                                        widget.input.value = m.number;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: panelHeight * (1 - progress)),
                              ],
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -panelHeight * progress,
                              child: IgnorePointer(
                                ignoring: collapsed,
                                child: ExcludeSemantics(
                                  excluding: collapsed,
                                  child: ColoredBox(
                                    color: keypadBackground,
                                    child: Column(
                                      key: const ValueKey('keypad-panel'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _NumberDisplay(number: number, onPaste: _paste),
                                        _Keypad(onKey: _type, onLongPress: _longPress, keyHeight: keyHeight),
                                        const SizedBox(height: 8),
                                        _CallRow(
                                          showBackspace: number.isNotEmpty,
                                          onCall: _calling ? null : _call,
                                          onBackspace: _backspace,
                                          onClear: () => widget.input.value = '',
                                        ),
                                        SizedBox(height: bottomSpace),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (collapsed)
                              Positioned(
                                right: 24,
                                bottom: MediaQuery.paddingOf(context).bottom + 16,
                                child: FloatingActionButton(
                                  tooltip: 'Show keypad',
                                  backgroundColor: const Color(0xFF08AB60),
                                  foregroundColor: Colors.black,
                                  shape: const CircleBorder(),
                                  elevation: 0,
                                  onPressed: () => setState(() => _collapsed = false),
                                  child: const Icon(Icons.dialpad_rounded),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.matches, required this.onPick, required this.onScroll, required this.expanded});

  final List<T9Match> matches;
  final ValueChanged<T9Match> onPick;
  final VoidCallback onScroll;
  final bool expanded;

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
        padding: EdgeInsets.fromLTRB(24, 12, 24, expanded ? 88 : 0),
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
            LetterAvatar(name: name, size: 40),
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
          height: 88,
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
                      fontSize: 44,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              children: [
                for (final (digit, letters) in _keys.sublist(row * 3, row * 3 + 3))
                  Expanded(
                    child: _Key(
                      digit: digit,
                      keyHeight: keyHeight,
                      letters: letters,
                      onTap: () => onKey(digit),
                      onLongPress: () => onLongPress(digit),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.digit,
    required this.letters,
    required this.onTap,
    required this.keyHeight,
    this.onLongPress,
  });
  final double keyHeight;

  final String digit;
  final String letters;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: switch (digit) {
        '0' => '0, long-press for plus',
        '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9' => '$digit, long-press for speed dial',
        _ => digit,
      },
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: 44,
        highlightShape: BoxShape.circle,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.15),
        child: SizedBox(
          height: keyHeight,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    digit,
                    style: TextStyle(
                      fontSize: digit == '*' ? 44 : 38,
                      height: 1.1,
                      fontWeight: FontWeight.w400,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                  if (letters == 'VM')
                    const Icon(Icons.voicemail_rounded, size: 18, color: OneUITheme.textSecondary)
                  else if (letters.isNotEmpty)
                    Text(letters, style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.showBackspace, required this.onCall, required this.onBackspace, required this.onClear});

  final bool showBackspace;
  final VoidCallback? onCall;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Spacer(),
          Expanded(
            child: Center(child: _CallButton(onTap: onCall)),
          ),
          Expanded(
            child: showBackspace
                ? Semantics(
                    button: true,
                    label: 'Delete, long-press to clear',
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: onBackspace,
                      onLongPress: onClear,
                      radius: 28,
                      child: const SizedBox(
                        height: 64,
                        child: Icon(Icons.backspace_rounded, color: OneUITheme.textSecondary, size: 30),
                      ),
                    ),
                  )
                : const SizedBox(height: 64),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Call',
    enabled: onTap != null,
    excludeSemantics: true,
    child: Material(
      color: const Color(0xFF08AB60),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(height: 72, width: 72, child: Icon(Icons.call_rounded, color: Colors.white, size: 38)),
      ),
    ),
  );
}
