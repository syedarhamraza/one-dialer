import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_big_header.dart';
import '../../widgets/one_ui_floating_nav_bar.dart';
import '../../widgets/one_ui_glass_surface.dart';
import '../../widgets/swipe_to_call.dart';
import 'call_details_screen.dart';
import 'call_log.dart';
import 'call_log_repository.dart';

/// Samsung-style Recents: calls grouped by day, All / Missed filter, swipe right to
/// call and left to message, tap for details, long-press to multi-select and delete.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  final _repo = CallLogRepository.instance;
  bool _missedOnly = false;
  Set<int>? _selected; // call ids; null when not selecting
  List<SimCard> _sims = const [];

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getSims().then((s) {
      if (mounted) setState(() => _sims = s);
    });
  }

  void _toggle(CallGroup group) {
    final ids = group.calls.map((c) => c.id);
    setState(() {
      final selected = _selected ??= {};
      if (ids.every(selected.contains)) {
        selected.removeAll(ids);
      } else {
        selected.addAll(ids);
      }
      if (selected.isEmpty) _selected = null;
    });
  }

  Future<void> _deleteSelected() async {
    final ids = _selected;
    if (ids == null || ids.isEmpty) return;
    setState(() => _selected = null);
    await _repo.delete(ids);
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
        if (!didPop) setState(() => _selected = null);
      },
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([_repo.calls, _repo.hasAccess, ContactsRepository.instance.contacts]),
            builder: (context, _) => _buildList(context),
          ),
          if (selecting)
            _SelectionBar(
              count: _selected!.length,
              onCancel: () => setState(() => _selected = null),
              onSelectAll: () => setState(() => _selected = {for (final c in _visibleCalls) c.id}),
              onDelete: _deleteSelected,
            ),
        ],
      ),
    );
  }

  /// Blocked calls live under Block numbers, not Recents (like Samsung).
  List<CallLogEntry> get _visibleCalls => [
        for (final c in _repo.calls.value)
          if (c.type != CallType.blocked && (!_missedOnly || c.isMissed)) c,
      ];

  Widget _buildList(BuildContext context) {
    final days = groupByDay(_visibleCalls);
    final now = DateTime.now();
    final title = _selected == null ? 'Recents' : '${_selected!.length} selected';
    return CustomScrollView(
      physics: OneUIScrollPhysics.bigHeader,
      slivers: [
        SliverPersistentHeader(pinned: true, delegate: OneUIBigHeader(title: title)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                _FilterPill(label: 'All', selected: !_missedOnly, onTap: () => setState(() => _missedOnly = false)),
                const SizedBox(width: 8),
                _FilterPill(label: 'Missed', selected: _missedOnly, onTap: () => setState(() => _missedOnly = true)),
              ],
            ),
          ),
        ),
        if (!_repo.hasAccess.value)
          _Empty(
            icon: Icons.lock_outline_rounded,
            text: 'Set Dialer as your default phone app to see recent calls',
            action: ('Set as default', () async {
              await TelecomBridge.instance.requestDefaultDialer();
              await _repo.start();
            }),
          )
        else if (days.isEmpty)
          _Empty(icon: Icons.watch_later_outlined, text: _missedOnly ? 'No missed calls' : 'No recent calls')
        else
          for (final (day, groups) in days) ...[
            SliverToBoxAdapter(child: _DayHeader(label: dayLabel(day, now))),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: OneUITheme.cardBorderRadius,
                  child: ColoredBox(
                    color: OneUITheme.surfaceCard,
                    child: Column(
                      children: [
                        for (var i = 0; i < groups.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, indent: 74, endIndent: 16, color: Colors.white.withValues(alpha: 0.08)),
                          _CallRow(
                            group: groups[i],
                            simBadge: _simBadge(groups[i].latest.simId),
                            selected: _selected?.contains(groups[i].latest.id),
                            onTap: () => _selected != null
                                ? _toggle(groups[i])
                                : Navigator.of(context).push(MaterialPageRoute<void>(
                                    builder: (_) => CallDetailsScreen(call: groups[i].latest),
                                  )),
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              _toggle(groups[i]);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + OneUIFloatingNavBar.barHeight + 32),
        ),
      ],
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.group,
    required this.simBadge,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final CallGroup group;
  final (String, Color)? simBadge;

  /// null when not in selection mode.
  final bool? selected;
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
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  selected! ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected! ? OneUITheme.accentBlue : OneUITheme.textTertiary,
                ),
              ),
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

    if (selected != null || call.isPrivate || call.number.isEmpty) return row;
    // Call back on the SIM the call used.
    return SwipeToCallOrMessage(key: ValueKey(call.id), number: call.number, simId: call.simId, child: row);
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
      child: Text(label, style: TextStyle(fontSize: 10, height: 1.3, fontWeight: FontWeight.w700, color: color)),
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? OneUITheme.surfacePillActive : OneUITheme.surfacePill,
        borderRadius: OneUITheme.pillBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: OneUITheme.pillBorderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.action});

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
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: OneUITheme.textSecondary)),
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

/// Floating Cancel | Select all | Delete pill above the nav bar while selecting.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onCancel,
    required this.onSelectAll,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.paddingOf(context).bottom + OneUIFloatingNavBar.barHeight + 20,
      child: Center(
        child: OneUIGlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              TextButton(onPressed: onSelectAll, child: const Text('Select all')),
              TextButton.icon(
                onPressed: count == 0 ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: OneUITheme.accentRed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
