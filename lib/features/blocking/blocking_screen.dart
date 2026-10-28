import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/search_bar_row.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_switch.dart';
import '../../widgets/one_ui_toast.dart';
import '../../widgets/one_ui_group_card.dart';
import '../contacts/contact_picker_screen.dart';
import '../recents/call_details_screen.dart';
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
import 'blocking_repository.dart';

/// Samsung's "Block numbers": rules, the blocked list, and calls that were blocked.
class BlockingScreen extends StatefulWidget {
  const BlockingScreen({super.key});

  @override
  State<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends State<BlockingScreen> {
  final _repo = BlockingRepository.instance;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repo.load();
  }

  /// The + of "Add number": the menu pops from it.
  final _addKey = GlobalKey();

  Future<void> _add() async {
    String? choice;
    await OneUIFloatingMenu.show(
      context: context,
      anchorKey: _addKey,
      width: 250,
      items: [
        OneUIFloatingMenuItem(label: 'Enter number', icon: Icons.dialpad_rounded, onTap: () => choice = 'type'),
        OneUIFloatingMenuItem(
          label: 'Choose from contacts',
          icon: Icons.person_outline_rounded,
          onTap: () => choice = 'contact',
        ),
      ],
    );
    if (!mounted || choice == null) return;
    final numbers = choice == 'type'
        ? [?await _typeNumber()]
        : (await pickContact(context, title: 'Block contact'))?.numbers;
    for (final n in numbers ?? const <String>[]) {
      await _repo.setBlocked(n, true);
    }
  }

  Future<void> _setRules({required bool blockHidden, required bool blockNonContacts}) async {
    final saved = await _repo.setRules(blockHidden: blockHidden, blockNonContacts: blockNonContacts);
    if (!saved && mounted) {
      OneUIToast.show(context, 'Set Dialer as your caller ID & spam app to block these calls', long: true);
    }
  }

  Future<String?> _typeNumber() async {
    final number = await showCosTextInput(
      context,
      title: 'Block number',
      hint: 'Phone number',
      keyboardType: TextInputType.phone,
      confirmLabel: 'Block',
    );
    return (number != null && numberKey(number).isNotEmpty) ? number.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Block & filter',
      header: ExpandableSearchHeader(
        controller: _query,
        hint: 'Search blocked numbers',
        leading: Row(
          children: [
            RoundIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Block & filter',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      listenable: Listenable.merge([
        _query,
        ContactsRepository.instance.contacts,
        _repo.numbers,
        _repo.rules,
        _repo.hasScreeningRole,
        CallLogRepository.instance.calls,
      ]),
      // Slivers: the blocked numbers and calls build lazily.
      slivers: (context) {
        final rules = _repo.rules.value;
        final blockedCalls = CallLogRepository.instance.calls.value.where((c) => c.type == CallType.blocked).toList();
        final query = _query.text.trim().toLowerCase();
        final digits = query.replaceAll(RegExp(r'[^0-9+]'), '');
        final numbers = _repo.numbers.value
            .where(
              (n) =>
                  query.isEmpty ||
                  (ContactsRepository.instance.nameFor(n) ?? '').toLowerCase().contains(query) ||
                  n.toLowerCase().contains(query) ||
                  (digits.isNotEmpty && n.replaceAll(RegExp(r'[^0-9+]'), '').contains(digits)),
            )
            .toList();
        return [
          if ((rules.blockHidden || rules.blockNonContacts) && !_repo.hasScreeningRole.value)
            SliverToBoxAdapter(
              child: OneUIGroupCard(
                items: [
                  OneUIGroupItem(
                    leading: const Icon(Icons.warning_amber_rounded, color: OneUITheme.accentRed),
                    title: 'Blocking rules are paused',
                    subtitle: 'Another app screens your calls. Tap to let Dialer screen them.',
                    subtitleColor: OneUITheme.accentRed,
                    onTap: () => _setRules(blockHidden: rules.blockHidden, blockNonContacts: rules.blockNonContacts),
                  ),
                ],
              ),
            ),
          SliverToBoxAdapter(
            child: OneUIGroupCard(
              items: [
                _switch(
                  title: 'Block unknown/private numbers',
                  subtitle: 'Callers who hide their number',
                  value: rules.blockHidden,
                  onChanged: (v) => _setRules(blockHidden: v, blockNonContacts: rules.blockNonContacts),
                ),
                _switch(
                  title: 'Block calls from numbers not in Contacts',
                  subtitle: 'Only your contacts can ring you',
                  value: rules.blockNonContacts,
                  onChanged: (v) => _setRules(blockHidden: rules.blockHidden, blockNonContacts: v),
                ),
              ],
            ),
          ),
          OneUIGroupCardSliver(
            headerTitle: 'Blocked numbers',
            itemCount: numbers.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return OneUIGroupItem(
                  leading: Icon(Icons.add_rounded, key: _addKey, color: context.palette.textPrimary),
                  title: 'Add number',
                  onTap: _add,
                  trailing: const SizedBox.shrink(),
                );
              }
              final n = numbers[i - 1];
              final name = ContactsRepository.instance.nameFor(n);
              return OneUIGroupItem(
                title: name ?? n,
                subtitle: name == null ? null : n,
                trailing: IconButton(
                  tooltip: 'Unblock',
                  icon: Icon(Icons.remove_circle_outline_rounded, color: context.palette.textSecondary),
                  onPressed: () => _repo.setBlocked(n, false),
                ),
              );
            },
          ),
          if (query.isNotEmpty && numbers.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(20), child: Text('No matching blocked numbers')),
            ),
          if (blockedCalls.isNotEmpty && query.isEmpty)
            OneUIGroupCardSliver(
              headerTitle: 'Blocked calls',
              itemCount: blockedCalls.length,
              itemBuilder: (context, i) {
                final c = blockedCalls[i];
                return OneUIGroupItem(
                  leading: Icon(Icons.block_rounded, color: context.palette.textSecondary),
                  title: callerName(c),
                  subtitle: '${dayLabel(c.date, DateTime.now())}, ${timeLabel(c.date)}',
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CallDetailsScreen(call: c))),
                );
              },
            ),
        ];
      },
    );
  }

  OneUIGroupItem _switch({
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
