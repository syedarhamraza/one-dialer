import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/haptics/haptics.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_switch.dart';
import '../../widgets/one_ui_toast.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/select_mark.dart';
import '../contacts/contact_details_screen.dart' show DetailsCardSliver;
import '../contacts/contact_picker_screen.dart';
import '../recents/call_details_screen.dart';
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
import 'blocking_repository.dart';
import '../../l10n/l10n.dart';

/// ColorOS's "Block & filter": Block calls (the rules and blocked calls), the Blocklist and
/// the Allowlist.
class BlockingScreen extends StatefulWidget {
  const BlockingScreen({super.key});

  @override
  State<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends State<BlockingScreen> {
  final _repo = BlockingRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.load();
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  String _count(int n) => n == 0 ? context.l10n.none : '$n';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OneUISubpage(
      title: l10n.blockAndFilter,
      listenable: Listenable.merge([_repo.numbers, _repo.prefixes, _repo.allowed, _repo.rules, _repo.hasScreeningRole]),
      builder: (context) => [
        if (_repo.needsScreening && !_repo.hasScreeningRole.value)
          OneUIGroupCard(
            items: [
              OneUIGroupItem(
                leading: const Icon(Icons.warning_amber_rounded, color: OneUITheme.accentRed),
                title: l10n.blockingPaused,
                subtitle: l10n.blockingPausedSubtitle,
                subtitleColor: OneUITheme.accentRed,
                onTap: _repo.restoreScreening,
              ),
            ],
          ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(title: l10n.blockCalls, onTap: () => _push(const BlockCallsScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: l10n.blocklist,
              subtitle: l10n.blocklistSubtitle,
              value: _count(_repo.numbers.value.length + _repo.prefixes.value.length),
              onTap: () => _push(const NumberListScreen(allow: false)),
            ),
            OneUIGroupItem(
              title: l10n.allowlist,
              subtitle: l10n.allowlistSubtitle,
              value: _count(_repo.allowed.value.length),
              onTap: () => _push(const NumberListScreen(allow: true)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Block & filter › Block calls: the private and non-contact rules, then the calls that were
/// blocked.
class BlockCallsScreen extends StatelessWidget {
  const BlockCallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = BlockingRepository.instance;
    Future<void> setRules({required bool blockHidden, required bool blockNonContacts}) async {
      final saved = await repo.setRules(blockHidden: blockHidden, blockNonContacts: blockNonContacts);
      if (!saved && context.mounted) {
        OneUIToast.show(context, context.l10n.blockingNeedsScreeningRole, long: true);
      }
    }

    return OneUISubpage(
      title: context.l10n.blockCalls,
      listenable: Listenable.merge([repo.rules, CallLogRepository.instance.calls]),
      // Slivers: the blocked calls build lazily.
      slivers: (context) {
        final rules = repo.rules.value;
        final blockedCalls = CallLogRepository.instance.calls.value.where((c) => c.type == CallType.blocked).toList();
        return [
          SliverToBoxAdapter(
            child: OneUIGroupCard(
              items: [
                _switch(
                  title: context.l10n.blockUnknown,
                  subtitle: context.l10n.blockUnknownSubtitle,
                  value: rules.blockHidden,
                  onChanged: (v) => setRules(blockHidden: v, blockNonContacts: rules.blockNonContacts),
                ),
                _switch(
                  title: context.l10n.blockNonContacts,
                  subtitle: context.l10n.blockNonContactsSubtitle,
                  value: rules.blockNonContacts,
                  onChanged: (v) => setRules(blockHidden: rules.blockHidden, blockNonContacts: v),
                ),
              ],
            ),
          ),
          if (blockedCalls.isNotEmpty)
            OneUIGroupCardSliver(
              headerTitle: context.l10n.blockedCalls,
              itemCount: blockedCalls.length,
              itemBuilder: (context, i) {
                final c = blockedCalls[i];
                return OneUIGroupItem(
                  leading: Icon(Icons.block_rounded, color: context.palette.textSecondary),
                  title: callerName(context.l10n, c),
                  subtitle: '${dayLabel(context.l10n, c.date, DateTime.now())}, ${timeLabel(context.l10n, c.date)}',
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CallDetailsScreen(call: c))),
                );
              },
            ),
        ];
      },
    );
  }

  static OneUIGroupItem _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => OneUIGroupItem(
    title: title,
    subtitle: subtitle,
    onTap: () => onChanged(!value),
    trailing: OneUISwitch(value: value, onChanged: onChanged),
  );
}

/// One row of a [NumberListScreen]: a blocked or allowed number, or a blocked prefix.
typedef _Entry = ({String key, String? number, String? prefix});

/// Block & filter › Blocklist ([allow] false: the system block list and the prefixes) or
/// Allowlist: + to add (type a number, a prefix, or pick from calls and contacts), the
/// checklist button or a long-press to select and remove.
class NumberListScreen extends StatefulWidget {
  const NumberListScreen({super.key, required this.allow});

  final bool allow;

  @override
  State<NumberListScreen> createState() => _NumberListScreenState();
}

class _NumberListScreenState extends State<NumberListScreen> {
  final _repo = BlockingRepository.instance;
  final _addKey = GlobalKey();

  /// Selected entry keys; null while not selecting (empty right after the checklist button).
  final _selected = ValueNotifier<Set<String>?>(null);

  /// Whether [_selected] is non-null: the page rebuilds only on entering and leaving
  /// selection; a tap redraws just the header, the bar and that row's mark.
  final _selecting = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _selected.addListener(() => _selecting.value = _selected.value != null);
  }

  @override
  void dispose() {
    _selected.dispose();
    _selecting.dispose();
    super.dispose();
  }

  List<_Entry> get _entries => widget.allow
      ? [for (final n in _repo.allowed.value) (key: 'n:$n', number: n, prefix: null)]
      : [
          for (final n in _repo.numbers.value) (key: 'n:$n', number: n, prefix: null),
          for (final p in _repo.prefixes.value) (key: 'p:$p', number: null, prefix: p),
        ];

  /// The selection still in [entries]: removed ones drop out of it.
  Set<String> _live(List<_Entry> entries) =>
      _selected.value?.intersection({for (final e in entries) e.key}) ?? const {};

  void _toggle(String key) {
    final set = {...?_selected.value};
    if (!set.remove(key)) set.add(key);
    _selected.value = set;
  }

  Future<void> _add() async {
    final l10n = context.l10n;
    String? choice;
    await OneUIFloatingMenu.show(
      context: context,
      anchorKey: _addKey,
      width: 250,
      items: [
        OneUIFloatingMenuItem(label: l10n.enterNumber, onTap: () => choice = 'type'),
        if (!widget.allow) OneUIFloatingMenuItem(label: l10n.blockByPrefix, onTap: () => choice = 'prefix'),
        OneUIFloatingMenuItem(label: l10n.chooseFromContacts, onTap: () => choice = 'pick'),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'prefix':
        return _addPrefix();
      case 'type':
        final number = await showCosTextInput(
          context,
          title: l10n.enterNumber,
          hint: l10n.phoneNumber,
          keyboardType: TextInputType.phone,
        );
        if (number != null && numberKey(number).isNotEmpty) await _addNumbers([number.trim()]);
      default:
        final numbers = await pickNumbers(context);
        if (numbers != null && numbers.isNotEmpty) await _addNumbers(numbers);
    }
  }

  Future<void> _addNumbers(List<String> numbers) => widget.allow ? _repo.allowAll(numbers) : _repo.blockAll(numbers);

  Future<void> _addPrefix() async {
    final text = await showCosTextInput(
      context,
      title: context.l10n.blockByPrefix,
      hint: context.l10n.numberPrefix,
      keyboardType: TextInputType.phone,
    );
    if (text == null) return;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final saved = await _repo.addPrefix('${text.startsWith('+') ? '+' : ''}$digits');
    if (!saved && mounted) OneUIToast.show(context, context.l10n.blockingNeedsScreeningRole, long: true);
  }

  Future<void> _remove(Set<String> keys) async {
    final l10n = context.l10n;
    final ok = await showCosActions<bool>(
      context,
      title: widget.allow ? l10n.removeFromAllowlist(keys.length) : l10n.removeFromBlocklist(keys.length),
      actions: [
        (label: l10n.cancel, value: false, destructive: false),
        (label: l10n.remove, value: true, destructive: true),
      ],
    );
    if (ok != true || !mounted) return;
    final numbers = [
      for (final k in keys)
        if (k.startsWith('n:')) k.substring(2),
    ];
    final prefixes = [
      for (final k in keys)
        if (k.startsWith('p:')) k.substring(2),
    ];
    _selected.value = null;
    if (widget.allow) {
      await _repo.removeAllowed(numbers);
    } else {
      if (numbers.isNotEmpty) await _repo.unblockAll(numbers);
      if (prefixes.isNotEmpty) await _repo.removePrefixes(prefixes);
    }
  }

  Widget _header(List<_Entry> entries) => ValueListenableBuilder(
    valueListenable: _selected,
    builder: (context, _, _) {
      final l10n = context.l10n;
      final selected = _live(entries);
      return SubpageHeader(
        selecting: _selected.value != null,
        title: widget.allow ? l10n.allowlist : l10n.blocklist,
        selectionTitle: selected.isEmpty ? l10n.selectItems : l10n.selectedCount(selected.length),
        allSelected: entries.isNotEmpty && selected.length == entries.length,
        onCancel: () => _selected.value = null,
        onToggleSelectAll: () =>
            _selected.value = selected.length == entries.length ? {} : {for (final e in entries) e.key},
        extra: RoundIconButton(key: _addKey, icon: Icons.add_rounded, tooltip: l10n.add, onTap: _add),
        trailingIcon: entries.isEmpty ? null : Icons.checklist_rounded,
        trailingTooltip: l10n.select,
        onTrailing: () => _selected.value = {},
      );
    },
  );

  Widget _row(_Entry e) {
    final grey = context.palette.textSecondary;
    final String title;
    final String? subtitle;
    if (e.prefix case final prefix?) {
      title = context.l10n.startsWith(prefix);
      subtitle = null;
    } else {
      final name = ContactsRepository.instance.nameFor(e.number!);
      title = name ?? e.number!;
      subtitle = name == null ? null : e.number;
    }
    return ValueListenableBuilder(
      valueListenable: _selected,
      builder: (context, selected, row) => InkWell(
        onTap: selected == null ? null : () => _toggle(e.key),
        onLongPress: selected != null
            ? null
            : () {
                Haptics.longPress();
                _selected.value = {e.key};
              },
        child: Row(
          children: [
            Expanded(child: row!),
            // Same row structure in and out of selection: the mark springs in.
            SelectMark(selected: selected?.contains(e.key)),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 14, color: grey)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _repo.numbers,
        _repo.prefixes,
        _repo.allowed,
        ContactsRepository.instance.contacts,
        _selecting,
      ]),
      builder: (context, _) {
        final entries = _entries;
        final selecting = _selecting.value;
        return PopScope(
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _selected.value = null;
          },
          child: OneUISubpage(
            title: widget.allow ? l10n.allowlist : l10n.blocklist,
            header: _header(entries),
            bottomPill: !selecting
                ? null
                : ValueListenableBuilder(
                    valueListenable: _selected,
                    builder: (context, _, _) {
                      final selected = _live(entries);
                      return OneUISubpage.actionBar([
                        OneUIFloatingActionBarItem(
                          icon: Icons.delete_outline_rounded,
                          label: l10n.remove,
                          isEnabled: selected.isNotEmpty,
                          onTap: () => _remove(selected),
                        ),
                      ]);
                    },
                  ),
            slivers: (context) => [
              if (entries.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 140, 32, 0),
                    child: Column(
                      children: [
                        Icon(Icons.person_rounded, size: 72, color: context.palette.textTertiary),
                        const SizedBox(height: 16),
                        Text(l10n.noNumbers, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                          widget.allow ? l10n.allowlistSubtitle : l10n.blocklistSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                DetailsCardSliver(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _row(entries[i]),
                ),
            ],
          ),
        );
      },
    );
  }
}
