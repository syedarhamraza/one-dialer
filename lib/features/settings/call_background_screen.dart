import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/haptics/haptics.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_switch.dart';
import '../../widgets/showcase_picker.dart';
import '../in_call/call_background.dart';
import '../in_call/call_screen_widgets.dart' show CallBackdrop;
import 'call_settings_pages.dart' show previewCallButtons;
import 'backup_screen.dart';

/// Call background, for one contact ([scope] is its id) or every call (`all`), as ColorOS 17's
/// illustrated choice: three little ringing phones (Aurora, Contact's photo, Photo), each showing
/// what a call would look like, then only the settings of the picked one (the aurora's colour,
/// Change photo, Blur & dim). A contact page starts with Same as all calls; off, the contact's
/// own choice beats the one for all calls.
class CallBackgroundScreen extends StatefulWidget {
  const CallBackgroundScreen({super.key, required this.scope, this.name});

  final String scope;

  /// The contact's name, tinting the aurora the way the call screen does.
  final String? name;

  /// The row value for a saved background; a [contact] without one follows all calls.
  static String label(AppLocalizations l10n, CallBackground? background, {bool contact = false}) =>
      switch (background) {
        null => contact ? l10n.callBackgroundSameAsAll : l10n.callBackgroundDefault,
        CallBackground(contactPhoto: true) => l10n.callBackgroundContactPhoto,
        CallBackground(image: _?) => l10n.callBackgroundPhoto,
        CallBackground(colour: _?) => l10n.callBackgroundColour,
        _ => l10n.callBackgroundDefault,
      };

  @override
  State<CallBackgroundScreen> createState() => _CallBackgroundScreenState();
}

/// The three choices, as [ShowcasePicker] values.
const _aurora = 'aurora', _contact = 'contact', _photo = 'photo';

String _kindOf(CallBackground? background) => switch (background) {
  CallBackground(contactPhoto: true) => _contact,
  CallBackground(image: _?) => _photo,
  _ => _aurora,
};

/// A sample caller's photo colours, for Contact's photo on the all-calls page (no caller to show).
const _sampleTones = [Color(0xFFE0782E), Color(0xFFE0782E), Color(0xFF4F7A3A), Color(0xFFD9A441), Color(0xFF4F7A3A)];

/// Sample callers for Auto on the all-calls page, shown in turn so it reads as "each caller's own
/// colours" rather than one colour: an initial and that caller's aurora colours.
const _sampleCallers = [
  ('A', [Color(0xFF1FA3A0), Color(0xFF1FA3A0), Color(0xFFE0A93A), Color(0xFF2F80ED), Color(0xFFE0A93A)]),
  ('B', [Color(0xFF3D6FE0), Color(0xFF3D6FE0), Color(0xFF7A4FE0), Color(0xFF2FA3C9), Color(0xFF7A4FE0)]),
  ('H', [Color(0xFFD9467A), Color(0xFFD9467A), Color(0xFF2FA89A), Color(0xFFE07AA8), Color(0xFF2FA89A)]),
];

class _CallBackgroundScreenState extends State<CallBackgroundScreen> {
  final _backgrounds = CallBackgrounds.instance;
  final _kind = ValueNotifier(_aurora);

  /// Which of [_sampleCallers] the all-calls Aurora phone shows.
  int _sample = 0;
  Timer? _samples;

  bool get _all => widget.scope == 'all';

  /// A contact without a choice of their own.
  bool get _follows => !_all && _backgrounds.stored(widget.scope) == null;

  /// The choice that applies on this page: the contact's own, or all calls' while following.
  CallBackground? get _effective => _backgrounds.stored(widget.scope) ?? (_all ? null : _backgrounds.stored('all'));

  @override
  void initState() {
    super.initState();
    _backgrounds.addListener(_sync);
    _backgrounds.load(widget.scope);
    _backgrounds.load('all');
    if (!_all) {
      _backgrounds.loadPhoto(widget.scope);
      _backgrounds.loadTones(widget.scope);
    }
    _sync();
    if (_all) {
      _samples = Timer.periodic(const Duration(milliseconds: 2200), (_) {
        if (mounted) setState(() => _sample = (_sample + 1) % _sampleCallers.length);
      });
    }
  }

  @override
  void dispose() {
    _backgrounds.removeListener(_sync);
    _kind.dispose();
    _samples?.cancel();
    super.dispose();
  }

  void _sync() => _kind.value = _kindOf(_effective);

