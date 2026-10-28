import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_switch.dart';
import '../../widgets/one_ui_toast.dart';
import 'contact_actions.dart';
import 'contact_sections.dart';
import 'contact_subpages.dart' show accountApp;

/// "This device", "SIM card", "Google · me@gmail.com" for an account key (`type|name`).
String accountLabel(String key) {
  final type = key.substring(0, key.indexOf('|'));
  final name = key.substring(key.indexOf('|') + 1);
  final app = accountApp(type);
  // Other apps' and carriers' accounts go by their own name, not "This device".
  if (type.isNotEmpty && app == 'This device') return name.isNotEmpty ? name : type;
  return app == 'Google' && name.isNotEmpty ? 'Google · $name' : app;
}

/// The account a new contact goes to from Manage contacts' save location; null leaves it
/// to Android's default.
// shortcut: "This device" also goes to Android's default (the package can't create a
// no-account contact; the editor makes one natively), upgrade if imports must stay local.
Account? _saveAccount() {
  final key = DialerPrefs.instance.saveAccount.value;
  if (key == null || key.startsWith('|')) return null;
  final i = key.indexOf('|');
  return Account(id: '', type: key.substring(0, i), name: key.substring(i + 1));
}

OneUIGroupItem _switch(String title, ValueNotifier<bool> value, ValueChanged<bool> onChanged, {String? subtitle}) =>
    OneUIGroupItem(
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value.value),
      trailing: ValueListenableBuilder(
        valueListenable: value,
        builder: (context, v, _) => OneUISwitch(value: v, onChanged: onChanged),
      ),
    );

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
            if ('${a['type'] ?? ''}|${a['name'] ?? ''}' case final key) key: accountLabel(key),
        },
      );
    }, onError: (Object _) {});
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _export() async {
    final all = await FlutterContacts.getAll(properties: ContactProperties.all);
    if (all.isEmpty) {
      if (mounted) OneUIToast.show(context, 'No contacts to export');
      return;
    }
    await ContactActions.shareVCards(all);
  }

  Future<void> _import() async {
    final String? text;
    try {
      text = await TelecomBridge.instance.pickVcf();
    } on PlatformException {
      if (mounted) OneUIToast.show(context, "Couldn't open the file");
      return;
    }
    if (text == null || !mounted) return;
    final contacts = FlutterContacts.vCard.import(text);
    if (contacts.isEmpty) {
      OneUIToast.show(context, 'No contacts in this file');
      return;
    }
    final ok = await showCosConfirm(
      context,
      title: contacts.length == 1 ? 'Import 1 contact?' : 'Import ${contacts.length} contacts?',
      message: 'They will be saved to ${accountLabel(_prefs.saveAccount.value ?? '|')}.',
      confirmLabel: 'Import',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await FlutterContacts.createAll(contacts, account: _saveAccount());
      if (mounted) {
        OneUIToast.show(context, contacts.length == 1 ? 'Contact imported' : '${contacts.length} contacts imported');
      }
    } on Object {
      if (mounted) OneUIToast.show(context, "Couldn't import these contacts");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Manage contacts',
      listenable: Listenable.merge([_prefs.hiddenAccounts, ContactsRepository.instance.allContacts]),
      builder: (context) => [
        OneUIGroupCard(
          headerTitle: 'Display',
          items: [
            _switch("Show contact's profile picture", _prefs.showPhotos, _prefs.setShowPhotos),
            _switch('Only display contacts with numbers', _prefs.onlyWithNumbers, _prefs.setOnlyWithNumbers),
            OneUIGroupItem(
              title: 'Contacts to display',
              value: _prefs.hiddenAccounts.value.isEmpty ? 'All' : 'Custom',
              onTap: () => _push(const _ContactsToDisplayScreen()),
            ),
            choiceRow(
              context,
              title: 'Sort by',
              anchor: _sortKey,
              value: _prefs.sortBy,
              labels: const {'first': 'First name', 'last': 'Last name'},
              onPick: _prefs.setSortBy,
            ),
            choiceRow(
              context,
              title: 'Name format',
              anchor: _orderKey,
              value: _prefs.nameOrder,
              labels: const {'first': 'First name first', 'last': 'Last name first'},
              onPick: _prefs.setNameOrder,
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: 'Default save location',
              anchor: _saveKey,
              value: _prefs.saveAccount,
              labels: _saveLabels,
              fallback: 'Phone default',
              onPick: _prefs.setSaveAccount,
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(title: 'Import contacts', subtitle: 'From a .vcf file', onTap: _busy ? null : _import),
            OneUIGroupItem(title: 'Export contacts', subtitle: 'As a .vcf file', onTap: _export),
            OneUIGroupItem(title: 'SIM card contacts', onTap: () => _push(const _SimContactsScreen())),
          ],
        ),
        OneUIGroupCard(
          items: [OneUIGroupItem(title: 'Merge duplicate contacts', onTap: () => _push(const _DuplicatesScreen()))],
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
      title: 'Contacts to display',
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
                  title: accountLabel(a),
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
      await FlutterContacts.createAll(missing, account: _saveAccount());
      if (mounted) {
        OneUIToast.show(context, missing.length == 1 ? 'Contact imported' : '${missing.length} contacts imported');
      }
    } on Object {
      if (mounted) OneUIToast.show(context, "Couldn't import these contacts");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sim,
      builder: (context, snapshot) => OneUISubpage(
        title: 'SIM card contacts',
        listenable: ContactsRepository.instance.contacts,
        builder: (context) {
          if (snapshot.hasError) return [const _Message("Couldn't read the SIM card")];
          final sim = snapshot.data;
          if (sim == null) return [const _Message('Reading the SIM card…')];
          if (sim.isEmpty) return [const _Message('No contacts on the SIM card')];
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
                  title: missing.isEmpty ? 'All saved in Contacts' : 'Import ${missing.length} to Contacts',
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

/// Manage contacts › Merge duplicate contacts: contacts sharing a number or a name.
class _DuplicatesScreen extends StatefulWidget {
  const _DuplicatesScreen();

  @override
  State<_DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<_DuplicatesScreen> {
  bool _busy = false;

  Future<void> _merge(List<List<DialerContact>> groups) async {
    final count = groups.fold(0, (n, g) => n + g.length);
    final ok = await showCosConfirm(
      context,
      title: groups.length == 1
          ? 'Merge ${groups.single.length} contacts?'
          : 'Merge $count contacts into ${groups.length}?',
      message: groups.length == 1
          ? 'They become one contact named ${groups.single.first.name}, with all their numbers and details.'
          : 'Each group becomes one contact, with all its numbers and details.',
      confirmLabel: 'Merge',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      for (final g in groups) {
        await TelecomBridge.instance.mergeContacts([for (final c in g) c.id]);
      }
      ContactsRepository.instance.reload();
      if (mounted) {
        OneUIToast.show(context, groups.length == 1 ? 'Contacts merged' : '${groups.length} contacts merged');
      }
    } on PlatformException {
      if (mounted) OneUIToast.show(context, "Couldn't merge these contacts");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Merge duplicate contacts',
      listenable: ContactsRepository.instance.allContacts,
      builder: (context) {
        final groups = duplicateGroups(ContactsRepository.instance.allContacts.value);
        if (groups.isEmpty) return [const _Message('No duplicate contacts')];
        return [
          OneUIGroupCard(
            items: [
              OneUIGroupItem(
                leading: Icon(Icons.merge_rounded, color: context.palette.textPrimary),
                title: 'Merge all (${groups.length})',
                onTap: _busy ? null : () => _merge(groups),
              ),
            ],
          ),
          for (final g in groups)
            OneUIGroupCard(
              items: [
                for (final c in g) OneUIGroupItem(title: c.name, subtitle: c.numbers.join(', ')),
                OneUIGroupItem(
                  title: 'Merge',
                  leading: const Icon(Icons.merge_rounded, color: OneUITheme.accentGreen),
                  onTap: _busy ? null : () => _merge([g]),
                ),
              ],
            ),
        ];
      },
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
