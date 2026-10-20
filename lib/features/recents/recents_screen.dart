import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../app/main_shell.dart' show navDock;
import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';

import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/place_call.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/swipe_to_call.dart';
import '../contacts/editor/add_to_contacts.dart';
import '../in_call/call_controls.dart';
import '../keypad/keypad_screen.dart';
import '../settings/settings_screen.dart';
import 'call_details_screen.dart';
import 'call_log.dart';
import 'call_log_repository.dart';
import '../search/search_screen.dart';
import '../../widgets/select_mark.dart';
import '../blocking/blocking_repository.dart';
import '../../core/haptics/haptics.dart';

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
  CallFilter _filter = CallFilter.all;
  bool _hideBlocked = true;
  Set<int>? _selected; // call ids; null when not selecting

  /// Bumped when the selection changes but selection mode doesn't, so only the
  /// header count and the visible rows' checkboxes rebuild, not the whole list.
  final _selectionChanged = ValueNotifier(0);
  List<SimCard> _sims = const [];

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getSims().then((s) {
      if (mounted) setState(() => _sims = s);
    });
    DialerPrefs.instance.changes.addListener(_loadPrefs);
    _loadPrefs();
  }

  @override
  void dispose() {
    DialerPrefs.instance.changes.removeListener(_loadPrefs);
    _selectionChanged.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final hide = await DialerPrefs.instance.hideBlockedCalls();
    if (mounted && hide != _hideBlocked) setState(() => _hideBlocked = hide);
  }

  List<OneUIFloatingMenuItem> _menuItems() => [
    OneUIFloatingMenuItem(
      label: _hideBlocked ? 'Show blocked calls' : 'Hide blocked calls',
      icon: Icons.block_rounded,
      onTap: () => DialerPrefs.instance.setHideBlockedCalls(!_hideBlocked),
    ),
    OneUIFloatingMenuItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
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
        OneUIFloatingActionBarItem(icon: Icons.block_rounded, label: 'Block', onTap: _blockSelected),
        OneUIFloatingActionBarItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
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
    _endSelection();
    await _repo.delete(ids);
  }

  Future<void> _blockSelected() async {
    final ids = _selected ?? const {};
    final numbers = {
      for (final g in _rows)
        if (ids.contains(g.latest.id) && !g.latest.isPrivate && g.latest.number.isNotEmpty) g.latest.number,
    };
    if (numbers.isEmpty) return;
    final ok = await OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: numbers.length == 1 ? 'Block ${numbers.single}?' : 'Block ${numbers.length} numbers?',
      message: "You won't get calls from blocked numbers.",
      confirmLabel: 'Block',
      confirmTextColor: OneUITheme.accentRed,
    );
    if (ok != true) return;
    for (final n in numbers) {
      await BlockingRepository.instance.setBlocked(n, true);
    }
    _endSelection();
  }

  /// "1"/"2" badge, only on dual-SIM phones.
  (String, Color)? _simBadge(String? simId) {
    if (_sims.length < 2 || simId == null) return null;
    final i = _sims.indexWhere((s) => s.id == simId);
    return i < 0 ? null : ('${i + 1}', _sims[i].color);
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
        listenable: Listenable.merge([_repo.calls, _repo.hasAccess, ContactsRepository.instance.contacts]),
        builder: (context, _) => _buildList(context),
      ),
    );
  }

  List<CallLogEntry> get _visibleCalls => [
    for (final c in _repo.calls.value)
      if (_filter.matches(c, hideBlocked: _hideBlocked)) c,
  ];

  // groupByDay is only redone when the calls or the filter change, not on every selection tap.
  (List<CallLogEntry>, CallFilter, bool)? _groupedFor;
  List<(DateTime, List<CallGroup>)> _days = const [];

  List<(DateTime, List<CallGroup>)> get _groupedDays {
    final key = (_repo.calls.value, _filter, _hideBlocked);
    final old = _groupedFor;
    if (old == null || !identical(old.$1, key.$1) || old.$2 != key.$2 || old.$3 != key.$3) {
      _groupedFor = key;
      _days = groupByDay(_visibleCalls);
    }
    return _days;
  }

  Widget _buildList(BuildContext context) {
    final groups = [for (final (_, g) in _groupedDays) ...g];
    final now = DateTime.now();
    final selecting = _selected != null;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          toolbarHeight: kHeaderBarHeight,
          // The glass press stretches the pills past the bar; don't cut it off.
          clipBehavior: Clip.none,
          titleSpacing: 0,
          title: ListenableBuilder(
            listenable: Listenable.merge([widget.dialInput ?? _noInput, _selectionChanged]),
            builder: (context, _) {
              final number = (widget.dialInput ?? _noInput).value;
              return _HeaderControls(
                typing: number.isNotEmpty,
                selecting: selecting,
                filterIndex: _filter == CallFilter.missed ? 1 : 0,
                onFilter: (i) => setState(() => _filter = i == 1 ? CallFilter.missed : CallFilter.all),
                onAdd: () => showAddToContacts(context, number),
                allSelected: selecting && _selectedRows == _rows.length,
                onToggleSelectAll: _toggleSelectAll,
                onCancel: _endSelection,
                menuKey: _menuKey,
                menuItems: () => number.isEmpty
                    ? _menuItems()
                    : keypadMenuItems(context, input: widget.dialInput!, open: widget.keypadOpen!),
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
                      child: Text(
                        selecting ? '$_selectedRows selected' : 'Calls',
                        // Keyed on the mode only, so the count updates in place.
                        key: ValueKey(selecting),
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_repo.hasAccess.value)
                _Empty(
                  icon: Icons.lock_outline_rounded,
                  text: 'Set Dialer as your default phone app to see recent calls',
                  action: (
                    'Set as default',
                    () async {
                      await TelecomBridge.instance.requestDefaultDialer();
                      await _repo.start();
                    },
                  ),
                )
              else if (groups.isEmpty)
                _Empty(text: _filter == CallFilter.all ? 'No recent calls' : 'No ${_filter.label.toLowerCase()}')
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
    );
  }

  Widget _row(BuildContext context, List<CallGroup> groups, int i, DateTime now) {
    final group = groups[i];
    final call = group.latest;
    final day = dayLabel(call.date, now);
    void details() =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CallDetailsScreen(call: call)));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (i > 0) Divider(height: 1, indent: 76, color: Colors.white.withValues(alpha: 0.1)),
        _CallRow(
          group: group,
          simBadge: _simBadge(call.simId),
          when: day == 'Today' ? timeLabel(call.date) : day,
          selecting: _selected != null,
          // Only the circle listens to selection taps; the rest of the row stays built.
          selectMark: ValueListenableBuilder(
            valueListenable: _selectionChanged,
            builder: (context, _, _) => SelectMark(selected: _selected?.contains(call.id), gap: 12),
          ),
          // Tapping a row calls back on the SIM the call used, like ColorOS; (i) opens details.
          onTap: () => _selected != null
              ? _toggle(group)
              : call.isPrivate || call.number.isEmpty
              ? details()
              : placeCall(context, call.number, simId: call.simId),
          onInfo: details,
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _toggle(group);
          },
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
  final bool allSelected;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onCancel;
  final GlobalKey menuKey;
  final List<OneUIFloatingMenuItem> Function() menuItems;

  static const _labels = ['All', 'Missed'];
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
          foregroundColor: OneUITheme.textPrimary,
          fixedSize: const Size.square(_button),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 24),
      );

  @override
  Widget build(BuildContext context) {
    final tabs = FilterTabs.sizeFor(_labels.length);
    return SizedBox(
      height: _button,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final menuLeft = w - _edge - _button;
          final searchLeft = menuLeft - _gap - _button;
          final addLeft = searchLeft - _gap - _button;
          final tabsLeft = (w - tabs.width) / 2;
          return _morph(
            context,
            selecting,
            (sel) => Stack(
              clipBehavior: Clip.none,
              children: [
                // Search merges into the menu button and fades while selecting.
                Positioned(
                  left: _lerp(searchLeft, menuLeft, sel),
                  child: IgnorePointer(
                    ignoring: selecting,
                    child: Opacity(
                      opacity: (1 - sel * 1.5).clamp(0.0, 1.0),
                      child: RoundIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'Search',
                        onTap: () => openSearch(context),
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
                                  tooltip: 'More options',
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
                                child: _glassIcon(icon: Icons.close_rounded, tooltip: 'Cancel', onTap: onCancel),
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
                                    labels: _labels,
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
                                  icon: Icons.person_add_alt_rounded,
                                  tooltip: 'Add to Contacts',
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
                                  child: _SelectAllCount(allSelected: allSelected, onTap: onToggleSelectAll),
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

/// Select all, inside the lead pill: a check circle (filled blue when every row is
/// selected) and "All". The count itself is the big "N selected" title.
class _SelectAllCount extends StatelessWidget {
  const _SelectAllCount({required this.allSelected, required this.onTap});

  final bool allSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: allSelected ? 'Deselect all' : 'Select all',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allSelected ? const Color(0xFF2C69FF) : Colors.transparent,
                border: Border.all(
                  color: allSelected ? const Color(0xFF2C69FF) : Colors.white.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
              child: allSelected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(
              'All',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: OneUITheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.group,
    required this.simBadge,
    required this.when,
    required this.selecting,
    required this.selectMark,
    required this.onTap,
    required this.onInfo,
    required this.onLongPress,
  });

  final CallGroup group;
  final (String, Color)? simBadge;
  final String when;

  final bool selecting;
  final Widget selectMark;
  final VoidCallback onTap;
  final VoidCallback onInfo;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final call = group.latest;
    final name = callerName(call);
    final count = group.calls.length;
    final row = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
        child: Row(
          children: [
            selectMark,
            LetterAvatar(name: call.isPrivate ? '' : name),
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
                      color: call.isMissed ? OneUITheme.accentRed : OneUITheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CallTypeIcon(type: call.type, muted: true),
                      const SizedBox(width: 6),
                      if (simBadge != null) ...[SimBadge(badge: simBadge!), const SizedBox(width: 6)],
                      Flexible(
                        child: Text(
                          name == call.number || call.isPrivate ? callTypeLabel(call.type) : call.number,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: OneUITheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(when, style: const TextStyle(fontSize: 14, color: OneUITheme.textSecondary)),
            IconButton(
              tooltip: 'Call details',
              onPressed: selecting ? null : onInfo,
              icon: const Icon(Icons.info_outline_rounded, size: 24, color: OneUITheme.textPrimary),
            ),
          ],
        ),
      ),
    );

    if (call.isPrivate || call.number.isEmpty) return row;
    // Call back on the SIM the call used.
    return SwipeToCallOrMessage(
      key: ValueKey(call.id),
      number: call.number,
      simId: call.simId,
      enabled: !selecting,
      color: Colors.black,
      child: row,
    );
  }
}

/// Small arrow showing incoming / outgoing / missed, Samsung style.
class CallTypeIcon extends StatelessWidget {
  const CallTypeIcon({super.key, required this.type, this.muted = false});

  final CallType type;

  /// Grey arrows with only missed calls in red, for the flat Recents rows.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      CallType.outgoing => (Icons.call_made_rounded, OneUITheme.accentGreen),
      CallType.missed => (Icons.call_missed_rounded, OneUITheme.accentRed),
      CallType.rejected || CallType.blocked => (Icons.block_rounded, OneUITheme.textSecondary),
      CallType.voicemail => (Icons.voicemail_rounded, OneUITheme.accentBlue),
      _ => (Icons.call_received_rounded, OneUITheme.accentBlue),
    };
    if (muted) {
      return Icon(icon, size: 18, color: type == CallType.missed ? color : OneUITheme.textSecondary);
    }
    return Icon(icon, size: 15, color: color);
  }
}

String callTypeLabel(CallType type) => switch (type) {
  CallType.outgoing => 'Outgoing call',
  CallType.missed => 'Missed call',
  CallType.rejected => 'Rejected call',
  CallType.blocked => 'Blocked call',
  CallType.voicemail => 'Voicemail',
  _ => 'Incoming call',
};

/// SIM slot number in its SIM colour.
class SimBadge extends StatelessWidget {
  const SimBadge({super.key, required this.badge});

  final (String, Color) badge;

  @override
  Widget build(BuildContext context) {
    final (label, color) = badge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, height: 1.3, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
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
            Icon(icon, size: 40, color: OneUITheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: OneUITheme.textSecondary),
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
