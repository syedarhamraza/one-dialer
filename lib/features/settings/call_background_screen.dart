import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/haptics/haptics.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../in_call/call_background.dart';
import '../in_call/call_screen_widgets.dart' show CallBackdrop;

/// Call background, for one contact ([scope] is its id) or every call (`all`): the default
/// tint, the caller's contact photo, a picked photo, or the aurora in one of
/// [CallBackgrounds.swatches], with a preview. A contact's own choice beats the one for all calls,
/// and each page says so.
class CallBackgroundScreen extends StatefulWidget {
  const CallBackgroundScreen({super.key, required this.scope, this.name});

  final String scope;

  /// The contact's name, tinting the default preview the way the call screen does.
  final String? name;

  /// The row value for a saved background; a [contact] without one follows all calls.
  static String label(AppLocalizations l10n, CallBackground? background, {bool contact = false}) =>
      switch (background) {
        null => contact ? l10n.callBackgroundSameAsAll : l10n.callBackgroundDefault,
        CallBackground(contactPhoto: true) => l10n.callBackgroundContactPhoto,
        CallBackground(image: _?) => l10n.callBackgroundPhoto,
        _ => l10n.callBackgroundColour,
      };

  @override
  State<CallBackgroundScreen> createState() => _CallBackgroundScreenState();
}

class _CallBackgroundScreenState extends State<CallBackgroundScreen> {
  final _backgrounds = CallBackgrounds.instance;

  @override
  void initState() {
    super.initState();
    _backgrounds.load(widget.scope);
    _backgrounds.load('all');
    if (!_all) _backgrounds.loadPhoto(widget.scope);
  }

  bool get _all => widget.scope == 'all';

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _backgrounds,
      builder: (context, _) {
        final current = _backgrounds.stored(widget.scope);
        // What a call would show; with no caller to show, "Contact's photo" previews as the default.
        final shown = _all ? (current?.contactPhoto ?? false ? null : current) : _backgrounds.forCall(widget.scope);
        // Choices show a tick or nothing; only Choose photo (it opens the picker) keeps its chevron.
        Widget check(bool on) =>
            on ? const Icon(Icons.check_rounded, color: OneUITheme.dialGreen) : const SizedBox(width: 24);
        // A contact page doesn't offer "Contact's photo" again when all calls already use it: the
        // two would look the same. One saved before then reads as following all calls.
        final allUsePhoto = !_all && (_backgrounds.stored('all')?.contactPhoto ?? false);
        final follows = current == null || (allUsePhoto && current.contactPhoto);
        return CosSubpage(
          title: l10n.callBackground,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: 150,
                  height: 310,
                  child: ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(24),
                    child: CallBackdrop(seed: widget.name, background: shown, child: const SizedBox.expand()),
                  ),
                ),
              ),
            ),
            OneUIGroupCard(
              items: [
                OneUIGroupItem(
                  title: _all ? l10n.callBackgroundDefault : l10n.callBackgroundSameAsAll,
                  // A contact following all calls sees what that is.
                  subtitle: _all ? null : CallBackgroundScreen.label(l10n, _backgrounds.stored('all')),
                  trailing: check(follows),
                  onTap: () => _backgrounds.save(widget.scope),
                ),
                if (!allUsePhoto)
                  OneUIGroupItem(
                    title: l10n.callBackgroundContactPhoto,
                    subtitle: l10n.callBackgroundContactPhotoSubtitle,
                    trailing: check(current?.contactPhoto ?? false),
                    onTap: () => _backgrounds.save(widget.scope, contactPhoto: true),
                  ),
                OneUIGroupItem(
                  title: l10n.callBackgroundChoosePhoto,
                  trailing: current?.image != null ? check(true) : null,
                  onTap: _pickPhoto,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 8, top: 4),
              child: Text(
                l10n.callBackgroundColour,
                style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
              ),
            ),
            DecoratedBox(
              decoration: ShapeDecoration(color: context.palette.card, shape: OneUITheme.cardShape),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final colour in CallBackgrounds.swatches)
                      _Swatch(
                        colour: colour,
                        selected: current?.colour == colour,
                        label: l10n.callBackgroundColour,
                        onTap: () {
                          Haptics.tap();
                          _backgrounds.save(widget.scope, colour: colour);
                        },
                      ),
                  ],
                ),
              ),
            ),
            // The one rule, said where it applies.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(
                _all ? l10n.callBackgroundAllNote : l10n.callBackgroundContactNote,
                style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.colour, required this.selected, required this.label, required this.onTap});

  final Color colour;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: ShapeDecoration(
          shape: CircleBorder(
            side: BorderSide(color: selected ? context.palette.textPrimary : Colors.transparent, width: 2),
          ),
        ),
        child: DecoratedBox(
          decoration: ShapeDecoration(color: colour, shape: const CircleBorder()),
        ),
      ),
    ),
  );
}