  Future<void> _pickPhoto() async {
    try {
      // At the screen's own resolution (Android keeps contact photos at ~720 px): it fills the screen.
      final screen = View.of(context).physicalSize;
      final bytes = await TelecomBridge.instance.pickPhoto(max: math.max(1440, screen.longestSide.round()));
      if (bytes != null) await _backgrounds.save(widget.scope, photo: bytes);
    } on PlatformException {
      // No picker on this phone, or it failed: the background stays as it was.
    }
  }

  void _pick(String kind) {
    switch (kind) {
      case _aurora:
        // A contact's own Aurora must still be stored, or it would read as following all calls.
        _backgrounds.save(widget.scope, auto: !_all);
      case _contact:
        _backgrounds.save(widget.scope, contactPhoto: true);
      case _photo:
        // The photo picked before comes back; only without one does the picker open.
        _backgrounds.useKeptPhoto(widget.scope).then((used) {
          if (!used && mounted) _pickPhoto();
        });
    }
  }

  /// Same as all calls off: all calls' choice becomes the contact's own, so nothing changes yet.
  Future<void> _setFollows(bool follows) async {
    if (follows) return _backgrounds.save(widget.scope);
    final all = _backgrounds.stored('all');
    switch (all) {
      case CallBackground(contactPhoto: true, :final soft):
        await _backgrounds.save(widget.scope, contactPhoto: true, soft: soft);
      case CallBackground(image: final FileImage image, :final soft):
        try {
          await _backgrounds.save(widget.scope, photo: await image.file.readAsBytes(), soft: soft);
        } on FileSystemException {
          await _backgrounds.save(widget.scope, auto: true);
        }
      case CallBackground(colour: final colour?):
        await _backgrounds.save(widget.scope, colour: colour);
      default:
        await _backgrounds.save(widget.scope, auto: true);
    }
  }

  /// The caller's small photo in a preview: this contact's, or a stand-in on the all-calls page.
  Widget _avatar({String? name}) {
    final photo = _all ? null : _backgrounds.photo(widget.scope);
    return LetterAvatar(name: name ?? widget.name ?? '', size: 24, photo: photo);
  }

