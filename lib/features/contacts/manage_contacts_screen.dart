import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/select_mark.dart';
import '../recents/call_log.dart' show numberKey;
import 'contact_details_screen.dart' show DetailsCard;
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_switch.dart';
import '../../widgets/one_ui_toast.dart';
import 'contact_actions.dart';
import 'contact_sections.dart';
import 'contact_subpages.dart' show accountApp;
import '../../l10n/l10n.dart';

/// "This device", "SIM card", "Google · me@gmail.com" for an account key (`type|name`).
String accountLabel(AppLocalizations l10n, String key) {
  final type = key.substring(0, key.indexOf('|'));
  final name = key.substring(key.indexOf('|') + 1);
  final app = accountApp(l10n, type);
  // Other apps' and carriers' accounts go by their own name, not "This device".
  if (type.isNotEmpty && app == l10n.accountThisDevice) return name.isNotEmpty ? name : type;
  return app == 'Google' && name.isNotEmpty ? 'Google · $name' : app;
}

/// The account a new contact goes to from Manage contacts' save location; null leaves it
/// to Android's default.
// shortcut: "This device" also goes to Android's default (the package can't create a
// no-account contact; the editor makes one natively), upgrade if imports must stay local.
Account? saveAccount() {
  final key = DialerPrefs.instance.saveAccount.value;
  if (key == null || key.startsWith('|')) return null;
  final i = key.indexOf('|');
  return Account(id: '', type: key.substring(0, i), name: key.substring(i + 1));
}

/// The contacts in a .vcf, or null when it can't be read: the package decodes quoted-printable
/// values as strict UTF-8, and files in another charset (or with a broken line break) threw.
List<Contact>? importVCards(String text) {
  try {
    return FlutterContacts.vCard.import(text);
  } on FormatException {
    return null;
  }
}

/// Contacts ⋮ › Manage contacts, ColorOS's page: what the list shows, where new contacts
/// go, import and export, SIM contacts and merging duplicates.
class ManageContactsScreen extends StatefulWidget {
  const ManageContactsScreen({super.key});

  @override
  State<ManageContactsScreen> createState() => _ManageContactsScreenState();
}

