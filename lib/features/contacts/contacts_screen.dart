import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../app/layout.dart';
import '../../app/main_shell.dart' show navDock;
import '../../core/contacts/contacts_repository.dart';
import '../../core/haptics/haptics.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/select_mark.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'contact_actions.dart';
import 'contact_details_screen.dart';
import 'contact_sections.dart';
import 'contacts_widgets.dart';
import 'manage_contacts_screen.dart';
import '../../l10n/l10n.dart';

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
  Set<String>? _selected; // null when not selecting

  /// Bumped when the selection changes but selection mode doesn't, so only the header
  /// and the visible rows' circles rebuild.
  final _selectionChanged = ValueNotifier(0);

  /// The big "Contacts" going under the header, where a small one takes over.
  final _collapse = TitleCollapse(titleTop: 0);

  // Fixed heights, so each section's scroll offset is known without building it.
  static const double _titleHeight = 92;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _collapse.dispose();
    _currentLetter.dispose();
    _selectionChanged.dispose();
    super.dispose();
  }

  // --- Sections, recomputed only when the contacts change ----------------------------

  (List<DialerContact>, Set<String>)? _builtFor;
  List<DialerContact> _shown = const [];
  List<DialerContact> _favourites = const [];
  List<(String, List<DialerContact>)> _sections = const [];
  Map<String, double> _offsets = const {};

  /// The contacts Manage contacts lets through: with numbers only (unless turned off), and
  /// not only in accounts it hides.
  void _section() {
    final prefs = DialerPrefs.instance;
    final repo = ContactsRepository.instance;
    final source = prefs.onlyWithNumbers.value ? repo.contacts.value : repo.allContacts.value;
    final hidden = prefs.hiddenAccounts.value;
    if (_builtFor case (final s, final h) when identical(s, source) && identical(h, hidden)) return;
    _builtFor = (source, hidden);
    final all = _shown = hidden.isEmpty
        ? source
        : [
            for (final c in source)
              if (!(c.accounts.isEmpty ? hidden.contains('|') : c.accounts.every(hidden.contains))) c,
          ];
    _favourites = [
      for (final c in all)
        if (c.isFavorite) c,
    ];
    _sections = [if (_favourites.isNotEmpty) (kFavoritesMark, _favourites), ...sectionContacts(all)];
    // Offsets are measured below the pinned header, which is what `jumpTo` scrolls under.
    var y = _titleHeight;
    final offsets = <String, double>{};
    for (final (letter, list) in _sections) {
      offsets[letter] = y;
      y += ContactsSectionHeader.height + list.length * ContactRow.height;
    }
    _offsets = offsets;
  }

  void _onScroll() {
    final y = _scroll.offset + 8;
    String? current;
    for (final MapEntry(key: letter, value: offset) in _offsets.entries) {
      if (offset <= y) current = letter;
    }
    _currentLetter.value = current;
  }

  // Our details page is built around numbers; Android's shows the rest.
  void _open(DialerContact c) => c.numbers.isEmpty
      ? FlutterContacts.native.showViewer(c.id)
      : Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ContactDetailsScreen(contactId: c.id)));

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
          label: context.l10n.share,
          isEnabled: count > 0,
          onTap: _shareSelected,
        ),
        OneUIFloatingActionBarItem(
          icon: Icons.delete_outline_rounded,
          label: context.l10n.delete,
          color: OneUITheme.accentRed,
          isEnabled: count > 0,
          onTap: _deleteSelected,
        ),
      ],
    );
  }

  bool get _allSelected => _selected?.length == _shown.length;

  void _toggleSelectAll() {
    final all = _shown;
    _selected = _allSelected ? {} : {for (final c in all) c.id};
    _selectionChanged.value++;
    _updateDock();
  }

  Future<void> _shareSelected() async {
    final ids = _selected?.toList() ?? const <String>[];
    if (ids.isEmpty) return;
    final l10n = context.l10n;
    final contacts = await FlutterContacts.getAll(properties: ContactProperties.all, filter: ContactFilter.ids(ids));
    await ContactActions.shareVCards(l10n, contacts);
  }

  Future<void> _deleteSelected() async {
    final ids = _selected?.toList() ?? const <String>[];
    if (ids.isEmpty) return;
    final ok = await showCosConfirm(
      context,
      title: context.l10n.deleteContactsTitle(ids.length),
      message: context.l10n.deleteContactsMessage,
      confirmLabel: context.l10n.delete,
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
      OneUIFloatingMenuItem(label: context.l10n.select, onTap: _startSelection),
      OneUIFloatingMenuItem(
        label: context.l10n.manageContacts,
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ManageContactsScreen())),
      ),
      OneUIFloatingMenuItem(
        label: context.l10n.settings,
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
        listenable: Listenable.merge([
          ContactsRepository.instance.contacts,
          ContactsRepository.instance.allContacts,
          ContactsRepository.instance.hasAccess,
          DialerPrefs.instance.onlyWithNumbers,
          DialerPrefs.instance.hiddenAccounts,
        ]),
        builder: (context, _) => _build(context),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final repo = ContactsRepository.instance;
    _section();
    final all = _shown;
    final selecting = _selected != null;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        NotificationListener<ScrollUpdateNotification>(
          onNotification: _collapse.track,
          child: CustomScrollView(
            controller: _scroll,
            physics: const OneUIScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                // The page's top blur sits behind the header's pills, not over them.
                // Ends at the bar's bottom: the big title right under it stays sharp.
                flexibleSpace: OneUIStatusBarScrim(height: MediaQuery.paddingOf(context).top + kHeaderBarHeight),
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                toolbarHeight: kHeaderBarHeight,
                // The glass press stretches the buttons past the bar; don't cut it off.
                clipBehavior: Clip.none,
                titleSpacing: 0,
                title: ValueListenableBuilder(
                  valueListenable: _selectionChanged,
                  builder: (context, _, _) => Stack(
                    children: [
                      HeaderTitle(collapse: _collapse, text: context.l10n.navContacts, hidden: selecting),
                      _Header(
                        selecting: selecting,
                        allSelected: _allSelected,
                        onToggleSelectAll: _toggleSelectAll,
                        onCancel: _endSelection,
                        menuKey: _menuKey,
                        onMenu: _openMenu,
                      ),
                    ],
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
                          BigTitle(
                            collapse: _collapse,
                            text: selecting ? context.l10n.selectedCount(_selected!.length) : context.l10n.navContacts,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.contactsCount(all.length),
                            style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
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
                        Text(
                          context.l10n.contactsAccessMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.palette.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: repo.requestAccess, child: Text(context.l10n.allow)),
                      ],
                    ),
                  ),
                )
              else ...[
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
        ),
        if (_sections.length > 1)
          Positioned(
            right: 4,
            top: top + kHeaderBarHeight + _titleHeight,
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
                  RoundIconButton(icon: Icons.close_rounded, tooltip: context.l10n.cancel, onTap: onCancel),
                ]
              : [
                  const Spacer(),
                  RoundIconButton(
                    icon: Icons.search_rounded,
                    tooltip: context.l10n.search,
                    onTap: () => openSearch(context),
                  ),
                  const SizedBox(width: 8),
                  // The menu measures this wrapper, outside the glass press, so holding the
                  // button doesn't shift where the menu opens.
                  KeyedSubtree(
                    key: menuKey,
                    child: RoundIconButton(
                      icon: Icons.more_vert_rounded,
                      tooltip: context.l10n.moreOptions,
                      onTap: onMenu,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