  /// What a call shows for [kind], given the current choice [shown] (its colour, photo and blur).
  Widget _phone(String kind, CallBackground? shown) {
    final tones = _all ? null : _backgrounds.tones(widget.scope);
    final callerPhoto = _all ? null : _backgrounds.photo(widget.scope);
    final soft = shown?.soft ?? false;
    // All calls, Auto: the sample callers in turn, each in their own colours.
    final sample = _all && kind == _aurora && shown?.colour == null ? _sampleCallers[_sample] : null;
    final (CallBackground? background, bool avatar, Widget? overlay) = switch (kind) {
      _aurora => (shown?.colour != null ? shown : null, true, null),
      _contact when callerPhoto != null => (CallBackground.image(MemoryImage(callerPhoto), soft: soft), soft, null),
      // No caller photo to show: the aurora in the photo's colours, as a call without one.
      // On a contact without a photo: the aurora in their name's colour, as their call shows.
      _contact when !_all => (null, true, null),
      // All calls: a stand-in photo filling the screen, in a sample photo's colours.
      _contact => (
        null,
        soft,
        Align(
          alignment: const Alignment(0, -.05),
          child: Icon(Icons.person_rounded, size: 84, color: Colors.white.withValues(alpha: soft ? .12 : .3)),
        ),
      ),
      _ when shown?.image != null => (shown, true, null),
      // Not in use, but kept: Photo shows it, and picking Photo brings it back.
      _ when _backgrounds.kept(widget.scope) != null => (_backgrounds.kept(widget.scope), true, null),
      _ => (null, true, const Center(child: Icon(Icons.add_rounded, color: Colors.white70, size: 30))),
    };
    return PhonePreview(
      background: CallBackdrop(
        seed: widget.name,
        tones: switch (kind) {
          _ when sample != null => sample.$2,
          _photo when background == null => List.filled(5, const Color(0xFF3A3A3C)),
          _contact when _all => _sampleTones,
          _ => tones,
        },
        background: background,
        child: const SizedBox.expand(),
      ),
      // No small photo when the photo fills the screen, but the same left-aligned name.
      avatar: avatar ? _avatar(name: sample?.$1) : const SizedBox(),
      child: Stack(children: [?overlay, previewCallButtons]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _backgrounds,
      builder: (context, _) {
        final shown = _effective;
        final follows = _follows;
        final kind = _kindOf(shown);
        OneUIGroupItem softRow(CallBackground current) => OneUIGroupItem(
          title: l10n.callBackgroundSoft,
          subtitle: l10n.callBackgroundSoftSubtitle,
          trailing: OneUISwitch(value: current.soft, onChanged: (on) => _backgrounds.setSoft(widget.scope, on)),
          onTap: () => _backgrounds.setSoft(widget.scope, !current.soft),
        );
        return CosSubpage(
          title: l10n.callBackground,
          children: [
            if (!_all)
              OneUIGroupCard(
                items: [
                  OneUIGroupItem(
                    title: l10n.callBackgroundSameAsAll,
                    subtitle: CallBackgroundScreen.label(l10n, _backgrounds.stored('all')),
                    trailing: OneUISwitch(value: follows, onChanged: _setFollows),
                    onTap: () => _setFollows(!follows),
                  ),
                ],
              ),
            if (!_all) const SizedBox(height: 16),
            ShowcasePicker(
              value: _kind,
              enabled: !follows,
              onPick: _pick,
              footnote: _all ? l10n.callBackgroundAllNote : l10n.callBackgroundContactNote,
              options: [
                for (final (value, label) in [
                  (_aurora, l10n.callBackgroundAurora),
                  (_contact, l10n.callBackgroundContactPhoto),
                  (_photo, l10n.callBackgroundPhoto),
                ])
                  ShowcaseOption(value: value, label: label, preview: _phone(value, shown)),
              ],
            ),
            // Only the picked choice's settings, and none while following all calls.
            if (!follows)
              ...switch ((kind, shown)) {
                (_aurora, _) => [
                  _ColourCard(current: shown?.colour, onAuto: () => _pick(_aurora), scope: widget.scope),
                ],
                (_contact, final current?) => [
                  OneUIGroupCard(items: [softRow(current)]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Text(
                      l10n.callBackgroundContactPhotoSubtitle,
                      style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary),
                    ),
                  ),
                ],
                (_photo, final current?) => [
                  OneUIGroupCard(
                    items: [
                      OneUIGroupItem(title: l10n.callBackgroundChangePhoto, onTap: _pickPhoto),
                      softRow(current),
                    ],
                  ),
                  // Picked photos live only in the app's storage: an uninstall loses them.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l10n.callBackgroundPhotoBackupNote} '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: Semantics(
                              link: true,
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.of(context)
                                        .push(MaterialPageRoute<void>(builder: (_) => const BackupScreen())),
                                child: Text(
                                  l10n.callBackgroundPhotoBackupLink,
                                  style: TextStyle(fontSize: 13.5, color: OneUITheme.accentBlue),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary),
                    ),
                  ),
                ],
                _ => const <Widget>[],
              },
          ],
        );
      },
    );
  }
}

/// The aurora's colour: Auto (the caller's photo or name colours) or one of
/// [CallBackgrounds.swatches].
class _ColourCard extends StatelessWidget {
  const _ColourCard({required this.current, required this.onAuto, required this.scope});

  final Color? current;
  final VoidCallback onAuto;
  final String scope;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18, bottom: 8),
          child: Text(l10n.callBackgroundColour, style: TextStyle(fontSize: 15, color: context.palette.textSecondary)),
        ),
        DecoratedBox(
          decoration: ShapeDecoration(color: context.palette.card, shape: OneUITheme.cardShape),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Swatch(
                  selected: current == null,
                  label: l10n.callBackgroundAuto,
                  onTap: onAuto,
                  // A wheel of the swatches: colours that follow the caller.
                  fill: const SweepGradient(colors: [...CallBackgrounds.swatches, Color(0xFF2F80ED)]),
                ),
                for (final colour in CallBackgrounds.swatches)
                  _Swatch(
                    selected: current == colour,
                    label: l10n.callBackgroundColour,
                    onTap: () => CallBackgrounds.instance.save(scope, colour: colour),
                    fill: LinearGradient(colors: [colour, colour]),
                  ),
              ],
            ),
          ),
        ),
        // Auto is no colour of its own: say what the preview shows.
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Text(
            current == null ? l10n.callBackgroundAutoNote : l10n.callBackgroundColourNote,
            style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.fill, required this.selected, required this.label, required this.onTap});

  final Gradient fill;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      onTap: () {
        if (selected) return;
        Haptics.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: ShapeDecoration(
          shape: CircleBorder(
            side: BorderSide(color: selected ? context.palette.textPrimary : Colors.transparent, width: 2),
          ),
        ),
        child: DecoratedBox(
          decoration: ShapeDecoration(gradient: fill, shape: const CircleBorder()),
        ),
      ),
    ),
  );
}
