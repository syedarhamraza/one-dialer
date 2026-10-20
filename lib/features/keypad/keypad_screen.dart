import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../recents/call_log_repository.dart';
import '../settings/settings_screen.dart';
import 'speed_dial_screen.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/place_call.dart';
import '../../widgets/press_glow.dart';
import 't9.dart';
import '../in_call/call_controls.dart';

/// Samsung-style dial pad as a sheet over Calls: T9 contact search above while
/// typing, then the typed number, pill keys and one call button. Hidden, the shell
/// shows a green dialpad button beside the nav bar.
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

const double _gap = 10;

final double _blur = OneUIEffectsController.instance.blurSigma;

final _riseSpring = GlassSpringCurve(
  SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: .85),
  const Duration(milliseconds: 450),
);

/// Material's emphasized accelerate, for leaving.
const _dropCurve = Cubic(0.3, 0, 0.8, 0.15);

class _KeypadScreenState extends State<KeypadScreen> with SingleTickerProviderStateMixin {
  final _telecom = TelecomBridge.instance;
  bool _calling = false;

  /// How far the sheet has slid away: 0 up, 1 hidden. Follows the finger while dragged.
  late final _slide = AnimationController(vsync: this, value: widget.open.value ? 0 : 1);
  late final _offset = _slide.drive(Tween(begin: Offset.zero, end: const Offset(0, 1)));
  final _panel = GlobalKey();
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    widget.open.addListener(_settle);
  }

  @override
  void didUpdateWidget(KeypadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
      oldWidget.open.removeListener(_settle);
      widget.open.addListener(_settle);
      _settle();
    }
  }

  @override
  void dispose() {
    widget.open.removeListener(_settle);
    _slide.dispose();
    super.dispose();
  }

  /// Rises on a soft spring that settles without a bounce and drops away quickly, speeding up as
  /// it goes; from wherever a drag let go, for the part of the way that's left.
  void _settle() {
    if (_dragging) return;
    final open = widget.open.value;
    final target = open ? 0.0 : 1.0;
    final left = (target - _slide.value).abs();
    if (MediaQuery.disableAnimationsOf(context) || left == 0) {
      _slide.value = target;
      return;
    }
    _slide.animateTo(
      target,
      duration: Duration(milliseconds: open ? 450 : 240) * left,
      curve: open ? _riseSpring : _dropCurve,
    );
  }

  void _dragStart(DragStartDetails _) {
    _dragging = true;
    _slide.stop();
  }

  void _dragUpdate(DragUpdateDetails d) {
    final height = _panel.currentContext?.size?.height ?? 1;
    _slide.value += d.primaryDelta! / height;
  }

  /// A flick decides by its direction; a slow release by whether the sheet is past halfway.
  void _dragEnd(DragEndDetails d) {
    _dragging = false;
    final velocity = d.primaryVelocity ?? 0;
    final open = velocity.abs() > 700 ? velocity < 0 : _slide.value < .5;
    if (open == widget.open.value) {
      _settle();
    } else {
      widget.open.value = open;
    }
  }

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
                  // Nothing typed: no backdrop, so Calls shows and takes taps. The results start
                  // under the Calls header bar, whose All | Missed pill morphs into Add to
                  // Contacts while typing. They fade in on the first digit and out when the
                  // number is cleared; the outgoing one keeps its last number while it fades.
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + kHeaderBarHeight,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (current, previous) =>
                          Stack(fit: StackFit.expand, children: [...previous, ?current]),
                      child: number.isNotEmpty
                          // Clear backdrop: Calls fades its list out underneath, and the header's
                          // press can stretch down over this space without being covered.
                          ? KeyedSubtree(
                              key: const ValueKey('results'),
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
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    // Keyed so the results appearing above it on the first digit don't rebuild the
                    // sheet, which would cut off the tapped key's press.
                    key: const ValueKey('keypad-sheet'),
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SlideTransition(
                      position: _offset,
                      // Hold anywhere on the sheet, keys included, and slide it down or back up; a
                      // drag cancels the key's tap, so nothing is typed.
                      child: GestureDetector(
                        onVerticalDragStart: _dragStart,
                        onVerticalDragUpdate: _dragUpdate,
                        onVerticalDragEnd: _dragEnd,
                        onVerticalDragCancel: () {
                          if (_dragging) _dragEnd(DragEndDetails());
                        },
                        child: IgnorePointer(
                          ignoring: !open,
                          child: ExcludeSemantics(
                            excluding: !open,
                            // Its own layer, so the slide and the results changing while typing
                            // don't repaint the keys.
                            child: RepaintBoundary(
                              key: _panel,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                                // Frosted like the nav bar: Calls shows blurred behind the keys. Costs a
                                // blur only on frames where something animates.
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
                                    child: DecoratedBox(
                                      key: const ValueKey('keypad-panel'),
                                      decoration: BoxDecoration(
                                        color: OneUITheme.surfaceCard.withValues(alpha: .75),
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
        padding: EdgeInsets.only(top: 4, bottom: bottomPadding),
        itemCount: matches.length,
        itemBuilder: (context, i) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0) Divider(height: 1, indent: 76, color: Colors.white.withValues(alpha: 0.1)),
            _ResultTile(match: matches[i], onTap: () => onPick(matches[i])),
          ],
        ),
      ),
    );
  }
}

/// A T9 match laid out like a Calls row: avatar, name, and the number below, with the
/// matched part in blue.
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.match, required this.onTap});

  final T9Match match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = match.entry.name;
    const nameStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
      color: OneUITheme.textPrimary,
    );
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            LetterAvatar(
              name: name,
              photo: switch (match.entry) {
                DialerContact(:final thumbnail) => thumbnail,
                _ => null,
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unsaved numbers (from Recents) are named by their number; show it once.
                  if (name == match.number)
                    _highlighted(name, match.numberRange, nameStyle)
                  else ...[
                    _highlighted(name, match.nameRange, nameStyle),
                    const SizedBox(height: 2),
                    _highlighted(
                      match.number,
                      match.numberRange,
                      const TextStyle(fontSize: 14, color: OneUITheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
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

/// The sheet's grab handle: tap to hide the keys (dragging is handled by the whole sheet).
class _Handle extends StatelessWidget {
  const _Handle({required this.onHide});
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    // The dialpad pill is the accessible way to hide the keys.
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onHide,
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
        decoration: lit ? solidBody(color, const StadiumBorder(), glow: 0) : null,
        foregroundDecoration: lit ? solidGlow(const StadiumBorder()) : null,
        // The nav bar's call glass without its backdrop blur (a save layer per key), rasterized
        // once so presses and the sheet's slide only draw an image.
        child: lit ? _ink() : CallBodyArtwork(radius: height / 2, glow: kMainGlassGlow, opacity: .75, child: _ink()),
      ),
    ),
  );

  Widget _ink() => Material(
    color: Colors.transparent,
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
              color: OneUITheme.dialGreen,
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

/// The keypad's menu: typing actions while a number is entered, then speed dial and
/// settings. Shown from the Calls header's menu button while typing.
/// The keypad's menu items: typing actions while a number is entered, then speed dial
/// and settings. Shown from the Calls header's menu while typing.
List<OneUIFloatingMenuItem> keypadMenuItems(
  BuildContext context, {
  required ValueNotifier<String> input,
  required ValueNotifier<bool> open,
}) {
  final typing = input.value.isNotEmpty;
  return [
    if (typing) ...[
      OneUIFloatingMenuItem(
        label: open.value ? 'Hide keypad' : 'Show keypad',
        icon: Icons.dialpad_rounded,
        onTap: () => open.value = !open.value,
      ),
      OneUIFloatingMenuItem(label: 'Add 2-sec pause', icon: Icons.pause_rounded, onTap: () => input.value += ','),
      OneUIFloatingMenuItem(label: 'Add wait', icon: Icons.hourglass_empty_rounded, onTap: () => input.value += ';'),
      OneUIFloatingMenuItem(
        label: 'Send message',
        icon: Icons.message_outlined,
        onTap: () => TelecomBridge.instance.sendSms(input.value),
      ),
    ],
    OneUIFloatingMenuItem(
      label: 'Speed dial numbers',
      icon: Icons.speed_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpeedDialScreen())),
    ),
    OneUIFloatingMenuItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
    ),
  ];
}