class _ManageContactsScreenState extends State<ManageContactsScreen> {
  final _prefs = DialerPrefs.instance;
  final _sortKey = GlobalKey();
  final _orderKey = GlobalKey();
  final _saveKey = GlobalKey();
  final _mergeKey = GlobalKey();
  Map<String, String> _saveLabels = const {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getContactAccounts().then((all) {
      if (!mounted) return;
      setState(
        () => _saveLabels = {
          for (final a in all)
            if ('${a['type'] ?? ''}|${a['name'] ?? ''}' case final key) key: accountLabel(context.l10n, key),
        },
      );
    }, onError: (Object _) {});
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _export() async {
    final l10n = context.l10n;
    final all = await FlutterContacts.getAll(properties: ContactProperties.all);
    if (all.isEmpty) {
      if (mounted) OneUIToast.show(context, l10n.noContactsToExport);
      return;
    }
    await ContactActions.shareVCards(l10n, all);
  }

  Future<void> _import() async {
    final String? text;
    try {
      text = await TelecomBridge.instance.pickVcf();
    } on PlatformException {
      if (mounted) OneUIToast.show(context, context.l10n.couldNotOpenFile);
      return;
    }
    if (text == null || !mounted) return;
    final contacts = importVCards(text);
    if (contacts == null) {
      OneUIToast.show(context, context.l10n.couldNotOpenFile);
      return;
    }
    if (contacts.isEmpty) {
      OneUIToast.show(context, context.l10n.noContactsInFile);
      return;
    }
    final ok = await showCosConfirm(
      context,
      title: context.l10n.importContactsTitle(contacts.length),
      message: context.l10n.importContactsMessage(accountLabel(context.l10n, _prefs.saveAccount.value ?? '|')),
      confirmLabel: context.l10n.import,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await FlutterContacts.createAll(contacts, account: saveAccount());
      if (mounted) {
        OneUIToast.show(context, context.l10n.contactsImported(contacts.length));
      }
    } on Object {
      if (mounted) OneUIToast.show(context, context.l10n.couldNotImportContacts);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: context.l10n.manageContacts,
      listenable: Listenable.merge([_prefs.hiddenAccounts, ContactsRepository.instance.allContacts]),
      builder: (context) => [
        OneUIGroupCard(
          headerTitle: context.l10n.display,
          items: [
            switchRow(context.l10n.showContactPhotos, _prefs.showPhotos, _prefs.setShowPhotos),
            switchRow(context.l10n.onlyContactsWithNumbers, _prefs.onlyWithNumbers, _prefs.setOnlyWithNumbers),
            OneUIGroupItem(
              title: context.l10n.contactsToDisplay,
              value: _prefs.hiddenAccounts.value.isEmpty ? context.l10n.all : context.l10n.custom,
              onTap: () => _push(const _ContactsToDisplayScreen()),
            ),
            choiceRow(
              context,
              title: context.l10n.sortBy,
              anchor: _sortKey,
              value: _prefs.sortBy,
              labels: {'first': context.l10n.firstName, 'last': context.l10n.lastName},
              onPick: _prefs.setSortBy,
            ),
            choiceRow(
              context,
              title: context.l10n.nameFormat,
              anchor: _orderKey,
              value: _prefs.nameOrder,
              labels: {'first': context.l10n.firstNameFirst, 'last': context.l10n.lastNameFirst},
              onPick: _prefs.setNameOrder,
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: context.l10n.defaultSaveLocation,
              anchor: _saveKey,
              value: _prefs.saveAccount,
              labels: _saveLabels,
              fallback: context.l10n.phoneDefault,
              onPick: _prefs.setSaveAccount,
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: context.l10n.importContacts,
              subtitle: context.l10n.fromVcf,
              onTap: _busy ? null : _import,
            ),
            OneUIGroupItem(title: context.l10n.exportContacts, subtitle: context.l10n.asVcf, onTap: _export),
            OneUIGroupItem(title: context.l10n.simContacts, onTap: () => _push(const _SimContactsScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: context.l10n.mergeDuplicates,
              trailing: Icon(Icons.unfold_more_rounded, key: _mergeKey, size: 22, color: context.palette.textSecondary),
              onTap: () => OneUIFloatingMenu.show(
                context: context,
                anchorKey: _mergeKey,
                width: 270,
                items: [
                  OneUIFloatingMenuItem(
                    label: context.l10n.mergeDuplicatedNames,
                    onTap: () => _push(const _DuplicatesScreen(byNumber: false)),
                  ),
                  OneUIFloatingMenuItem(
                    label: context.l10n.mergeDuplicatedNumbers,
                    onTap: () => _push(const _DuplicatesScreen(byNumber: true)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Manage contacts › Contacts to display: a switch for each account the contacts are in.
class _ContactsToDisplayScreen extends StatelessWidget {
  const _ContactsToDisplayScreen();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return OneUISubpage(
      title: context.l10n.contactsToDisplay,
      listenable: Listenable.merge([prefs.hiddenAccounts, ContactsRepository.instance.allContacts]),
      builder: (context) {
        final accounts = <String>{
          for (final c in ContactsRepository.instance.allContacts.value)
            if (c.accounts.isEmpty) '|' else ...c.accounts,
        };
        final hidden = prefs.hiddenAccounts.value;
        return [
          OneUIGroupCard(
            items: [
              for (final a in accounts)
                OneUIGroupItem(
                  title: accountLabel(context.l10n, a),
                  onTap: () => _set(a, hidden.contains(a)),
                  trailing: OneUISwitch(value: !hidden.contains(a), onChanged: (show) => _set(a, show)),
                ),
            ],
          ),
        ];
      },
    );
  }

  void _set(String account, bool show) {
    final prefs = DialerPrefs.instance;
    final hidden = {...prefs.hiddenAccounts.value};
    show ? hidden.remove(account) : hidden.add(account);
    prefs.setHiddenAccounts(hidden);
  }
}

/// Manage contacts › SIM card contacts: what the SIM holds, with Import for the ones not
/// already saved.
class _SimContactsScreen extends StatefulWidget {
  const _SimContactsScreen();

  @override
  State<_SimContactsScreen> createState() => _SimContactsScreenState();
}

class _SimContactsScreenState extends State<_SimContactsScreen> {
  late final Future<List<Contact>> _sim = FlutterContacts.sim.get();
  bool _busy = false;

  Future<void> _import(List<Contact> missing) async {
    setState(() => _busy = true);
    try {
      await FlutterContacts.createAll(missing, account: saveAccount());
      if (mounted) {
        OneUIToast.show(context, context.l10n.contactsImported(missing.length));
      }
    } on Object {
      if (mounted) OneUIToast.show(context, context.l10n.couldNotImportContacts);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sim,
      builder: (context, snapshot) => OneUISubpage(
        title: context.l10n.simContacts,
        listenable: ContactsRepository.instance.contacts,
        builder: (context) {
          if (snapshot.hasError) return [_Message(context.l10n.simReadError)];
          final sim = snapshot.data;
          if (sim == null) return [_Message(context.l10n.simReading)];
          if (sim.isEmpty) return [_Message(context.l10n.simEmpty)];
          final repo = ContactsRepository.instance;
          final missing = [
            for (final c in sim)
              if (!c.phones.any((p) => repo.contactFor(p.number) != null)) c,
          ];
          return [
            OneUIGroupCard(
              items: [
                OneUIGroupItem(
                  leading: Icon(Icons.download_rounded, color: context.palette.textPrimary),
                  title: missing.isEmpty
                      ? context.l10n.allSavedInContacts
                      : context.l10n.importToContacts(missing.length),
                  onTap: missing.isEmpty || _busy ? null : () => _import(missing),
                ),
              ],
            ),
            OneUIGroupCard(
              items: [
                for (final c in sim)
                  OneUIGroupItem(
                    title: (c.displayName?.trim().isNotEmpty ?? false)
                        ? c.displayName!.trim()
                        : (c.phones.firstOrNull?.number ?? ''),
                    subtitle: c.phones.map((p) => p.number).join(', '),
                  ),
              ],
            ),
          ];
        },
      ),
    );
  }
}

/// Manage contacts › Merge duplicate contacts › names or numbers: ColorOS's "Manually merge
/// duplicates", one card per group with Merge manually.
class _DuplicatesScreen extends StatelessWidget {
  const _DuplicatesScreen({required this.byNumber});

  final bool byNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OneUISubpage(
      title: l10n.manuallyMergeDuplicates,
      listenable: ContactsRepository.instance.allContacts,
      bottomPill: ValueListenableBuilder(
        valueListenable: ContactsRepository.instance.allContacts,
        builder: (context, contacts, _) {
          final groups = duplicateGroups(contacts, byNumber: byNumber);
          if (groups.isEmpty) return const SizedBox.shrink();
          return OneUISubpage.actionBar([
            OneUIFloatingActionBarItem(
              icon: Icons.merge_rounded,
              label: l10n.mergeAll('${groups.length}'),
              onTap: () => _mergeAll(context, groups),
            ),
          ]);
        },
      ),
      builder: (context) {
        final groups = duplicateGroups(ContactsRepository.instance.allContacts.value, byNumber: byNumber);
        if (groups.isEmpty) return [_Message(l10n.noDuplicateContacts)];
        final grey = TextStyle(fontSize: 14, color: context.palette.textSecondary);
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Row(
              children: [
                Expanded(child: Text(byNumber ? l10n.sameNumberContacts : l10n.sameNameContacts, style: grey)),
                Text(l10n.groupCount(groups.length), style: grey),
              ],
            ),
          ),
          for (final g in groups)
            DetailsCard(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
              dividerIndent: 62,
              children: [
                for (final c in g)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        ContactAvatar(id: c.id, name: c.name, size: 46),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 18),
                              ),
                              if (c.numbers.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  c.numbers.join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 4),
                              _AccountsLine(contact: c),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(child: _groupAction(l10n.merge, () => _mergeGroups(context, [g]))),
                    Container(width: 1, height: 20, color: context.palette.divider),
                    Expanded(
                      child: _groupAction(
                        l10n.mergeManually,
                        () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute<void>(builder: (_) => _MergeDetailsScreen(group: g))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ];
      },
    );
  }

  Widget _groupAction(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(foregroundColor: OneUITheme.accentGreen, minimumSize: const Size.fromHeight(52)),
    child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
  );

  static bool _merging = false;

  /// Merges each group without the details page: every number kept, the best name
  /// ([_nameRank]). One failed group doesn't stop the rest.
  static Future<void> _mergeGroups(BuildContext context, List<List<DialerContact>> groups) async {
    if (_merging) return; // a second tap would merge ids the first one already replaced
    _merging = true;
    final l10n = context.l10n;
    var merged = 0;
    try {
      for (final g in groups) {
        final keep = g.reduce((a, b) => _nameRank(b) > _nameRank(a) ? b : a);
        try {
          await TelecomBridge.instance.mergeContacts([for (final c in g) c.id], nameContactId: keep.id);
          merged++;
        } on PlatformException {
          // Counted below as not merged.
        }
      }
      ContactsRepository.instance.reload();
      if (!context.mounted) return;
      OneUIToast.show(context, merged == 0 ? l10n.couldNotMergeContacts : l10n.contactsMerged(merged));
    } finally {
      _merging = false;
    }
  }

  static Future<void> _mergeAll(BuildContext context, List<List<DialerContact>> groups) async {
    final l10n = context.l10n;
    final ok = await showCosConfirm(
      context,
      title: l10n.mergeGroupsTitle('${groups.fold(0, (n, g) => n + g.length)}', '${groups.length}'),
      message: l10n.mergeGroupsMessage,
      confirmLabel: l10n.merge,
    );
    if (ok && context.mounted) await _mergeGroups(context, groups);
  }

  /// A real name beats a bare number, and a synced account's copy beats a SIM's.
  static int _nameRank(DialerContact c) =>
      (RegExp(r'\p{L}', unicode: true).hasMatch(c.name) ? 2 : 0) +
      (c.accounts.any((a) => !a.toLowerCase().contains('sim')) ? 1 : 0);
}

/// Where a duplicate lives, one icon and app name per account: SIM card, Google, WhatsApp...
class _AccountsLine extends StatelessWidget {
  const _AccountsLine({required this.contact});

  final DialerContact contact;

  static IconData _icon(String type) => switch (type.toLowerCase()) {
    final t when t.contains('sdn') || t.contains('sim') => Icons.sim_card_outlined,
    final t when t.contains('google') && !t.contains('tachyon') => Icons.cloud_outlined,
    '' => Icons.smartphone_rounded,
    _ => Icons.apps_rounded, // WhatsApp, Telegram, Meet and other apps' copies
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final types = contact.accounts.isEmpty ? [''] : [for (final a in contact.accounts) a.substring(0, a.indexOf('|'))];
    final seen = <String>{};
    final color = context.palette.textSecondary;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final t in types)
          if (seen.add(accountApp(l10n, t)))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon(t), size: 15, color: color),
                const SizedBox(width: 4),
                Text(accountApp(l10n, t), style: TextStyle(fontSize: 13, color: color)),
              ],
            ),
      ],
    );
  }
}

/// "Manual merging details": which name the merged contact keeps, and which numbers (an
/// unticked one is deleted from it).
class _MergeDetailsScreen extends StatefulWidget {
  const _MergeDetailsScreen({required this.group});

  final List<DialerContact> group;

  @override
  State<_MergeDetailsScreen> createState() => _MergeDetailsScreenState();
}

class _MergeDetailsScreenState extends State<_MergeDetailsScreen> {
  /// One name per contact (the same name twice once), in group order: the contact it's from.
  late final Map<String, String> _names = () {
    final out = <String, String>{};
    for (final c in widget.group) {
      if (c.name.trim().isNotEmpty) out.putIfAbsent(c.name, () => c.id);
    }
    return out;
  }();

  /// Every number once, by [numberKey], as first written.
  late final Map<String, String> _numbers = () {
    final out = <String, String>{};
    for (final c in widget.group) {
      for (final n in c.numbers) {
        if (numberKey(n).isNotEmpty) out.putIfAbsent(numberKey(n), () => n);
      }
    }
    return out;
  }();

  late String? _name = _names.keys.firstOrNull;
  late final Set<String> _kept = {..._numbers.keys};
  bool _busy = false;

  Future<void> _merge() async {
    final l10n = context.l10n;
    final removed = [
      for (final MapEntry(:key, :value) in _numbers.entries)
        if (!_kept.contains(key)) value,
    ];
    if (removed.isNotEmpty) {
      final ok = await showCosConfirm(
        context,
        title: l10n.mergeGroupTitle('${widget.group.length}'),
        message: l10n.mergeDeletesNumbers(removed.length),
        confirmLabel: l10n.merge,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await TelecomBridge.instance.mergeContacts(
        [for (final c in widget.group) c.id],
        nameContactId: _names[_name],
        removeNumbers: removed,
      );
      ContactsRepository.instance.reload();
      if (!mounted) return;
      OneUIToast.show(context, l10n.contactsMerged(1));
      Navigator.of(context).pop();
    } on PlatformException {
      if (mounted) OneUIToast.show(context, l10n.couldNotMergeContacts);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = TextStyle(fontSize: 15, color: context.palette.textSecondary);
    return OneUISubpage(
      title: l10n.manualMergingDetails,
      bottomPill: OneUISubpage.actionBar([
        OneUIFloatingActionBarItem(
          icon: Icons.merge_rounded,
          label: l10n.merge,
          isEnabled: !_busy && (_numbers.isEmpty || _kept.isNotEmpty),
          onTap: _merge,
        ),
      ]),
      builder: (context) => [
        if (_names.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 18, bottom: 8),
            child: Text(l10n.nameRequired, style: label),
          ),
          OneUIGroupCard(
            items: [
              for (final name in _names.keys)
                OneUIGroupItem(
                  title: name,
                  onTap: () => setState(() => _name = name),
                  trailing: OneUIRadio(isSelected: name == _name, selectedColor: OneUITheme.accentGreen),
                ),
            ],
          ),
        ],
        if (_numbers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 18, bottom: 8),
            child: Text(l10n.numbersSelectMany, style: label),
          ),
          OneUIGroupCard(
            items: [
              for (final MapEntry(:key, :value) in _numbers.entries)
                OneUIGroupItem(
                  title: value,
                  onTap: () => setState(() => _kept.contains(key) ? _kept.remove(key) : _kept.add(key)),
                  trailing: SelectMark(selected: _kept.contains(key), gap: 0),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: context.palette.textSecondary),
    ),
  );
}
