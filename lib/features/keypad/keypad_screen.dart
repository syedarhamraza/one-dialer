import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../core/diagnostics/lag_diagnostics.dart';
import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_toast.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../theme/one_ui_scroll.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../recents/call_log_repository.dart';
import '../settings/settings_screen.dart';
import 'speed_dial_screen.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/place_call.dart';
import '../../widgets/press_glow.dart';
import '../../widgets/rise_route.dart';
import 't9.dart';
import '../in_call/call_controls.dart';
import '../../l10n/l10n.dart';

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

class _KeypadScreenState extends State<KeypadScreen> {
  final _telecom = TelecomBridge.instance;
  final _callKey = GlobalKey();
  bool _calling = false;

  /// Only set on dual SIM with no default SIM, where the SIM choice applies.
  // shortcut: read once per launch; re-read on resume if SIM hot-swap matters.
  List<SimCard> _askSims = const [];

  @override
  void initState() {
    super.initState();
    _telecom.getSims().then((sims) {
      if (mounted && sims.length > 1 && !sims.any((s) => s.isDefault)) setState(() => _askSims = sims);
    });
  }

  /// The last search, so showing/hiding the sheet or opening a menu doesn't search again.
  (String, List<DialerContact>, List<T9Match>)? _search;

  List<T9Match> _matches(String number, List<DialerContact> contacts) {
    if (_search case (final n, final c, final m) when n == number && identical(c, contacts)) return m;
    final matches = t9Search(number, contacts);
    _search = (number, contacts, matches);
    return matches;
  }

  /// The keys don't depend on the number; one instance per key height lets each digit skip rebuilding them.
  _Keypad? _keys;

  void _show() => widget.open.value = true;

  void _hide() => widget.open.value = false;

  /// Scrolling the results drops the keys so the whole list shows.
  void _collapse() {
    if (widget.input.value.isNotEmpty && mounted) _hide();
  }

  void _type(String key) {
    LagDiagnostics.instance.screen('keypad');
    LagDiagnostics.instance.action(DiagnosticAction.keypad);
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
    final assign = await showCosConfirm(
      context,
      title: context.l10n.speedDialNoNumber,
      message: context.l10n.speedDialAssignPrompt(digit),
      confirmLabel: context.l10n.assign,
    );
    if (assign && mounted) _openSpeedDial();
  }

