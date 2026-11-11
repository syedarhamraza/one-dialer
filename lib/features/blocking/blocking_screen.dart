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
import '../../l10n/l10n.dart';

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
        OneUIFloatingMenuItem(
          label: context.l10n.enterNumber,
          icon: Icons.dialpad_rounded,
          onTap: () => choice = 'type',
        ),
        OneUIFloatingMenuItem(
          label: context.l10n.chooseFromContacts,
          icon: Icons.person_outline_rounded,
          onTap: () => choice = 'contact',
        ),
      ],
    );
    if (!mounted || choice == null) return;
    final numbers = choice == 'type'
        ? [?await _typeNumber()]
        : (await pickContact(context, title: context.l10n.blockContact))?.numbers;
    if (numbers != null && numbers.isNotEmpty) await _repo.blockAll(numbers);
  }

  Future<void> _setRules({required bool blockHidden, required bool blockNonContacts}) async {
    final saved = await _repo.setRules(blockHidden: blockHidden, blockNonContacts: blockNonContacts);
    if (!saved && mounted) {
      OneUIToast.show(context, context.l10n.blockingNeedsScreeningRole, long: true);
    }
  }

  Future<String?> _typeNumber() async {
    final number = await showCosTextInput(
      context,
      title: context.l10n.blockNumber,
      hint: context.l10n.phoneNumber,
      keyboardType: TextInputType.phone,
      confirmLabel: context.l10n.block,
    );
    return (number != null && numberKey(number).isNotEmpty) ? number.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: context.l10n.blockAndFilter,
      header: ExpandableSearchHeader(
        controller: _query,
        hint: context.l10n.searchBlockedNumbers,
        leading: Row(
          children: [
            RoundIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: context.l10n.back,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.l10n.blockAndFilter,
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
                    title: context.l10n.blockingPaused,
                    subtitle: context.l10n.blockingPausedSubtitle,
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
                  title: context.l10n.blockUnknown,
                  subtitle: context.l10n.blockUnknownSubtitle,
                  value: rules.blockHidden,
                  onChanged: (v) => _setRules(blockHidden: v, blockNonContacts: rules.blockNonContacts),
                ),
                _switch(
                  title: context.l10n.blockNonContacts,
                  subtitle: context.l10n.blockNonContactsSubtitle,
                  value: rules.blockNonContacts,
                  onChanged: (v) => _setRules(blockHidden: rules.blockHidden, blockNonContacts: v),
                ),
              ],
            ),
          ),
          OneUIGroupCardSliver(
            headerTitle: context.l10n.blockedNumbers,
            itemCount: numbers.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return OneUIGroupItem(
                  leading: Icon(Icons.add_rounded, key: _addKey, color: context.palette.textPrimary),
                  title: context.l10n.addNumber,
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
                  tooltip: context.l10n.unblock,
                  icon: Icon(Icons.remove_circle_outline_rounded, color: context.palette.textSecondary),
                  onPressed: () => _repo.setBlocked(n, false),
                ),
              );
            },
          ),
          if (query.isNotEmpty && numbers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.all(20), child: Text(context.l10n.noMatchingBlocked)),
            ),
          if (blockedCalls.isNotEmpty && query.isEmpty)
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
