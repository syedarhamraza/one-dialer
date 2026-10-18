import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../app/layout.dart';
import '../../app/main_shell.dart' show navDock;
import '../../core/contacts/contacts_repository.dart';
import '../../core/haptics/haptics.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_scroll_to_top_button.dart';
import '../settings/settings_screen.dart';
import 'contact_details_screen.dart';
import 'contact_sections.dart';
import 'contacts_widgets.dart';
import 'editor/contact_editor_screen.dart';
import 'groups_screen.dart';
import '../search/search_screen.dart';
import 'contact_actions.dart';
import '../../widgets/one_ui_selection_header_pills.dart';

/// Samsung-style Contacts tab: favourite tiles, My profile, Groups, A–Z section cards
/// with an inline quick card on tap, a dotted fast scroller and multi-select delete.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _scroll = ScrollController();
  final _menuKey = GlobalKey();
  final _currentLetter = ValueNotifier<String?>(null);
  final _showLetterPill = ValueNotifier(false);
  final _showScroller = ValueNotifier(false);
  Timer? _pillTimer;

  String? _expandedId;
  Set<String>? _selected; // null when not selecting
  bool _favoritesAsList = false;
  Contact? _profile;

  // Fixed heights, so section offsets are known without building the slivers.
  static const double _cardGap = 14;
  static const double _tileSpacing = 10;
  static const double _tileAspect = 0.86;
  static const double _headerScroll = OneUIScrollPhysics.bigHeaderCollapse;
  Map<String, double> _offsets = const {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    DialerPrefs.instance.changes.addListener(_loadPrefs);
    _loadPrefs();
    FlutterContacts.profile
        .get(properties: {ContactProperty.name, ContactProperty.photoThumbnail})
        .then((p) {
          if (mounted) setState(() => _profile = p);
        })
        .catchError((Object _) {}); // no "Me" profile on this phone
  }

  @override
  void dispose() {
    DialerPrefs.instance.changes.removeListener(_loadPrefs);
    _pillTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final asList = await DialerPrefs.instance.favoritesAsList();
    if (mounted && asList != _favoritesAsList) setState(() => _favoritesAsList = asList);
  }

  void _onScroll() {
    // The section under the pinned top bar is the current one.
    final y = _scroll.offset + 100;
    // Like Samsung, the fast scroller appears once the A–Z list is on screen.
    final firstSection = _offsets.values.firstOrNull;
    _showScroller.value = firstSection != null && _scroll.offset > firstSection - 600;
    String? current;
    for (final MapEntry(key: letter, value: offset) in _offsets.entries) {
      if (offset <= y) current = letter;
    }
    _currentLetter.value = current;
    // Small letter pill under the status bar while scrolling the list, like Samsung.
    if (current != null) {
      _showLetterPill.value = true;
      _pillTimer?.cancel();
      _pillTimer = Timer(const Duration(milliseconds: 900), () => _showLetterPill.value = false);
    }
  }

  void _open(DialerContact c) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ContactDetailsScreen(contactId: c.id)));

  void _toggleExpanded(DialerContact c) {
    Haptics.tap();
    setState(() => _expandedId = _expandedId == c.id ? null : c.id);
  }

  // --- Selection ---------------------------------------------------------------

  void _startSelection([DialerContact? first]) {
    Haptics.longPress();
    setState(() {
      _expandedId = null;
      _selected = {?first?.id};
    });
    _updateDock();
  }

  void _toggleSelected(DialerContact c) {
    setState(() {
      final s = _selected!;
      s.contains(c.id) ? s.remove(c.id) : s.add(c.id);
    });
    _updateDock();
  }

  void _endSelection() {
    setState(() => _selected = null);
    navDock.value = null;
  }

  /// OneSpend's selection mode: All and Cancel live in the header pills; a glass bar
  /// of these actions springs in over the tab bar.
  void _updateDock() {
    final count = _selected?.length ?? 0;
    navDock.value = OneUIFloatingActionBar(
      docked: true,
      items: [
        OneUIFloatingActionBarItem(
          icon: Icons.share_outlined,
          label: 'Share',
          isEnabled: count > 0,
          onTap: _shareSelected,
        ),
        OneUIFloatingActionBarItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          color: OneUITheme.accentRed,
          isEnabled: count > 0,
          onTap: _deleteSelected,
        ),
      ],
    );
  }

  void _toggleSelectAll() {
    final all = ContactsRepository.instance.contacts.value;
    setState(() => _selected = _selected?.length == all.length ? {} : {for (final c in all) c.id});
    _updateDock();
  }

  Future<void> _shareSelected() async {
    final ids = _selected?.toList() ?? const <String>[];
    if (ids.isEmpty) return;
    final contacts = await FlutterContacts.getAll(properties: ContactProperties.all, filter: ContactFilter.ids(ids));
    await ContactActions.shareVCards(contacts);
  }

  Future<void> _deleteSelected() async {
    final ids = _selected?.toList() ?? const <String>[];
    if (ids.isEmpty) return;
    final ok = await OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: ids.length == 1 ? 'Delete contact?' : 'Delete ${ids.length} contacts?',
      message: 'They will be removed from this phone and from their accounts.',
      confirmTextColor: OneUITheme.accentRed,
    );
    if (ok != true) return;
    await ContactsRepository.instance.delete(ids);
    _endSelection();
  }

  // --- Menu and search ---------------------------------------------------------

  void _openMenu() => OneUIFloatingMenu.show(
    context: context,
    anchorKey: _menuKey,
    width: 250,
    items: [
      OneUIFloatingMenuItem(label: 'Select', onTap: _startSelection),
      OneUIFloatingMenuItem(
        label: _favoritesAsList ? 'View favorites as tiles' : 'View favorites as list',
        onTap: () => DialerPrefs.instance.setFavoritesAsList(!_favoritesAsList),
      ),
      OneUIFloatingMenuItem(
        label: 'Settings',
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
      ),
    ],
  );

  // --- Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSelection();
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([ContactsRepository.instance.contacts, ContactsRepository.instance.hasAccess]),
        builder: (context, _) => LayoutBuilder(builder: (context, size) => _build(context, size.maxWidth)),
      ),
    );
  }

  Widget _build(BuildContext context, double width) {
    final repo = ContactsRepository.instance;
    final all = repo.contacts.value;
    final favourites = [
      for (final c in all)
        if (c.isFavorite) c,
    ];
    final sections = sectionContacts(all);
    final selecting = _selected != null;

    // Heights of the blocks above the A–Z list.
    final tileHeight = (width - 20 - _tileSpacing * 2) / 3 / _tileAspect;
    final favHeight = favourites.isEmpty
        ? 0.0
        : ContactsSectionHeader.height +
              (_favoritesAsList
                  ? favourites.length * ContactRow.height
                  : (favourites.length / 3).ceil() * (tileHeight + _tileSpacing) - _tileSpacing);
    final profileHeight = _profile == null ? 0.0 : ContactsSectionHeader.height + ContactRow.height;
    const groupsHeight = _cardGap + ContactRow.height;

    double rowExtent(DialerContact c) => c.id == _expandedId ? ContactQuickCard.height : ContactRow.height;

    // Scroll offset where each letter section starts, for the fast scroller.
    final offsets = <String, double>{};
    var y = _headerScroll + favHeight + profileHeight + groupsHeight;
    for (final (letter, list) in sections) {
      offsets[letter] = y;
      y += ContactsSectionHeader.height + list.fold(0.0, (sum, c) => sum + rowExtent(c));
    }
    _offsets = offsets;

    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        CustomScrollView(
          controller: _scroll,
          physics: OneUIScrollPhysics.bigHeader,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: OneUICollapsibleHeaderDelegate(
                title: selecting ? '${_selected!.length} selected' : 'Phone',
                subtitle: selecting
                    ? (_selected!.length == all.length ? 'All selected • Tap (O) to deselect' : 'Tap (O) to select all')
                    : '${all.length} contacts',
                isSelectionMode: selecting,
                selectionLeading: selecting
                    ? OneUISelectionCountPill(
                        selectedCount: _selected!.length,
                        totalCount: all.length,
                        onToggleSelectAll: _toggleSelectAll,
                      )
                    : null,
                onSelectionCancel: selecting ? _endSelection : null,
                actionsPillKey: _menuKey,
                actions: selecting
                    ? null
                    : [
                        OneUIHeaderAction(
                          icon: Icons.add_rounded,
                          tooltip: 'Create contact',
                          onTap: () => openContactEditor(context),
                        ),
                        OneUIHeaderAction(
                          icon: Icons.search_rounded,
                          tooltip: 'Search',
                          onTap: () => openSearch(context),
                        ),
                        OneUIHeaderAction(icon: Icons.more_vert_rounded, tooltip: 'More options', onTap: _openMenu),
                      ],
              ),
            ),
            if (!repo.hasAccess.value)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                  child: Column(
                    children: [
                      const Text(
                        'Allow access to your contacts to see them here and show names for calls',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: OneUITheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: repo.requestAccess, child: const Text('Allow')),
                    ],
                  ),
                ),
              ),
            if (favourites.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: ContactsSectionHeader(title: 'Favorites', icon: Icons.star_rounded),
              ),
              if (_favoritesAsList)
                _rows(favourites, selecting)
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: _tileSpacing,
                      crossAxisSpacing: _tileSpacing,
                      childAspectRatio: _tileAspect,
                    ),
                    itemCount: favourites.length,
                    itemBuilder: (context, i) => FavoriteTile(
                      contact: favourites[i],
                      onTap: () => selecting ? _toggleSelected(favourites[i]) : _open(favourites[i]),
                      onLongPress: () => _startSelection(favourites[i]),
                    ),
                  ),
                ),
            ],
            if (_profile case final profile?) ...[
              const SliverToBoxAdapter(child: ContactsSectionHeader(title: 'My profile')),
              SliverToBoxAdapter(child: _ProfileRow(profile: profile)),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: _cardGap),
                child: _GroupsRow(
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GroupsScreen())),
                ),
              ),
            ),
            for (final (letter, list) in sections) ...[
              SliverToBoxAdapter(child: ContactsSectionHeader(title: letter)),
              _rows(list, selecting),
            ],
            SliverToBoxAdapter(child: SizedBox(height: navBarClearance(context) + 40)),
          ],
        ),
        if (sections.length > 1)
          Positioned(
            right: 0,
            top: top + 110,
            bottom: navBarClearance(context),
            width: 160,
            child: ValueListenableBuilder<bool>(
              valueListenable: _showScroller,
              builder: (context, show, child) => IgnorePointer(
                ignoring: !show,
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
              ),
              child: FastScroller(
                letters: [for (final (l, _) in sections) l],
                current: _currentLetter,
                onLetter: (l) => _scroll.jumpTo(offsets[l]!.clamp(0, _scroll.position.maxScrollExtent)),
              ),
            ),
          ),
        // The current letter while scrolling, once the big header has collapsed.
        Positioned(
          top: top + 70,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: Listenable.merge([_showLetterPill, _currentLetter]),
              builder: (context, _) {
                final visible =
                    _showLetterPill.value &&
                    _currentLetter.value != null &&
                    _scroll.hasClients &&
                    _scroll.offset > _headerScroll + 40;
                return AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: OneUITheme.surfacePill,
                        borderRadius: OneUITheme.pillBorderRadius,
                      ),
                      child: Text(_currentLetter.value ?? '', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: navBarClearance(context) - 8,
          child: Center(child: OneUIScrollToTopButton(scrollController: _scroll)),
        ),
      ],
    );
  }

  /// A section card of contact rows; the tapped contact opens as a quick card in place.
  Widget _rows(List<DialerContact> list, bool selecting) {
    return SliverVariedExtentList.builder(
      itemCount: list.length,
      itemExtentBuilder: (i, _) => list[i].id == _expandedId ? ContactQuickCard.height : ContactRow.height,
      itemBuilder: (context, i) {
        final c = list[i];
        if (c.id == _expandedId) return ContactQuickCard(contact: c, onInfo: () => _open(c));
        // The card breaks around an open quick card, like Samsung.
        final isFirst = i == 0 || list[i - 1].id == _expandedId;
        final isLast = i == list.length - 1 || list[i + 1].id == _expandedId;
        return ContactRow(
          contact: c,
          isFirst: isFirst,
          isLast: isLast,
          selected: selecting ? _selected!.contains(c.id) : null,
          onTap: () => selecting ? _toggleSelected(c) : _toggleExpanded(c),
          onLongPress: () => selecting ? _toggleSelected(c) : _startSelection(c),
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile});

  final Contact profile;

  @override
  Widget build(BuildContext context) {
    final name = (profile.displayName?.trim().isNotEmpty ?? false) ? profile.displayName!.trim() : 'Me';
    return _CardRow(
      leading: LetterAvatar(name: name, photo: profile.photo?.thumbnail, size: 36),
      title: name,
    );
  }
}

class _GroupsRow extends StatelessWidget {
  const _GroupsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardRow(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: Color(0xFFD9D9DE), shape: BoxShape.circle),
        child: const Icon(Icons.group_rounded, color: Colors.white, size: 20),
      ),
      title: 'Groups',
    );
  }
}

/// A single-row rounded card (My profile, Groups).
class _CardRow extends StatelessWidget {
  const _CardRow({required this.leading, required this.title, this.onTap});

  final Widget leading;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: OneUITheme.surfaceCard,
        borderRadius: OneUITheme.cardBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: OneUITheme.cardBorderRadius,
          child: SizedBox(
            height: ContactRow.height,
            child: Row(
              children: [
                const SizedBox(width: 18),
                leading,
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
