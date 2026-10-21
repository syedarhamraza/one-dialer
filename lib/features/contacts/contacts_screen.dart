import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../app/layout.dart';
import '../../app/main_shell.dart' show navDock;
import '../../core/contacts/contacts_repository.dart';
import '../../core/haptics/haptics.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/select_mark.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'contact_actions.dart';
import 'contact_details_screen.dart';
import 'contact_sections.dart';
import 'contacts_widgets.dart';
import 'groups_screen.dart';

/// The Contacts tab in the Calls tab's style (ColorOS layout): glass search and menu,
/// a big title, a card with My contact card and Groups, favourites under a star, then
/// A–Z rows with a letter index. Tap opens the contact; long-press selects.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _scroll = ScrollController();
  final _menuKey = GlobalKey();
  final _currentLetter = ValueNotifier<String?>(null);
  Contact? _profile;
  Set<String>? _selected; // null when not selecting

  /// Bumped when the selection changes but selection mode doesn't, so only the header
  /// and the visible rows' circles rebuild.
  final _selectionChanged = ValueNotifier(0);

  // Fixed heights, so each section's scroll offset is known without building it.
  static const double _titleHeight = 92;
  static const double _cardRowHeight = 60;
  static const double _cardBottom = 8;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    FlutterContacts.profile
        .get(properties: {ContactProperty.name, ContactProperty.photoThumbnail})
        .then((p) {
          if (mounted) setState(() => _profile = p);
        })
        .catchError((Object _) {}); // no "Me" profile on this phone
  }

  @override
  void dispose() {
    _scroll.dispose();
    _currentLetter.dispose();
    _selectionChanged.dispose();
    super.dispose();
  }

  // --- Sections, recomputed only when the contacts or the profile row change -------

  (List<DialerContact>, bool)? _builtFor;
  List<DialerContact> _favourites = const [];
  List<(String, List<DialerContact>)> _sections = const [];
  Map<String, double> _offsets = const {};

  void _section(List<DialerContact> all) {
    final key = (all, _profile != null);
    if (_builtFor case (final list, final profile) when identical(list, all) && profile == key.$2) return;
    _builtFor = key;
    _favourites = [
      for (final c in all)
        if (c.isFavorite) c,
    ];
    _sections = [if (_favourites.isNotEmpty) (kFavoritesMark, _favourites), ...sectionContacts(all)];
    // Offsets are measured below the pinned header, which is what `jumpTo` scrolls under.
    var y = _titleHeight + _topCardHeight;
    final offsets = <String, double>{};
    for (final (letter, list) in _sections) {
      offsets[letter] = y;
      y += ContactsSectionHeader.height + list.length * ContactRow.height;
    }
    _offsets = offsets;
  }

  double get _topCardHeight => (_profile == null ? 1 : 2) * _cardRowHeight + _cardBottom;

  void _onScroll() {
    final y = _scroll.offset + 8;
    String? current;
    for (final MapEntry(key: letter, value: offset) in _offsets.entries) {
      if (offset <= y) current = letter;
    }
    _currentLetter.value = current;
  }

  void _open(DialerContact c) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ContactDetailsScreen(contactId: c.id)));

  // --- Selection ---------------------------------------------------------------

  void _startSelection([DialerContact? first]) {
    Haptics.longPress();
    setState(() => _selected = {?first?.id});
    _updateDock();
  }

  void _toggleSelected(DialerContact c) {
    final s = _selected!;
    s.contains(c.id) ? s.remove(c.id) : s.add(c.id);
    _selectionChanged.value++;
    _updateDock();
  }

  void _endSelection() {
    setState(() => _selected = null);
    navDock.value = null;
  }

  /// OneSpend's selection mode: a glass bar of these actions springs in over the tab bar.
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

  bool get _allSelected => _selected?.length == ContactsRepository.instance.contacts.value.length;

  void _toggleSelectAll() {
    final all = ContactsRepository.instance.contacts.value;
    _selected = _allSelected ? {} : {for (final c in all) c.id};
    _selectionChanged.value++;
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
    final ok = await showCosConfirm(
      context,
      title: ids.length == 1 ? 'Delete contact?' : 'Delete ${ids.length} contacts?',
      message: 'They will be removed from this phone and from their accounts.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ContactsRepository.instance.delete(ids);
    _endSelection();
  }

  void _openMenu() => OneUIFloatingMenu.show(
    context: context,
    anchorKey: _menuKey,
    width: 250,
    items: [
      OneUIFloatingMenuItem(label: 'Select', onTap: _startSelection),
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
        builder: (context, _) => _build(context),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final repo = ContactsRepository.instance;
    final all = repo.contacts.value;
    _section(all);
    final selecting = _selected != null;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        CustomScrollView(
          controller: _scroll,
          physics: const OneUIScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              toolbarHeight: kHeaderBarHeight,
              // The glass press stretches the buttons past the bar; don't cut it off.
              clipBehavior: Clip.none,
              titleSpacing: 0,
              title: ValueListenableBuilder(
                valueListenable: _selectionChanged,
                builder: (context, _, _) => _Header(
                  selecting: selecting,
                  allSelected: _allSelected,
                  onToggleSelectAll: _toggleSelectAll,
                  onCancel: _endSelection,
                  menuKey: _menuKey,
                  onMenu: _openMenu,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: _titleHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: ValueListenableBuilder(
                    valueListenable: _selectionChanged,
                    builder: (context, _, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selecting ? '${_selected!.length} selected' : 'Contacts',
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${all.length} contacts',
                          style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
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
              )
            else ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _topCardHeight,
                  child: _TopCard(
                    profile: _profile,
                    onGroups: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GroupsScreen())),
                  ),
                ),
              ),
              for (final (letter, list) in _sections) ...[
                SliverToBoxAdapter(child: ContactsSectionHeader(title: letter)),
                // Lazy, fixed-extent rows: only the ones on screen are built.
                SliverFixedExtentList.builder(
                  itemExtent: ContactRow.height,
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return ContactRow(
                      contact: c,
                      isLast: i == list.length - 1,
                      selecting: selecting,
                      selectMark: ValueListenableBuilder(
                        valueListenable: _selectionChanged,
                        builder: (context, _, _) => SelectMark(selected: _selected?.contains(c.id), gap: 12),
                      ),
                      onTap: () => _selected != null ? _toggleSelected(c) : _open(c),
                      onLongPress: () => _selected != null ? _toggleSelected(c) : _startSelection(c),
                    );
                  },
                ),
              ],
            ],
            SliverToBoxAdapter(child: SizedBox(height: navBarClearance(context) + 8)),
          ],
        ),
        if (_sections.length > 1)
          Positioned(
            right: 4,
            top: top + kHeaderBarHeight + _titleHeight + _topCardHeight,
            bottom: navBarClearance(context),
            width: 140,
            child: FastScroller(
              letters: [for (final (l, _) in _sections) l],
              current: _currentLetter,
              onLetter: (l) => _scroll.jumpTo(_offsets[l]!.clamp(0, _scroll.position.maxScrollExtent)),
            ),
          ),
      ],
    );
  }
}

