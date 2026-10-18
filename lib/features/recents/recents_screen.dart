import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../app/main_shell.dart' show navDock;
import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/morph_menu_action.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/swipe_to_call.dart';
import '../settings/settings_screen.dart';
import 'call_details_screen.dart';
import 'call_log.dart';
import 'call_log_repository.dart';
import '../search/search_screen.dart';
import '../../widgets/select_mark.dart';
import '../blocking/blocking_repository.dart';
import '../../widgets/one_ui_selection_header_pills.dart';

/// Samsung-style Recents: calls grouped by day, All / Missed filter, swipe right to
/// call and left to message, tap for details, long-press to multi-select and delete.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
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

  /// Samsung's "Filter calls" dialog (radio list, Cancel | OK).
  Future<void> _chooseFilter() async {
    var choice = _filter;
    final ok = await OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Filter calls',
      confirmLabel: 'OK',
      customContent: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          children: [
            for (final f in CallFilter.values)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setModal(() => choice = f),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      OneUIRadio(isSelected: choice == f),
                      const SizedBox(width: 22),
                      Text(f.label, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) setState(() => _filter = choice);
  }

  List<OneUIFloatingMenuItem> get _menuItems => [
    OneUIFloatingMenuItem(
      label: _hideBlocked ? 'Show blocked calls' : 'Hide blocked calls',
      onTap: () => DialerPrefs.instance.setHideBlockedCalls(!_hideBlocked),
    ),
    OneUIFloatingMenuItem(
      label: 'Settings',
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
    final days = _groupedDays;
    final now = DateTime.now();
    final selecting = _selected != null;
    return CustomScrollView(
      physics: OneUIScrollPhysics.bigHeader,
      slivers: [
        ValueListenableBuilder(
          valueListenable: _selectionChanged,
          builder: (context, _, _) => SliverPersistentHeader(
            pinned: true,
            delegate: OneUICollapsibleHeaderDelegate(
              title: selecting ? '$_selectedRows selected' : 'Phone',
              subtitle: selecting
                  ? (_selectedRows == _rows.length ? 'All selected • Tap (O) to deselect' : 'Tap (O) to select all')
                  : (_filter == CallFilter.all ? null : _filter.label),
              isSelectionMode: selecting,
              selectionLeading: selecting
                  ? OneUISelectionCountPill(
                      selectedCount: _selectedRows,
                      totalCount: _rows.length,
                      onToggleSelectAll: _toggleSelectAll,
                    )
                  : null,
              onSelectionCancel: selecting ? _endSelection : null,
              actionsPillKey: _menuKey,
              actions: selecting
                  ? null
                  : [
                      OneUIHeaderAction(icon: Icons.filter_list_rounded, tooltip: 'Filter calls', onTap: _chooseFilter),
                      OneUIHeaderAction(
                        icon: Icons.search_rounded,
                        tooltip: 'Search',
                        onTap: () => openSearch(context),
                      ),
                      MorphMenuAction(items: _menuItems),
                    ],
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
        else if (days.isEmpty)
          _Empty(text: _filter == CallFilter.all ? 'No recent calls' : 'No ${_filter.label.toLowerCase()}')
        else
          for (final (day, groups) in days)
            SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: _DayHeader(label: dayLabel(day, now))),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // Lazy: only the rows on screen are built.
                  sliver: DecoratedSliver(
                    decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: OneUITheme.cardBorderRadius),
                    sliver: SliverList.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, i) => _cardRow(context, groups, i),
                    ),
                  ),
                ),
              ],
            ),
        SliverToBoxAdapter(child: SizedBox(height: navBarClearance(context) + 8)),
      ],
    );
  }

  /// One row of a day card; the first and last are clipped to the card's corners so
  /// swipe backgrounds and ink stay inside it.
  Widget _cardRow(BuildContext context, List<CallGroup> groups, int i) {
    const radius = Radius.circular(OneUITheme.radiusCard);
    final group = groups[i];
    final row = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (i > 0) Divider(height: 1, indent: 74, endIndent: 16, color: Colors.white.withValues(alpha: 0.08)),
        _CallRow(
          group: group,
          simBadge: _simBadge(group.latest.simId),
          selecting: _selected != null,
          // Only the circle listens to selection taps; the rest of the row stays built.
          selectMark: ValueListenableBuilder(
            valueListenable: _selectionChanged,
            builder: (context, _, _) => SelectMark(selected: _selected?.contains(group.latest.id), gap: 12),
          ),
          onTap: () => _selected != null
              ? _toggle(group)
              : Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => CallDetailsScreen(call: group.latest))),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _toggle(group);
          },
        ),
      ],
    );
    final first = i == 0, last = i == groups.length - 1;
    if (!first && !last) return row;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: first ? radius : Radius.zero, bottom: last ? radius : Radius.zero),
      child: row,
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.group,
    required this.simBadge,
    required this.selecting,
    required this.selectMark,
    required this.onTap,
    required this.onLongPress,
  });

  final CallGroup group;
  final (String, Color)? simBadge;

  final bool selecting;
  final Widget selectMark;
  final VoidCallback onTap;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            selectMark,
            LetterAvatar(name: call.isPrivate ? '' : name),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count > 1 ? '$name ($count)' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: -0.2,
                      color: call.isMissed ? OneUITheme.accentRed : OneUITheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CallTypeIcon(type: call.type),
                      if (simBadge != null) ...[const SizedBox(width: 4), SimBadge(badge: simBadge!)],
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          name == call.number || call.isPrivate ? callTypeLabel(call.type) : call.number,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(timeLabel(call.date), style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
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
      child: row,
    );
  }
}

/// Small arrow showing incoming / outgoing / missed, Samsung style.
class CallTypeIcon extends StatelessWidget {
  const CallTypeIcon({super.key, required this.type});

  final CallType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      CallType.outgoing => (Icons.call_made_rounded, OneUITheme.accentGreen),
      CallType.missed => (Icons.call_missed_rounded, OneUITheme.accentRed),
      CallType.rejected || CallType.blocked => (Icons.block_rounded, OneUITheme.textSecondary),
      CallType.voicemail => (Icons.voicemail_rounded, OneUITheme.accentBlue),
      _ => (Icons.call_received_rounded, OneUITheme.accentBlue),
    };
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

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: OneUITheme.sectionHeader,
        ),
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
