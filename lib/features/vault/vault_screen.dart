import 'package:flutter/material.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/place_call.dart';
import '../recents/call_log.dart' show dayLabel, timeLabel, numberKey;
import 'vault.dart';

/// The private vault: its contacts and their calls. Opened only after the unlock prompt
/// ([PrivateVault.open]); closes again when the app goes to the background.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with WidgetsBindingObserver {
  final _data = ValueNotifier<({List<VaultContact> contacts, List<VaultCall> calls})>((contacts: [], calls: []));
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _data.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _closeIfLeft();
    if (state == AppLifecycleState.resumed) _load(); // a call may have moved in meanwhile
  }

  /// Leaving the app closes the vault; our own pickers (Import) don't.
  Future<void> _closeIfLeft() async {
    if (await TelecomBridge.instance.expectingReturn()) return;
    if (!mounted) return;
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    navigator.popUntil((r) => r == route); // and any menu or alert over it
    navigator.pop();
  }

  Future<void> _load() async {
    final data = await PrivateVault.read();
    if (mounted) _data.value = data;
  }

  String _nameFor(String number) {
    final key = numberKey(number);
    for (final c in _data.value.contacts) {
      if (c.numbers.any((n) => numberKey(n) == key)) return c.name;
    }
    return number;
  }

  void _contactMenu(VaultContact contact) {
    final l10n = context.l10n;
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _keys.putIfAbsent(contact.id, GlobalKey.new),
      width: 260,
      items: [
        for (final n in contact.numbers)
          OneUIFloatingMenuItem(label: '${l10n.call} $n', onTap: () => placeCall(context, n)),
        OneUIFloatingMenuItem(
          label: l10n.moveOutOfVault,
          onTap: () async {
            if (await PrivateVault.moveOut(context, contact)) _load();
          },
        ),
        OneUIFloatingMenuItem(
          label: l10n.delete,
          onTap: () async {
            if (await PrivateVault.delete(context, contact)) _load();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    return OneUISubpage(
      title: l10n.privateVault,
      listenable: _data,
      builder: (context) {
        final (:contacts, :calls) = _data.value;
        return [
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Text(l10n.vaultEmpty, style: TextStyle(fontSize: 15, color: context.palette.textSecondary)),
            )
          else
            OneUIGroupCard(
              headerTitle: l10n.navContacts,
              items: [
                for (final c in contacts)
                  OneUIGroupItem(
                    leading: LetterAvatar(name: c.name, size: 40),
                    title: c.name.isEmpty ? l10n.unknown : c.name,
                    subtitle: c.numbers.firstOrNull,
                    trailing: Icon(
                      Icons.more_vert_rounded,
                      key: _keys.putIfAbsent(c.id, GlobalKey.new),
                      color: context.palette.textSecondary,
                    ),
                    onTap: () => _contactMenu(c),
                  ),
              ],
            ),
          if (calls.isNotEmpty)
            OneUIGroupCard(
              headerTitle: l10n.vaultCalls,
              items: [
                for (final call in calls)
                  OneUIGroupItem(
                    leading: Icon(switch (call.type) {
                      2 => Icons.call_made_rounded,
                      3 || 5 => Icons.call_missed_rounded,
                      _ => Icons.call_received_rounded,
                    }, color: call.type == 3 || call.type == 5 ? OneUITheme.accentRed : context.palette.textSecondary),
                    title: _nameFor(call.number),
                    subtitle: switch (call.type) {
                      2 => l10n.callTypeOutgoing,
                      3 || 5 => l10n.callTypeMissed,
                      _ => l10n.callTypeIncoming,
                    },
                    value: () {
                      final at = DateTime.fromMillisecondsSinceEpoch(call.date);
                      return '${dayLabel(l10n, at, now)} ${timeLabel(l10n, at)}';
                    }(),
                    onTap: () => placeCall(context, call.number),
                  ),
              ],
            ),
          OneUIGroupCard(
            margin: const EdgeInsets.only(bottom: 8),
            items: [
              OneUIGroupItem(
                title: l10n.vaultImport,
                onTap: () async {
                  if (await PrivateVault.import(context) > 0) _load();
                },
              ),
              OneUIGroupItem(
                title: l10n.exportContacts,
                enabled: contacts.isNotEmpty,
                onTap: () => PrivateVault.export(context, contacts),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Text(l10n.vaultUninstallNote, style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
          ),
        ];
      },
    );
  }
}
