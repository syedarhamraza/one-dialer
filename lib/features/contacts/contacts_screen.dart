import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_big_header.dart';
import '../../widgets/one_ui_floating_nav_bar.dart';
import '../../widgets/swipe_to_call.dart';
import 'contact_details_screen.dart';
import 'contact_sections.dart';

/// Samsung-style Contacts: search, Favourites, A–Z sections with a fast-scroll index,
/// swipe right to call and left to message.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  // Fixed heights so the A–Z index can jump to a section without building it first.
  static const double _rowHeight = 68;
  static const double _sectionHeaderHeight = 44;
  static const double _searchHeight = 64;
  static const double _headerCollapse = OneUIScrollPhysics.bigHeaderCollapse;

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _open(DialerContact contact) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ContactDetailsScreen(contactId: contact.id)),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ContactsRepository.instance.contacts, ContactsRepository.instance.hasAccess]),
      builder: (context, _) {
        final all = ContactsRepository.instance.contacts.value;
        final query = _search.text;
        final searching = query.trim().isNotEmpty;
        final favourites = searching ? const <DialerContact>[] : [for (final c in all) if (c.isFavorite) c];
        final sections = searching
            ? [('Results', searchContacts(all, query))]
            : sectionContacts(all);

        // Scroll offset of each section, for the index.
        final offsets = <String, double>{};
        var y = _headerCollapse + _searchHeight;
        if (favourites.isNotEmpty) y += _sectionHeaderHeight + favourites.length * _rowHeight;
        for (final (letter, list) in sections) {
          offsets[letter] = y;
          y += _sectionHeaderHeight + list.length * _rowHeight;
        }

        return Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              physics: OneUIScrollPhysics.bigHeader,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: OneUIBigHeader(title: 'Contacts', subtitle: '${all.length} contacts with numbers'),
                ),
                SliverToBoxAdapter(child: _SearchBar(controller: _search, onChanged: () => setState(() {}))),
                if (!ContactsRepository.instance.hasAccess.value)
                  SliverToBoxAdapter(
                    child: _AccessNeeded(
                      text: 'Allow access to your contacts to see them here and show names for calls',
                      action: 'Allow',
                      onTap: ContactsRepository.instance.requestAccess,
                    ),
                  ),
                if (favourites.isNotEmpty) ..._section('Favourites', favourites),
                for (final (letter, list) in sections) ..._section(letter, list),
                if (searching && sections.single.$2.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: Text('No contacts found', style: TextStyle(color: OneUITheme.textSecondary))),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).bottom + OneUIFloatingNavBar.barHeight + 32),
                ),
              ],
            ),
            if (!searching && sections.length > 1)
              Positioned(
                right: 0,
                top: MediaQuery.paddingOf(context).top + 120,
                bottom: MediaQuery.paddingOf(context).bottom + OneUIFloatingNavBar.barHeight + 24,
                child: _IndexStrip(
                  letters: [for (final (l, _) in sections) l],
                  onLetter: (l) {
                    HapticFeedback.selectionClick();
                    final max = _scroll.position.maxScrollExtent;
                    _scroll.jumpTo(offsets[l]!.clamp(0, max));
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _section(String title, List<DialerContact> list) => [
        SliverToBoxAdapter(
          child: SizedBox(
            height: _sectionHeaderHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 16, 0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: OneUITheme.sectionHeader,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 28), // room for the A–Z index
          sliver: SliverFixedExtentList(
            itemExtent: _rowHeight,
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ContactRow(
                contact: list[i],
                isFirst: i == 0,
                isLast: i == list.length - 1,
                onTap: () => _open(list[i]),
              ),
              childCount: list.length,
            ),
          ),
        ),
      ];
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ContactsScreenState._searchHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 28, 12), // right: clear of the A–Z index
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search_rounded, color: OneUITheme.textSecondary),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded, color: OneUITheme.textSecondary),
                          onPressed: () {
                            controller.clear();
                            onChanged();
                          },
                        ),
                  filled: true,
                  fillColor: OneUITheme.surfaceCard,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: OneUITheme.pillBorderRadius, borderSide: BorderSide.none),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Create contact',
              icon: const Icon(Icons.add_rounded, size: 28),
              onPressed: ContactsRepository.instance.addNumber,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.isFirst, required this.isLast, required this.onTap});

  final DialerContact contact;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(OneUITheme.radiusCard);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: isFirst ? radius : Radius.zero, bottom: isLast ? radius : Radius.zero),
      child: SwipeToCallOrMessage(
        key: ValueKey('contact-${contact.id}'),
        number: contact.numbers.first,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.06),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: Container(
            height: _ContactsScreenState._rowHeight, // Dismissible loosens the list's fixed extent
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.8)),
            ),
            child: Row(
              children: [
                LetterAvatar(name: contact.name, photo: contact.thumbnail),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, letterSpacing: -0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical A–Z strip: tap or drag to jump to a section.
class _IndexStrip extends StatelessWidget {
  const _IndexStrip({required this.letters, required this.onLetter});

  final List<String> letters;
  final ValueChanged<String> onLetter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void pick(double dy) {
          final i = (dy / constraints.maxHeight * letters.length).floor().clamp(0, letters.length - 1);
          onLetter(letters[i]);
        }

        return Semantics(
          label: 'Alphabet index',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition.dy),
            onVerticalDragUpdate: (d) => pick(d.localPosition.dy),
            child: SizedBox(
              width: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final l in letters)
                    Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Explains missing access, with one button to grant it.
class _AccessNeeded extends StatelessWidget {
  const _AccessNeeded({required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 40, color: OneUITheme.textSecondary),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: OneUITheme.textSecondary)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