/// The Calls header's controls: glass search and menu; while selecting, a select-all
/// pill on the left and Cancel on the right.
class _Header extends StatelessWidget {
  const _Header({
    required this.selecting,
    required this.allSelected,
    required this.onToggleSelectAll,
    required this.onCancel,
    required this.menuKey,
    required this.onMenu,
  });

  final bool selecting;
  final bool allSelected;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onCancel;
  final GlobalKey menuKey;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
      child: Padding(
        key: ValueKey(selecting),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: selecting
              ? [
                  CallGlass(
                    radius: 24,
                    child: SizedBox(
                      width: 100,
                      height: 48,
                      child: SelectAllCount(allSelected: allSelected, onTap: onToggleSelectAll),
                    ),
                  ),
                  const Spacer(),
                  RoundIconButton(icon: Icons.close_rounded, tooltip: 'Cancel', onTap: onCancel),
                ]
              : [
                  const Spacer(),
                  RoundIconButton(icon: Icons.search_rounded, tooltip: 'Search', onTap: () => openSearch(context)),
                  const SizedBox(width: 8),
                  // The menu measures this wrapper, outside the glass press, so holding the
                  // button doesn't shift where the menu opens.
                  KeyedSubtree(
                    key: menuKey,
                    child: RoundIconButton(icon: Icons.more_vert_rounded, tooltip: 'More options', onTap: onMenu),
                  ),
                ],
        ),
      ),
    );
  }
}

/// My contact card (when the phone has a profile) and Groups, in one card.
class _TopCard extends StatelessWidget {
  const _TopCard({required this.profile, required this.onGroups});

  final Contact? profile;
  final VoidCallback onGroups;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final photo = p?.photo?.thumbnail;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, _ContactsScreenState._cardBottom),
      child: Material(
        color: OneUITheme.surfaceCard,
        borderRadius: OneUITheme.cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (p != null) ...[
              _CardRow(
                leading: photo != null
                    ? LetterAvatar(name: p.displayName ?? '', photo: photo, size: 40)
                    : const _GreenIcon(Icons.person_rounded),
                title: 'My contact card',
              ),
              Divider(height: 1, indent: 70, color: Colors.white.withValues(alpha: 0.1)),
            ],
            _CardRow(leading: const _GreenIcon(Icons.group_rounded), title: 'My groups', onTap: onGroups),
          ],
        ),
      ),
    );
  }
}

class _GreenIcon extends StatelessWidget {
  const _GreenIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(color: OneUITheme.dialGreen, shape: BoxShape.circle),
    child: Icon(icon, color: Colors.white, size: 22),
  );
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.leading, required this.title, this.onTap});

  final Widget leading;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: _ContactsScreenState._cardRowHeight - 0.5,
        child: Row(
          children: [
            const SizedBox(width: 16),
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
