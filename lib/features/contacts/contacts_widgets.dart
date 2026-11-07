import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../l10n/l10n.dart';

/// Favourites' star, shared by their section header and the letter index.
const kFavoritesMark = '★';
const _favoriteStar = Color(0xFFF7A93B);

/// A section's small heading: a letter, or the favourites' star.
class ContactsSectionHeader extends StatelessWidget {
  const ContactsSectionHeader({super.key, required this.title});

  static const double height = 36;

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 22, bottom: 4),
      alignment: Alignment.bottomLeft,
      child: title == kFavoritesMark
          ? const Icon(Icons.star_rounded, size: 18, color: _favoriteStar)
          : Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.palette.textSecondary),
            ),
    );
  }
}

/// A contact row laid out like a Calls row: flat on black, avatar, name, and a divider
/// that starts at the name. Same structure in and out of selection mode.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.contact,
    required this.isLast,
    required this.selectMark,
    this.highlight,
    required this.onTap,
    required this.onLongPress,
  });

  /// Fixed, so the list can use a fixed-extent sliver and section offsets are known.
  static const double height = 75; // ColorOS 17 Contacts' row pitch

  final DialerContact contact;
  final bool isLast;

  /// The selection box and the selected row's background, which alone listen to selection taps.
  final Widget selectMark;
  final Widget? highlight;
  final VoidCallback onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: context.palette.textPrimary.withValues(alpha: 0.06),
      highlightColor: context.palette.textPrimary.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            ContactAvatar(id: contact.id, name: contact.name),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: height,
                alignment: Alignment.centerLeft,
                // The divider and the name stop short of the letter index on the right.
                margin: const EdgeInsets.only(right: 36),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.2),
                      ),
                    ),
                    selectMark,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final highlight = this.highlight;
    if (highlight == null) return row;
    return Stack(
      children: [
        Positioned.fill(child: highlight),
        row,
      ],
    );
  }
}

/// ColorOS's letter index down the right edge: tap or drag to jump to a section. The
/// current section's letter is green; dragging shows a big letter bubble beside it.
class FastScroller extends StatefulWidget {
  const FastScroller({super.key, required this.letters, required this.current, required this.onLetter});

  final List<String> letters;
  final ValueListenable<String?> current;
  final ValueChanged<String> onLetter;

  @override
  State<FastScroller> createState() => _FastScrollerState();
}

class _FastScrollerState extends State<FastScroller> {
  String? _dragLetter;
  double _dragY = 0;

  void _pick(double dy, double height) {
    final i = (dy / height * widget.letters.length).floor().clamp(0, widget.letters.length - 1);
    final letter = widget.letters[i];
    if (letter != _dragLetter) {
      HapticFeedback.selectionClick();
      widget.onLetter(letter);
    }
    setState(() {
      _dragLetter = letter;
      _dragY = dy;
    });
  }

  void _end() => setState(() => _dragLetter = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Up to 22 dp a letter, squeezed on short screens.
        final cell = (h / widget.letters.length).clamp(0.0, 22.0);
        final column = cell * widget.letters.length;
        final top = (h - column) / 2;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 0,
              top: top,
              height: column,
              width: 28,
              child: Semantics(
                label: context.l10n.alphabetIndex,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _pick(d.localPosition.dy, column),
                  onTapUp: (_) => _end(),
                  onVerticalDragUpdate: (d) => _pick(d.localPosition.dy, column),
                  onVerticalDragEnd: (_) => _end(),
                  onVerticalDragCancel: _end,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: widget.current,
                    builder: (context, current, _) => Column(
                      children: [
                        for (final l in widget.letters)
                          SizedBox(
                            height: cell,
                            child: Center(
                              child: Text(
                                l,
                                style: TextStyle(
                                  fontSize: (cell * .62).clamp(6.0, 13.0),
                                  fontWeight: FontWeight.w500,
                                  color: l == (_dragLetter ?? current)
                                      ? OneUITheme.accentGreen
                                      : context.palette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_dragLetter != null)
              Positioned(
                right: 56,
                top: (top + _dragY - 40).clamp(0, h - 80),
                child: IgnorePointer(
                  child: Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: OneUITheme.accentGreen, shape: BoxShape.circle),
                    child: Text(_dragLetter!, style: const TextStyle(fontSize: 40, color: Colors.white)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
