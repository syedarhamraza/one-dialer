import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
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
/// one call button per SIM (two when "Ask every time" is set on a dual-SIM phone).
class KeypadScreen extends StatefulWidget {
  const KeypadScreen({super.key, required this.input});

  /// The typed number; the shell also writes `tel:` links into it.
  final ValueNotifier<String> input;

  @override
  State<KeypadScreen> createState() => _KeypadScreenState();
}

/// Samsung's keypad sits on charcoal, not the pure black of the other tabs.
const keypadBackground = Color(0xFF17171A);

class _KeypadScreenState extends State<KeypadScreen> with WidgetsBindingObserver {
  final _telecom = TelecomBridge.instance;
  final _menuKey = GlobalKey();
  List<SimCard> _sims = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSims();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadSims(); // SIM settings may have changed
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadSims() async {
    final sims = await _telecom.getSims();
    if (mounted) setState(() => _sims = sims);
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

  Future<void> _call(SimCard? sim) async {
    final number = widget.input.value;
    if (number.isEmpty) {
      // Like Samsung: an empty call button fills in the last dialled number.
      widget.input.value = CallLogRepository.instance.lastDialled ?? '';
      return;
    }
    HapticFeedback.mediumImpact();
    await _telecom.placeCall(number, simId: sim?.id);
    widget.input.value = '';
  }

  void _openMenu() {
    final typing = widget.input.value.isNotEmpty;
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _menuKey,
      width: 250,
      items: [
        if (typing) ...[
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

  /// One button per SIM only when Android has no default SIM to use.
  List<SimCard?> get _callButtons => _sims.length > 1 && !_sims.any((s) => s.isDefault) ? _sims : const [null];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: keypadBackground,
      child: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<String>(
          valueListenable: widget.input,
          builder: (context, number, _) {
            // The shell hides the nav bar while typing, so the call row drops to the bottom.
            final bottomSpace = number.isEmpty
                ? navBarClearance(context) + 8
                : MediaQuery.paddingOf(context).bottom + 40;
            return Column(
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
                      onPick: (m) => widget.input.value = m.number,
                    ),
                  ),
                ),
                _NumberDisplay(number: number, onPaste: _paste),
                _Keypad(onKey: _type, onLongPress: _longPress),
                const SizedBox(height: 8),
                _CallRow(
                  sims: _callButtons,
                  showBackspace: number.isNotEmpty,
                  onCall: _call,
                  onBackspace: _backspace,
                  onClear: () => widget.input.value = '',
                ),
                SizedBox(height: bottomSpace),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.matches, required this.onPick});

  final List<T9Match> matches;
  final ValueChanged<T9Match> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: matches.length,
      itemBuilder: (context, i) => _ResultTile(match: matches[i], onTap: () => onPick(matches[i])),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            LetterAvatar(name: name, size: 48),
            const SizedBox(width: 16),
            // Unsaved numbers (from Recents) are named by their number; show it once.
            if (name == match.number)
              Expanded(
                child: _highlighted(
                  name,
                  match.numberRange,
                  const TextStyle(fontSize: 20, color: OneUITheme.textPrimary),
                ),
              )
            else ...[
              Expanded(
                child: _highlighted(
                  name,
                  match.nameRange,
                  const TextStyle(fontSize: 20, color: OneUITheme.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              _highlighted(
                match.number,
                match.numberRange,
                const TextStyle(fontSize: 17, color: OneUITheme.textSecondary),
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
                  if (number.isNotEmpty) Container(width: 2.5, height: 52, color: OneUITheme.accentBlue),
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
  const _Keypad({required this.onKey, required this.onLongPress});

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
  const _Key({required this.digit, required this.letters, required this.onTap, this.onLongPress});

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
        radius: 36,
        highlightShape: BoxShape.circle,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: TextStyle(
                  fontSize: digit == '*' ? 38 : 32,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                  color: OneUITheme.textPrimary,
                ),
              ),
              if (letters == 'VM')
                const Icon(Icons.voicemail_rounded, size: 18, color: OneUITheme.textSecondary)
              else if (letters.isNotEmpty)
                Text(
                  letters,
                  style: const TextStyle(fontSize: 11, letterSpacing: 1.2, color: OneUITheme.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.sims,
    required this.showBackspace,
    required this.onCall,
    required this.onBackspace,
    required this.onClear,
  });

  /// One entry per call button; `null` lets Android pick the SIM.
  final List<SimCard?> sims;
  final bool showBackspace;
  final ValueChanged<SimCard?> onCall;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        for (final sim in sims)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _CallButton(sim: sim, onTap: () => onCall(sim)),
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
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.sim, required this.onTap});

  final SimCard? sim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sim = this.sim;
    return Semantics(
      button: true,
      label: sim == null ? 'Call' : 'Call with ${sim.label}',
      excludeSemantics: true,
      child: Material(
        color: OneUITheme.accentGreen,
        shape: sim == null ? const CircleBorder() : const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: sim == null ? const CircleBorder() : const StadiumBorder(),
          child: SizedBox(
            height: 64,
            width: sim == null ? 64 : 112,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.call_rounded, color: Colors.white, size: 28),
                if (sim != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      sim.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
