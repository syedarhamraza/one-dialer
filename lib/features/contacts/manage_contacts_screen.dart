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
Account? _saveAccount() {
  final key = DialerPrefs.instance.saveAccount.value;
  if (key == null || key.startsWith('|')) return null;
  final i = key.indexOf('|');
  return Account(id: '', type: key.substring(0, i), name: key.substring(i + 1));
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
    final contacts = FlutterContacts.vCard.import(text);
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
      await FlutterContacts.createAll(contacts, account: _saveAccount());
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
          items: [OneUIGroupItem(title: context.l10n.mergeDuplicates, onTap: () => _push(const _DuplicatesScreen()))],
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
      await FlutterContacts.createAll(missing, account: _saveAccount());
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
          ? context.l10n.mergeGroupTitle('${groups.single.length}')
          : context.l10n.mergeGroupsTitle('$count', '${groups.length}'),
      message: groups.length == 1
          ? context.l10n.mergeGroupMessage(groups.single.first.name)
          : context.l10n.mergeGroupsMessage,
      confirmLabel: context.l10n.merge,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      for (final g in groups) {
        await TelecomBridge.instance.mergeContacts([for (final c in g) c.id]);
      }
      ContactsRepository.instance.reload();
      if (mounted) {
        OneUIToast.show(context, context.l10n.contactsMerged(groups.length));
      }
    } on PlatformException {
      if (mounted) OneUIToast.show(context, context.l10n.couldNotMergeContacts);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: context.l10n.mergeDuplicates,
      listenable: ContactsRepository.instance.allContacts,
      builder: (context) {
        final groups = duplicateGroups(ContactsRepository.instance.allContacts.value);
        if (groups.isEmpty) return [_Message(context.l10n.noDuplicateContacts)];
        return [
          OneUIGroupCard(
            items: [
              OneUIGroupItem(
                leading: Icon(Icons.merge_rounded, color: context.palette.textPrimary),
                title: context.l10n.mergeAll('${groups.length}'),
                onTap: _busy ? null : () => _merge(groups),
              ),
            ],
          ),
          for (final g in groups)
            OneUIGroupCard(
              items: [
                for (final c in g) OneUIGroupItem(title: c.name, subtitle: c.numbers.join(', ')),
                OneUIGroupItem(
                  title: context.l10n.merge,
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
