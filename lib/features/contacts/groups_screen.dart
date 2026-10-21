import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import 'contact_details_screen.dart';

/// Google's built-in groups that aren't real user groups (also hidden in the editor).
const hiddenGroupNames = {'My Contacts', 'Starred in Android'};

/// Contact groups (from all accounts) with member counts.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group>? _groups;

  @override
  void initState() {
    super.initState();
    FlutterContacts.groups.getAll(withContactCount: true).then((g) {
      if (!mounted) return;
      setState(
        () => _groups = [
          for (final x in g)
            if (!hiddenGroupNames.contains(x.name)) x,
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return OneUISubpage(
      title: 'Groups',
      builder: (context) => [
        if (groups != null && groups.isEmpty)
          // Laid out like Calls' empty state: a large grey icon over the text.
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 80, 32, 0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined, size: 40, color: OneUITheme.textSecondary),
                  SizedBox(height: 12),
                  Text('No groups', style: TextStyle(color: OneUITheme.textSecondary)),
                ],
              ),
            ),
          ),
        if (groups != null && groups.isNotEmpty)
          OneUIGroupCard(
            items: [
              for (final g in groups)
                OneUIGroupItem(
                  // The green circle of the Contacts tab's "My groups" row.
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: OneUITheme.dialGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.group_rounded, color: Colors.white, size: 22),
                  ),
                  title: g.name,
                  subtitle: '${g.contactCount ?? 0} contacts',
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupMembersScreen(group: g))),
                ),
            ],
          ),
      ],
    );
  }
}

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  Set<String>? _ids;

  @override
  void initState() {
    super.initState();
    FlutterContacts.getAll(filter: ContactFilter.group(widget.group.id!)).then((c) {
      if (mounted) setState(() => _ids = {for (final x in c) ?x.id});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ids = _ids;
    final members = ids == null
        ? const <DialerContact>[]
        : [
            for (final c in ContactsRepository.instance.contacts.value)
              if (ids.contains(c.id)) c,
          ];
    return OneUISubpage(
      title: widget.group.name,
      builder: (context) => [
        if (ids != null && members.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: Text('No contacts with numbers', style: TextStyle(color: OneUITheme.textSecondary)),
            ),
          ),
        if (members.isNotEmpty)
          OneUIGroupCard(
            items: [
              for (final c in members)
                OneUIGroupItem(
                  leading: LetterAvatar(name: c.name, photo: c.thumbnail),
                  title: c.name,
                  trailing: const SizedBox.shrink(),
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => ContactDetailsScreen(contactId: c.id))),
                ),
            ],
          ),
      ],
    );
  }
}
