import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../app/main_shell.dart' show navDock;
import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../theme/one_ui_scroll.dart';

import '../../widgets/cos_dialog.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/place_call.dart';
import '../contacts/editor/add_to_contacts.dart';
import '../in_call/call_controls.dart';
import '../keypad/keypad_screen.dart';
import '../settings/settings_screen.dart';
import 'call_details_screen.dart';
import 'app_calls.dart';
import 'call_log.dart';
import 'call_log_repository.dart';
import 'delete_calls.dart';
import '../search/search_screen.dart';
import '../../widgets/select_mark.dart';
import '../blocking/blocking_repository.dart';
import '../../l10n/l10n.dart';

/// Samsung-style Recents: calls grouped by day, All / Missed filter, swipe right to
/// call and left to message, tap for details, long-press to multi-select and delete.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key, this.dialInput, this.keypadOpen});

  /// The keypad's typed number and open state, from the shell. While a number is
  /// typed the header's All | Missed pill morphs into Add to Contacts and the menu
  /// shows the keypad's actions.
  final ValueNotifier<String>? dialInput;
  final ValueNotifier<bool>? keypadOpen;

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  static final _noInput = ValueNotifier('');
  final _repo = CallLogRepository.instance;
  final _menuKey = GlobalKey();
  final _addKey = GlobalKey();
  CallFilter _filter = CallFilter.all;

  /// Only calls VoIP apps (WhatsApp...) shared with the call log; combines with All/Missed.
  bool _appsOnly = false;
  bool _hideBlocked = true;
  Set<int>? _selected; // call ids; null when not selecting

  /// Bumped when the selection changes but selection mode doesn't, so only the
  /// header count and the visible rows' checkboxes rebuild, not the whole list.
  final _selectionChanged = ValueNotifier(0);

  /// The big "Calls" going under the header, where a small one takes over.
  final _collapse = TitleCollapse(titleTop: 0);
  List<SimCard> _sims = const [];

  /// Saved call notes by number key, shown under the rows' numbers.
  Map<String, List<(DateTime, String)>> _notes = const {};

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getSims().then((s) {
      if (mounted) setState(() => _sims = s);
    });
    DialerPrefs.instance.changes.addListener(_loadPrefs);
    // The call screen saves notes in its own engine; a call being logged is the cue to look.
    _repo.calls.addListener(_loadNotes);
    _loadPrefs();
  }

  Future<void> _loadNotes() async {
    final notes = await DialerPrefs.instance.noteIndex();
    if (mounted) setState(() => _notes = notes);
  }

  /// The newest note taken during one of [group]'s calls.
  String? _noteFor(CallGroup group) {
    final call = group.latest;
    final notes = _notes[call.isPrivate || numberKey(call.number).isEmpty ? 'private' : numberKey(call.number)];
    if (notes == null) return null;
    String? newest;
    DateTime? newestAt;
    for (final (at, text) in notes) {
      if ((newestAt == null || at.isAfter(newestAt)) && group.calls.any((c) => noteDuring(c, at))) {
        newest = text;
        newestAt = at;
      }
    }
    return newest;
  }

  @override
  void dispose() {
    DialerPrefs.instance.changes.removeListener(_loadPrefs);
    _repo.calls.removeListener(_loadNotes);
    _selectionChanged.dispose();
    _collapse.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    _loadNotes();
    final hide = await DialerPrefs.instance.hideBlockedCalls();
    if (mounted && hide != _hideBlocked) setState(() => _hideBlocked = hide);
  }

  List<OneUIFloatingMenuItem> _menuItems() => [
    if (widget.dialInput case final input?)
      OneUIFloatingMenuItem(
        label: context.l10n.paste,
        onTap: () async {
          await pasteNumber(input);
          if (input.value.isNotEmpty) widget.keypadOpen?.value = true;
        },
      ),
    // Only offered once an app has shared calls (Android 16.1+ with the app's call-log integration).
    if (_appsOnly || _repo.calls.value.any((c) => c.isApp))
      OneUIFloatingMenuItem(
        label: _appsOnly ? context.l10n.showAllCalls : context.l10n.showAppCallsOnly,
        onTap: () => setState(() => _appsOnly = !_appsOnly),
      ),
    OneUIFloatingMenuItem(
      label: _hideBlocked ? context.l10n.showBlockedCalls : context.l10n.hideBlockedCalls,
      onTap: () => DialerPrefs.instance.setHideBlockedCalls(!_hideBlocked),
    ),
    OneUIFloatingMenuItem(
      label: context.l10n.settings,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
    ),
  ];

  void _toggle(CallGroup group) {
    final ids = group.calls.map((c) => c.id);
    final entering = _selected == null;
    final selected = _selected ??= {};
    if (ids.every(selected.contains)) {
      selected.removeAll(ids);
    } else {
      selected.addAll(ids);
    }
    if (selected.isEmpty) {
      _endSelection();
    } else if (entering) {
      setState(() {});
      _updateDock();
    } else {
      _selectionChanged.value++;
    }
  }

  void _endSelection() {
    setState(() => _selected = null);
    navDock.value = null;
  }

  /// OneSpend's selection mode: All and Cancel live in the header pills; a glass bar
  /// of the actions springs in over the tab bar (same as Contacts).
  void _updateDock() {
    if (_selected == null) {
      navDock.value = null;
      return;
    }
    navDock.value = OneUIFloatingActionBar(
      docked: true,
      items: [
        OneUIFloatingActionBarItem(icon: Icons.block_rounded, label: context.l10n.block, onTap: _blockSelected),
        OneUIFloatingActionBarItem(
          icon: Icons.delete_outline_rounded,
          label: context.l10n.delete,
          color: OneUITheme.accentRed,
          onTap: _deleteSelected,
        ),
      ],
    );
  }

  /// Rows (call groups), which is what the user sees and counts.
  Iterable<CallGroup> get _rows => _groupedDays.expand((d) => d.$2);

  int get _selectedRows => _rows.where((g) => _selected?.contains(g.latest.id) ?? false).length;

  void _toggleSelectAll() {
    final all = _selectedRows == _rows.length;
    _selected = all ? {} : {for (final c in _visibleCalls) c.id};
    _selectionChanged.value++;
  }

  Future<void> _deleteSelected() async {
    final ids = _selected;
    if (ids == null || ids.isEmpty) return;
    await confirmDeleteCalls(context, ids, onConfirmed: _endSelection);
  }

  Future<void> _blockSelected() async {
    final ids = _selected ?? const {};
    final numbers = {
      for (final g in _rows)
        if (ids.contains(g.latest.id) && !g.latest.isPrivate && g.latest.number.isNotEmpty) g.latest.number,
    };
    if (numbers.isEmpty) return;
    final ok = await showCosConfirm(
      context,
      title: numbers.length == 1
          ? context.l10n.blockNumberTitle(numbers.single)
          : context.l10n.blockNumbersTitle(numbers.length),
      message: context.l10n.blockNumbersMessage,
      confirmLabel: context.l10n.block,
      destructive: true,
    );
    if (!ok) return;
    for (final n in numbers) {
      await BlockingRepository.instance.setBlocked(n, true);
    }
    _endSelection();
  }

  /// "1"/"2" badge, only on dual-SIM phones.
  String? _simBadge(String? simId) {
    if (_sims.length < 2 || simId == null) return null;
    final i = _sims.indexWhere((s) => s.id == simId);
    return i < 0 ? null : '${i + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final selecting = _selected != null;
    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSelection();
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _repo.calls,
          _repo.hasAccess,
          ContactsRepository.instance.contacts,
          BlockingRepository.instance.numbers,
        ]),
        builder: (context, _) => _buildList(context),
      ),
    );
  }

  List<CallLogEntry> get _visibleCalls => [
    for (final c in _repo.calls.value)
      if (_filter.matches(c, hideBlocked: _hideBlocked) &&
          (!_appsOnly || c.isApp) &&
          !(_hideBlocked && !c.isPrivate && BlockingRepository.instance.isBlocked(c.number)))
        c,
  ];

  // groupByDay is only redone when the calls or the filter change, not on every selection tap.
  (List<CallLogEntry>, CallFilter, bool, List<String>, bool)? _groupedFor;
  List<(DateTime, List<CallGroup>)> _days = const [];

  List<(DateTime, List<CallGroup>)> get _groupedDays {
    final key = (_repo.calls.value, _filter, _hideBlocked, BlockingRepository.instance.numbers.value, _appsOnly);
    final old = _groupedFor;
    if (old == null ||
        !identical(old.$1, key.$1) ||
        old.$2 != key.$2 ||
        old.$3 != key.$3 ||
        !identical(old.$4, key.$4) ||
        old.$5 != key.$5) {
      _groupedFor = key;
      _days = groupByDay(_visibleCalls);
    }
    return _days;
  }

  Widget _buildList(BuildContext context) {
    final groups = [for (final (_, g) in _groupedDays) ...g];
    final now = DateTime.now();
    final selecting = _selected != null;
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: _collapse.track,
      child: CustomScrollView(
        physics: const OneUIScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            // The page's top blur sits behind the header's pills, not over them.
            // Ends at the bar's bottom: the big title right under it stays sharp.
            flexibleSpace: OneUIStatusBarScrim(height: MediaQuery.paddingOf(context).top + headerBarHeight(context)),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            toolbarHeight: headerBarHeight(context),
            // The glass press stretches the pills past the bar; don't cut it off.
            clipBehavior: Clip.none,
            titleSpacing: 0,
            title: ListenableBuilder(
              listenable: Listenable.merge([widget.dialInput ?? _noInput, _selectionChanged]),
              builder: (context, _) {
                final number = (widget.dialInput ?? _noInput).value;
                final controls = _HeaderControls(
                  typing: number.isNotEmpty,
                  selecting: selecting,
                  filterIndex: _filter == CallFilter.missed ? 1 : 0,
                  onFilter: (i) => setState(() => _filter = i == 1 ? CallFilter.missed : CallFilter.all),
                  onAdd: () => showAddToContacts(context, number, anchorKey: _addKey),
                  addKey: _addKey,
                  allSelected: selecting && _selectedRows == _rows.length,
                  onToggleSelectAll: _toggleSelectAll,
                  onCancel: _endSelection,
                  menuKey: _menuKey,
                  menuItems: () => number.isEmpty
                      ? _menuItems()
                      : keypadMenuItems(context, input: widget.dialInput!, open: widget.keypadOpen!),
                );
                return LayoutBuilder(
                  builder: (context, box) {
                    final scale = headerScale(context);
                    // With big top buttons (a small App size) All | Missed slides left beside Search; the small title
                    // gives way if it would reach it. The controls are laid out at width / scale.
                    final tabsLeft = _HeaderControls.tabsLeftFor(box.maxWidth / scale) * scale;
                    final clash = HeaderTitle.rightEdge(context, context.l10n.navCalls) + 8 > tabsLeft;
                    return Stack(
                      children: [
                        HeaderTitle(
                          collapse: _collapse,
                          text: context.l10n.navCalls,
                          hidden: selecting || number.isNotEmpty || clash,
                        ),
                        scaledToWidth(scale, controls),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // While a number is typed the keypad's results take this space: the list fades
          // out under them (their backdrop is clear, so the header's press isn't covered).
          ValueListenableBuilder(
            valueListenable: widget.dialInput ?? _noInput,
            builder: (context, number, list) => SliverIgnorePointer(
              ignoring: number.isNotEmpty,
              sliver: SliverAnimatedOpacity(
                opacity: number.isEmpty ? 1 : 0,
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
                sliver: list!,
              ),
            ),
            child: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: ValueListenableBuilder(
                      valueListenable: _selectionChanged,
                      builder: (context, _, _) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        layoutBuilder: (current, previous) =>
                            Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                        child: BigTitle(
                          collapse: _collapse,
                          text: selecting ? context.l10n.selectedCount(_selectedRows) : context.l10n.navCalls,
                          // Keyed on the mode only, so the count updates in place.
                          key: ValueKey(selecting),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_repo.hasAccess.value)
                  _Empty(
                    icon: Icons.lock_outline_rounded,
                    text: context.l10n.recentsSetDefaultMessage,
                    action: (
                      context.l10n.setAsDefault,
                      () async {
                        await TelecomBridge.instance.requestDefaultDialer();
                        await _repo.start();
                      },
                    ),
                  )
                else if (groups.isEmpty)
                  _Empty(
                    text: _appsOnly
                        ? context.l10n.recentsNoAppCalls
                        : _filter == CallFilter.all
                        ? context.l10n.recentsNoRecentCalls
                        : context.l10n.recentsNoMissedCalls, // the tabs offer only All and Missed
                  )
                else
                  // Lazy: only the rows on screen are built.
                  SliverList.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, i) => _row(context, groups, i, now),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: navBarClearance(context) + 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, List<CallGroup> groups, int i, DateTime now) {
    final group = groups[i];
    final call = group.latest;
    final day = dayLabel(context.l10n, call.date, now);
    void details() => openCallDetails(context, call);
    // What a tap does is the Settings choice (DialerPrefs.recentTap): open the details page,
    // write the number in the keypad so the call is one more, deliberate tap, or (dual SIM)
    // pick a SIM from our menu and call.
    void tap(BuildContext row) {
      if (_selected != null) return _toggle(group);
      if (call.isApp) {
        showAppCallBack(context, call, anchorContext: row);
        return;
      }
      final choice = DialerPrefs.instance.recentTap.value;
      final callable = !call.isPrivate && call.number.isNotEmpty;
      if (choice == 'sim' && callable && _sims.length > 1) {
        placeCall(context, call.number, chooseSim: true, anchorContext: row);
      } else if (choice == 'dial' && callable && widget.dialInput != null) {
        widget.dialInput!.value = call.number;
        widget.keypadOpen?.value = true;
      } else {
        widget.keypadOpen?.value = false;
        details();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (i > 0) Divider(height: 1, indent: 76, color: context.palette.divider),
        Builder(
          // The SIM menu pops from this row.
          builder: (row) => _CallRow(
            group: group,
            simBadge: _simBadge(call.simId),
            note: _noteFor(group),
            when: day == context.l10n.today ? timeLabel(context.l10n, call.date) : day,
            selecting: _selected != null,
            // Only the circle listens to selection taps; the rest of the row stays built.
            selectMark: ValueListenableBuilder(
              valueListenable: _selectionChanged,
              builder: (context, _, _) => SelectMark(selected: _selected?.contains(call.id), gap: 12),
            ),
            onTap: () => tap(row),
            onInfo: details,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _toggle(group);
            },
          ),
        ),
      ],
    );
  }
}

/// The Calls header, one set of glass controls that morph between three states
/// instead of swapping:
/// - normal: All | Missed centred, search and menu on the right;
/// - typing: the pill shrinks and slides into a round Add to Contacts beside search;
/// - selecting: the pill slides to the left edge and becomes the select-all count,
///   search slides into menu and fades, and menu turns into Cancel (×).
class _HeaderControls extends StatelessWidget {
  const _HeaderControls({
    required this.typing,
    required this.selecting,
    required this.filterIndex,
    required this.onFilter,
    required this.onAdd,
    required this.addKey,
    required this.allSelected,
    required this.onToggleSelectAll,
    required this.onCancel,
    required this.menuKey,
    required this.menuItems,
  });

  final bool typing;
  final bool selecting;
  final int filterIndex;
  final ValueChanged<int> onFilter;
  final VoidCallback onAdd;
  final GlobalKey addKey;
  final bool allSelected;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onCancel;
  final GlobalKey menuKey;
  final List<OneUIFloatingMenuItem> Function() menuItems;

  static const _tabCount = 2; // All | Missed
  static const double _button = 48;
  static const double _gap = 8;
  static const double _edge = 16;
  static const double _countWidth = 100;

  static final _morphSpring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 240, ratio: .78),
    const Duration(milliseconds: 550),
  );

  /// First half of a morph: the old content fades out; second half: the new fades in.
  static double _out(double t) => (1 - t * 2).clamp(0.0, 1.0);
  static double _in(double t) => (t * 2 - 1).clamp(0.0, 1.0);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Where All | Missed starts in a header [w] wide: centred, or beside Search when centred would
  /// touch it (big top buttons lay the header out narrower).
  static double tabsLeftFor(double w) {
    final tabs = FilterTabs.sizeFor(_tabCount);
    final searchLeft = w - _edge - _button - _gap - _button;
    return math.min((w - tabs.width) / 2, searchLeft - _gap - tabs.width);
  }

  Widget _morph(BuildContext context, bool on, Widget Function(double t) builder) => TweenAnimationBuilder<double>(
    tween: Tween(end: on ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 550),
    curve: _morphSpring,
    builder: (context, t, _) => builder(t),
  );

  static Widget _glassIcon({Key? key, required IconData icon, required String tooltip, required VoidCallback onTap}) =>
      IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(_button),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 26),
      );

  @override
  Widget build(BuildContext context) {
    final tabs = FilterTabs.sizeFor(_tabCount);
    return SizedBox(
      height: _button,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final menuLeft = w - _edge - _button;
          final searchLeft = menuLeft - _gap - _button;
          final addLeft = searchLeft - _gap - _button;
          final tabsLeft = tabsLeftFor(w);
          return _morph(
            context,
            selecting,
            (sel) => Stack(
              clipBehavior: Clip.none,
              children: [
                // Search slides under the menu button while selecting: its icon fades, its glass
                // stays solid (fading the glass itself drew it offscreen every frame).
                Positioned(
                  left: _lerp(searchLeft, menuLeft, sel),
                  child: IgnorePointer(
                    ignoring: selecting,
                    child: CallGlass(
                      child: SizedBox.square(
                        dimension: _button,
                        child: Opacity(
                          opacity: (1 - sel * 1.5).clamp(0.0, 1.0),
                          child: _glassIcon(
                            icon: Icons.search_rounded,
                            tooltip: context.l10n.search,
                            onTap: () => openSearch(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Menu, which becomes Cancel while selecting.
                Positioned(
                  left: menuLeft,
                  // The menu measures this wrapper, outside the glass press, so holding the
                  // button (which squeezes and stretches it) doesn't shift where the menu opens.
                  child: KeyedSubtree(
                    key: menuKey,
                    child: CallGlass(
                      child: SizedBox.square(
                        dimension: _button,
                        child: Stack(
                          children: [
                            IgnorePointer(
                              ignoring: selecting,
                              child: Opacity(
                                opacity: _out(sel),
                                child: _glassIcon(
                                  icon: Icons.more_vert_rounded,
                                  tooltip: context.l10n.moreOptions,
                                  onTap: () => OneUIFloatingMenu.show(
                                    context: context,
                                    anchorKey: menuKey,
                                    width: 250,
                                    items: menuItems(),
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              ignoring: !selecting,
                              child: Opacity(
                                opacity: _in(sel),
                                child: _glassIcon(
                                  icon: Icons.close_rounded,
                                  tooltip: context.l10n.cancel,
                                  onTap: onCancel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // The lead pill: All | Missed, Add to Contacts, or the selection count.
                _morph(context, typing && !selecting, (typ) {
                  final width = _lerp(
                    _lerp(tabs.width, _button, typ),
                    _countWidth,
                    sel,
                  ).clamp(_button - 6, tabs.width + 6);
                  final left = _lerp(_lerp(tabsLeft, addLeft, typ), _edge, sel);
                  return Positioned(
                    left: left,
                    width: width,
                    height: _button,
                    child: CallGlass(
                      radius: _button / 2,
                      // Clipped only mid-morph, so the tab highlight can still swing past the edge at rest.
                      child: ClipRSuperellipse(
                        borderRadius: const BorderRadius.all(Radius.circular(_button / 2)),
                        clipBehavior: typ == 0 && sel == 0 ? Clip.none : Clip.antiAlias,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IgnorePointer(
                              ignoring: typing || selecting,
                              child: Opacity(
                                opacity: _out(typ) * _out(sel),
                                child: OverflowBox(
                                  minWidth: tabs.width,
                                  maxWidth: tabs.width,
                                  child: FilterTabs(
                                    labels: [context.l10n.all, context.l10n.recentsFilterMissed],
                                    index: filterIndex,
                                    onChanged: onFilter,
                                    bare: true,
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              ignoring: !typing || selecting,
                              child: Opacity(
                                opacity: _in(typ) * _out(sel),
                                child: _glassIcon(
                                  key: addKey,
                                  icon: Icons.person_add_alt_rounded,
                                  tooltip: context.l10n.addToContacts,
                                  onTap: onAdd,
                                ),
                              ),
                            ),
                            IgnorePointer(
                              ignoring: !selecting,
                              child: Opacity(
                                opacity: _in(sel),
                                child: OverflowBox(
                                  minWidth: _countWidth,
                                  maxWidth: _countWidth,
                                  child: SelectAllCount(allSelected: allSelected, onTap: onToggleSelectAll),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.group,
    required this.simBadge,
    this.note,
    required this.when,
    required this.selecting,
    required this.selectMark,
    required this.onTap,
    required this.onInfo,
    required this.onLongPress,
  });

  final CallGroup group;
  final String? simBadge;

  /// A note taken during one of the group's calls, shown under the number.
  final String? note;
  final String when;

  final bool selecting;
  final Widget selectMark;
  final VoidCallback onTap;
  final VoidCallback onInfo;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final call = group.latest;
    final name = callerName(context.l10n, call);
    final count = group.calls.length;
    final row = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: context.palette.textPrimary.withValues(alpha: 0.06),
      highlightColor: context.palette.textPrimary.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
        child: Row(
          children: [
            selectMark,
            AppBadged(
              package: call.appPackage,
              child: CallerAvatar(number: call.number, name: name, isPrivate: call.isPrivate),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count > 1 ? '$name ($count)' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      color: call.isMissed ? OneUITheme.accentRed : context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CallTypeIcon(type: call.type),
                      const SizedBox(width: 6),
                      if (simBadge != null && !call.isApp) ...[SimBadge(label: simBadge!), const SizedBox(width: 6)],
                      Flexible(
                        child: Text(
                          call.isApp
                              ? appCallLabel(context.l10n, call)
                              : name == call.number || call.isPrivate
                              ? callTypeLabel(context.l10n, call.type)
                              : call.number,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  if (note case final note?) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 16, color: context.palette.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(when, style: TextStyle(fontSize: 14, color: context.palette.textSecondary)),
            IconButton(
              tooltip: context.l10n.callDetails,
              onPressed: selecting ? null : onInfo,
              icon: Icon(Icons.info_outline_rounded, size: 26, color: context.palette.textPrimary),
            ),
          ],
        ),
      ),
    );

    return row;
  }
}

/// The small grey arrow of a call's details line (ColorOS's: in for missed calls too, a barred
/// circle for rejected and blocked), our own glyphs from `tool/icons/render_icons.py`.
class CallTypeIcon extends StatelessWidget {
  const CallTypeIcon({super.key, required this.type, this.size = 16});

  final CallType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.textSecondary;
    final asset = switch (type) {
      CallType.voicemail => null,
      CallType.outgoing => 'arrow_out',
      CallType.rejected || CallType.blocked => 'arrow_blocked',
      _ => 'arrow_in',
    };
    return asset == null
        ? Icon(Icons.voicemail_rounded, size: size, color: color)
        : ImageIcon(AssetImage('assets/icons/$asset.png'), size: size, color: color);
  }
}

String callTypeLabel(AppLocalizations l10n, CallType type) => switch (type) {
  CallType.outgoing => l10n.callTypeOutgoing,
  CallType.missed => l10n.callTypeMissed,
  CallType.rejected => l10n.callTypeRejected,
  CallType.blocked => l10n.callTypeBlocked,
  CallType.voicemail => l10n.callTypeVoicemail,
  _ => l10n.callTypeIncoming,
};

/// SIM slot number knocked out of a small grey SIM card, grey like the text beside it.
class SimBadge extends StatelessWidget {
  const SimBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(15.3, 16),
        painter: _SimBadgePainter(label: label, color: context.palette.textSecondary),
      ),
    );
  }
}

/// Drawn on a 23×24 grid. The number is cut out of the card, so it shows whatever is behind the
/// row (the page or a card).
class _SimBadgePainter extends CustomPainter {
  _SimBadgePainter({required this.label, required this.color});

  final String label;
  final Color color;

  static final _sim = Path()
    ..moveTo(5, 2.5)
    ..lineTo(14.2, 2.5)
    ..lineTo(19, 7.3)
    ..lineTo(19, 20)
    ..quadraticBezierTo(19, 21.5, 17.5, 21.5)
    ..lineTo(5, 21.5)
    ..quadraticBezierTo(3.5, 21.5, 3.5, 20)
    ..lineTo(3.5, 4)
    ..quadraticBezierTo(3.5, 2.5, 5, 2.5)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.height / 24);
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 23, 24), Paint());
    canvas.drawPath(_sim, Paint()..color = color);
    // A thin stroke of the same grey softens the cut corner like the other glyphs' rounding.
    canvas.drawPath(
      _sim,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round,
    );
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
          foreground: Paint()..blendMode = BlendMode.dstOut,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(11.25, 12.6) - Offset(text.width / 2, text.height / 2));
    text.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SimBadgePainter old) => old.label != label || old.color != color;
}

class _Empty extends StatelessWidget {
  const _Empty({this.icon = Icons.watch_later_outlined, required this.text, this.action});

  final IconData icon;
  final String text;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: context.palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textSecondary),
            ),
            if (action case (final label, final onTap)) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onTap, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
