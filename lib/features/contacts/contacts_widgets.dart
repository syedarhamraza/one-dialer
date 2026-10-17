import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/swipe_to_call.dart';
import 'call_contact.dart';
import '../../widgets/select_mark.dart';

/// Section header text ("Favorites", "A", "My profile").
class ContactsSectionHeader extends StatelessWidget {
  const ContactsSectionHeader({super.key, required this.title, this.icon});

  static const double height = 48;

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 16, 0),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: OneUITheme.textSecondary), const SizedBox(width: 8)],
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Samsung's favourite tile: tinted card (or the photo), round avatar, name.
class FavoriteTile extends StatelessWidget {
  const FavoriteTile({super.key, required this.contact, required this.onTap, required this.onLongPress});

  final DialerContact contact;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = LetterAvatar.colorFor(contact.name);
    final photo = contact.thumbnail;
    return Semantics(
      button: true,
      label: '${contact.name}, favourite',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(OneUITheme.radiusCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo != null)
                // Cache the blurred photo as a layer instead of re-blurring every frame.
                RepaintBoundary(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Image.memory(
                      photo,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      color: Colors.black.withValues(alpha: 0.2),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.lerp(color, Colors.white, 0.18)!, color],
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (photo != null)
                    ClipOval(
                      child: Image.memory(photo, width: 60, height: 60, fit: BoxFit.cover, gaplessPlayback: true),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
                      ),
                      child: Text(
                        LetterAvatar.initials(contact.name).characters.firstOrNull ?? '#',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w300, color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One contact row inside a section card. Corners round only at the card's ends.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.contact,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
    this.selected,
  });

  static const double height = 54;

  final DialerContact contact;
  final bool isFirst, isLast;
  final VoidCallback onTap, onLongPress;

  /// null when not selecting.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(OneUITheme.radiusCard);
    final row = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      child: Container(
        height: height, // the swipe wrapper loosens the list's fixed extent
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            SelectMark(selected: selected, gap: 14),
            LetterAvatar(name: contact.name, photo: contact.thumbnail, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: height,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10), width: 0.8)),
                ),
                child: Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, letterSpacing: -0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: isFirst ? radius : Radius.zero, bottom: isLast ? radius : Radius.zero),
        child: SwipeToCallOrMessage(
          key: ValueKey('contact-${contact.id}'),
          number: contact.callNumber ?? contact.numbers.first,
          enabled: selected == null,
          child: row,
        ),
      ),
    );
  }
}

/// Samsung's inline quick card shown when a contact is tapped.
class ContactQuickCard extends StatelessWidget {
  const ContactQuickCard({super.key, required this.contact, required this.onInfo});

  static const double height = 196;

  final DialerContact contact;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final i = contact.primaryIndex >= 0 ? contact.primaryIndex : 0;
    return Container(
      height: height - 12,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: OneUITheme.cardBorderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onInfo,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${contact.labels[i]} ${contact.numbers[i]}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: OneUITheme.textSecondary,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: OneUITheme.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              LetterAvatar(name: contact.name, photo: contact.thumbnail, size: 52),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickAction(
                icon: Icons.call_rounded,
                color: OneUITheme.accentGreen,
                label: 'Call',
                onTap: () => callContact(context, contact),
              ),
              _QuickAction(
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF3E9BFF),
                label: 'Message',
                onTap: () async {
                  final n = contact.callNumber ?? await chooseNumber(context, contact);
                  if (n != null) await TelecomBridge.instance.sendSms(n);
                },
              ),
              _QuickAction(icon: Icons.info_rounded, color: OneUITheme.textSecondary, label: 'Details', onTap: onInfo),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(backgroundColor: OneUITheme.surfacePill),
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// Samsung's dotted fast-scroll track: one dot per section, the current one as a blue
/// thumb; dragging shows a big letter bubble and jumps to that section.
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
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              width: 22,
              child: Semantics(
                label: 'Alphabet index',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _pick(d.localPosition.dy, h),
                  onTapUp: (_) => _end(),
                  onVerticalDragUpdate: (d) => _pick(d.localPosition.dy, h),
                  onVerticalDragEnd: (_) => _end(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: OneUITheme.surfaceCard.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: ValueListenableBuilder<String?>(
                      valueListenable: widget.current,
                      builder: (context, current, _) => Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final l in widget.letters)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 4,
                              height: l == (_dragLetter ?? current) ? 18 : 4,
                              decoration: BoxDecoration(
                                color: l == (_dragLetter ?? current) ? OneUITheme.accentBlue : OneUITheme.textTertiary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_dragLetter != null)
              Positioned(
                right: 56,
                top: (_dragY - 45).clamp(0, h - 90),
                child: IgnorePointer(
                  child: Container(
                    width: 90,
                    height: 90,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFF2D5BC0), shape: BoxShape.circle),
                    child: Text(_dragLetter!, style: const TextStyle(fontSize: 46, color: Colors.white)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
