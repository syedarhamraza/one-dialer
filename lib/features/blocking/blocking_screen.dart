import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_dialog.dart';
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
    final numbers = choice == 'type' ? [?await _typeNumber()] : (await pickContact(context, title: 'Block contact'))?.numbers;
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
      title: 'Block numbers',
      listenable: Listenable.merge([
        _repo.numbers,
        _repo.rules,
        _repo.hasScreeningRole,
        CallLogRepository.instance.calls,
      ]),
      builder: (context) {
        final rules = _repo.rules.value;
        final blockedCalls = CallLogRepository.instance.calls.value
            .where((c) => c.type == CallType.blocked)
            .take(50)
            .toList();
        return [
          if ((rules.blockHidden || rules.blockNonContacts) && !_repo.hasScreeningRole.value)
            OneUIGroupCard(
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
          OneUIGroupCard(
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
          OneUIGroupCard(
            headerTitle: 'Blocked numbers',
            items: [
              OneUIGroupItem(
                leading: Icon(Icons.add_rounded, key: _addKey, color: OneUITheme.accentBlue),
                title: 'Add number',
                onTap: _add,
                trailing: const SizedBox.shrink(),
              ),
              for (final n in _repo.numbers.value)
                OneUIGroupItem(
                  title: ContactsRepository.instance.nameFor(n) ?? n,
                  subtitle: ContactsRepository.instance.nameFor(n) == null ? null : n,
                  trailing: IconButton(
                    tooltip: 'Unblock',
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: OneUITheme.accentRed),
                    onPressed: () => _repo.setBlocked(n, false),
                  ),
                ),
            ],
          ),
          if (blockedCalls.isNotEmpty)
            OneUIGroupCard(
              headerTitle: 'Blocked calls',
              items: [
                for (final c in blockedCalls)
                  OneUIGroupItem(
                    leading: const Icon(Icons.block_rounded, color: OneUITheme.textSecondary),
                    title: callerName(c),
                    subtitle: '${dayLabel(c.date, DateTime.now())}, ${timeLabel(c.date)}',
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CallDetailsScreen(call: c))),
                  ),
              ],
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