  void _openSpeedDial() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpeedDialScreen()));

  void _backspace() {
    LagDiagnostics.instance.action(DiagnosticAction.backspace);
    final text = widget.input.value;
    if (text.isNotEmpty) widget.input.value = text.substring(0, text.length - 1);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = data?.text?.replaceAll(RegExp(r'[^0-9+*#,;]'), '') ?? '';
    if (digits.isNotEmpty) widget.input.value += digits;
  }

  Future<void> _call([String? simId]) async {
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
      final called = await placeCall(context, number, simId: simId, anchorKey: _callKey);
      if (called && widget.input.value == number) widget.input.value = '';
    } on PlatformException {
      if (mounted) {
        OneUIToast.show(context, context.l10n.couldNotPlaceCall);
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.input, widget.open, DialerPrefs.instance.simChoice]),
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
                                  matches: _matches(number, contacts),
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
                    // Rises on a soft spring that settles without a bounce, and drops away
                    // quickly, speeding up as it goes.
                    child: AnimatedSlide(
                      offset: Offset(0, open ? 0 : 1),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : Duration(milliseconds: open ? 450 : 240),
                      curve: open ? kSheetRise : kSheetDrop,
                      child: IgnorePointer(
                        ignoring: !open,
                        child: ExcludeSemantics(
                          excluding: !open,
                          // Its own layer, so the slide and the results changing while typing
                          // don't repaint the keys.
                          child: RepaintBoundary(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                              // Frosted like the nav bar: Calls shows blurred behind the keys. Costs a
                              // blur only on frames where something animates.
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                child: _Frosted(
                                  builder: (blur) => DecoratedBox(
                                    key: const ValueKey('keypad-panel'),
                                    decoration: BoxDecoration(
                                      color: _sheetColor(context).withValues(alpha: blur ? .75 : 1),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                                    ),
                                    // Scrolls only when a small or landscape screen can't fit it.
                                    child: SingleChildScrollView(
                                      physics: const HoldStillScrollPhysics(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _Handle(onHide: _hide),
                                          if (number.isNotEmpty) _NumberDisplay(number: number, onPaste: _paste),
                                          _keys = _keys?.keyHeight == keyHeight
                                              ? _keys!
                                              : _Keypad(onKey: _type, onLongPress: _longPress, keyHeight: keyHeight),
                                          const SizedBox(height: _gap),
                                          _CallRow(
                                            keyHeight: keyHeight,
                                            callKey: _callKey,
                                            sims: DialerPrefs.instance.simChoice.value == 'buttons'
                                                ? _askSims
                                                : const [],
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
            if (i > 0) Divider(height: 1, indent: 76, color: context.palette.divider),
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
    final nameStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
      color: context.palette.textPrimary,
    );
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            switch (match.entry) {
              DialerContact(:final id) => ContactAvatar(id: id, name: name),
              _ => LetterAvatar(name: name),
            },
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
                      TextStyle(fontSize: 14, color: context.palette.textSecondary),
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
      label: number.isEmpty ? context.l10n.keypadNumberEmpty : context.l10n.keypadNumber(number),
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
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      color: context.palette.textPrimary,
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
              color: context.palette.textSecondary.withValues(alpha: 0.5),
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
                        '0' => context.l10n.keypadZeroHint,
                        '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9' => context.l10n.keypadDigitHint(digit),
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
                              fontSize: digit == '*' ? 34 : 30,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: context.palette.textPrimary,
                            ),
                          ),
                          if (letters == 'VM')
                            Icon(Icons.voicemail_rounded, size: 14, color: context.palette.textSecondary)
                          else if (letters.isNotEmpty)
                            Text(letters, style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
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
    super.key,
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
    child: ListenableBuilder(
      listenable: OneUIEffectsController.instance,
      builder: (context, _) {
        final fx = OneUIEffectsController.instance;
        if (lit) return LitButton(color: color, shape: const StadiumBorder(), child: _ink());
        return PressGlow(
          // Below full visual effects light mode is flat One UI: no shadows.
          shadows: context.palette.isLight && fx.isFull ? OneUIPalette.lightGlassShadow : null,
          child: fx.isFull
              // The nav bar's call glass without its backdrop blur (a save layer per key), rasterized
              // once so presses and the sheet's slide only draw an image.
              ? CallBodyArtwork(
                  radius: height / 2,
                  glow: kMainGlassGlow,
                  opacity: mainGlass(context, classicOpacity: .75).opacity,
                  edges: mainGlass(context).edges,
                  child: _ink(),
                )
              // Below full: a flat One UI key, translucent over the sheet when reduced, solid when off.
              : _ink(fx.oneUIFill(light: context.palette.isLight)),
        );
      },
    ),
  );

  Widget _ink([Color fill = Colors.transparent]) => Material(
    color: fill,
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
    required this.callKey,
    required this.sims,
    required this.onHide,
    required this.onCall,
    required this.onBackspace,
    required this.onClear,
  });

  final double keyHeight;
  final GlobalKey callKey;

  /// One Call key per SIM (the `buttons` SIM choice); empty for a single Call key.
  final List<SimCard> sims;
  final VoidCallback onHide;
  final void Function([String? simId])? onCall;
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
              label: context.l10n.hideKeypad,
              onTap: onHide,
              child: Icon(Icons.dialpad_rounded, color: context.palette.textPrimary, size: 30),
            ),
          ),
          if (sims.isEmpty)
            Expanded(
              child: _Pill(
                key: callKey,
                height: keyHeight,
                label: context.l10n.call,
                color: OneUITheme.dialGreen,
                lit: true,
                onTap: onCall,
                child: const Icon(Icons.call_rounded, color: Colors.white, size: 38),
              ),
            )
          else
            // Samsung's dual-SIM keys, numbered by slot: twice the Call key's room, so the
            // bottom row is four equal pills instead of two squeezed into one.
            Expanded(
              flex: 2,
              child: Row(
                spacing: _gap,
                children: [
                  for (final (i, sim) in sims.take(2).indexed)
                    Expanded(
                      child: _Pill(
                        height: keyHeight,
                        label: context.l10n.callWithSim('${i + 1}', sim.label),
                        color: OneUITheme.dialGreen,
                        lit: true,
                        onTap: onCall == null ? null : () => onCall!(sim.id),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.call_rounded, color: Colors.white, size: 34),
                            const SizedBox(width: 2),
                            Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _Pill(
              height: keyHeight,
              label: context.l10n.keypadDeleteHint,
              onTap: onBackspace,
              onLongPress: onClear,
              child: Icon(Icons.backspace_rounded, color: context.palette.textSecondary, size: 30),
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
        label: open.value ? context.l10n.hideKeypad : context.l10n.showKeypad,
        onTap: () => open.value = !open.value,
      ),
      OneUIFloatingMenuItem(label: context.l10n.addPause, onTap: () => input.value += ','),
      OneUIFloatingMenuItem(label: context.l10n.addWait, onTap: () => input.value += ';'),
      OneUIFloatingMenuItem(label: context.l10n.sendMessage, onTap: () => TelecomBridge.instance.sendSms(input.value)),
    ],
    OneUIFloatingMenuItem(
      label: context.l10n.speedDialNumbers,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpeedDialScreen())),
    ),
    OneUIFloatingMenuItem(
      label: context.l10n.settings,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
    ),
  ];
}

/// The sheet's frosted backing: Calls blurred behind the keys, and a solid backing with
/// visual effects off. Switches live.
/// The sheet behind the keys: the page grey in light mode, the card grey in dark mode, or (with the
/// soft and bold dark glass) that grey halfway to black, so the half-strength keys still stand out.
Color _sheetColor(BuildContext context) {
  final palette = context.palette;
  if (palette.isLight) return palette.page;
  final fx = OneUIEffectsController.instance;
  if (!fx.isFull || fx.glassStyle(light: false) == 'classic') return palette.card;
  return Color.lerp(palette.card, Colors.black, .5)!;
}

class _Frosted extends StatelessWidget {
  const _Frosted({required this.builder});
  final Widget Function(bool blur) builder;

  @override
  Widget build(BuildContext context) {
    final fx = OneUIEffectsController.instance;
    return ListenableBuilder(
      listenable: fx,
      builder: (context, _) {
        if (fx.isOff) return builder(false);
        return BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: fx.blurSigma, sigmaY: fx.blurSigma),
          child: builder(true),
        );
      },
    );
  }
}
