import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';

import '../../../core/telecom/telecom_bridge.dart';
import '../../../theme/one_ui_scroll.dart';
import '../../../theme/one_ui_theme.dart';
import '../../../widgets/letter_avatar.dart';
import '../../../widgets/one_ui_cancel_save_pill.dart';
import '../../../widgets/one_ui_date_wheel.dart';
import '../../../widgets/one_ui_floating_menu.dart';
import '../../../widgets/one_ui_floating_modal.dart';
import '../../../widgets/one_ui_radio.dart';
import '../groups_screen.dart' show hiddenGroupNames;
import 'contact_form.dart';
import 'editor_widgets.dart';

/// Opens the editor: a new contact (optionally with [number]) or [contactId] (optionally
/// adding [number] to it). Returns the saved contact's id, or null if cancelled.
Future<String?> openContactEditor(BuildContext context, {String? contactId, String? number}) => Navigator.of(context)
    .push<String>(
      MaterialPageRoute(
        builder: (_) => ContactEditorScreen(contactId: contactId, initialNumber: number),
      ),
    );

/// Samsung-style add/edit contact screen (replaces Android's contact editor).
class ContactEditorScreen extends StatefulWidget {
  const ContactEditorScreen({super.key, this.contactId, this.initialNumber});

  final String? contactId;
  final String? initialNumber;

  @override
  State<ContactEditorScreen> createState() => _ContactEditorScreenState();
}

class _ContactEditorScreenState extends State<ContactEditorScreen> {
  ContactForm? _form;
  Contact? _base; // the loaded contact when editing
  String _savedSignature = '';
  Set<String> _initialGroups = const {};
  List<Account> _accounts = const [];
  Account? _account;
  List<Group> _groups = const [];
  bool _nameExpanded = false, _workOpen = false, _more = false, _saving = false;

  bool get _isNew => widget.contactId == null;

  static List<Group> _userGroups(List<Group> all) => [
    for (final g in all)
      if (!hiddenGroupNames.contains(g.name)) g,
  ];
  bool get _dirty => _form != null && _form!.signature != _savedSignature;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var form = ContactForm();
    if (!_isNew) {
      final c = await FlutterContacts.get(widget.contactId!, properties: ContactProperties.all);
      if (c == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final groups = await FlutterContacts.groups.getOf(widget.contactId!);
      _base = c;
      _initialGroups = {for (final g in groups) ?g.id};
      form = ContactForm.fromContact(c, groupIds: _initialGroups);
    } else {
      _accounts = await FlutterContacts.accounts.getAll();
      _account = await FlutterContacts.accounts.getDefault() ?? _accounts.firstOrNull;
    }
    final savedSignature = form.signature; // the number below is an unsaved change
    if (widget.initialNumber case final n? when n.trim().isNotEmpty) {
      form.phones.add(LabeledValue(label: 'mobile', value: n.trim()));
    }
    if (form.phones.isEmpty) form.phones.add(LabeledValue(label: 'mobile'));
    _groups = _userGroups(await FlutterContacts.groups.getAll(accounts: _account == null ? null : [_account!]));
    if (!mounted) return;
    setState(() {
      _form = form;
      _savedSignature = savedSignature;
      _workOpen = form.company.isNotEmpty || form.jobTitle.isNotEmpty || form.department.isNotEmpty;
      _more = form.dates.isNotEmpty || form.websites.isNotEmpty || form.relations.isNotEmpty || form.notes.isNotEmpty;
    });
  }

  Future<void> _save() async {
    final form = _form!;
    if (form.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final String id;
      if (_base == null) {
        id = await FlutterContacts.create(form.applyTo(const Contact()), account: _account);
      } else {
        await FlutterContacts.update(form.applyTo(_base!));
        id = _base!.id!;
      }
      for (final g in form.groupIds.difference(_initialGroups)) {
        await FlutterContacts.groups.addContacts(groupId: g, contactIds: [id]);
      }
      for (final g in _initialGroups.difference(form.groupIds)) {
        await FlutterContacts.groups.removeContacts(groupId: g, contactIds: [id]);
      }
      if (mounted) Navigator.of(context).pop(id);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'read_only_contact'
                ? "This contact's account is read-only, so it can't be changed here"
                : "Couldn't save the contact",
          ),
        ),
      );
    }
  }

  /// "Save your changes or discard them?" on back with unsaved changes.
  Future<void> _confirmLeave() async {
    final choice = await OneUIFloatingModal.show<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Save your changes or discard them?', style: TextStyle(fontSize: 16.5, color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final (i, (label, value)) in [
                ('Cancel', null),
                ('Discard', 'discard'),
                ('Save', 'save'),
              ].indexed) ...[
                if (i > 0) Container(width: 1, height: 18, color: Colors.white.withValues(alpha: 0.10)),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, value),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'discard') Navigator.of(context).pop();
    if (choice == 'save') await _save();
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        body: form == null
            ? const SizedBox.expand()
            : Stack(
                children: [
                  ListView(
                    physics: const OneUIScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 140),
                    children: [
                      if (_isNew && _accounts.isNotEmpty) _accountRow(),
                      _photo(form),
                      const SizedBox(height: 24),
                      _mainCard(form),
                      _listCard(
                        icon: Icons.mail_outline_rounded,
                        title: 'Email',
                        addLabel: 'Add email',
                        rows: form.emails,
                        options: EditorLabels.email,
                        keyboard: TextInputType.emailAddress,
                        newLabel: 'home',
                      ),
                      _addressCard(form),
                      if (_more) ...[
                        _datesCard(form),
                        _groupsCard(form),
                        _listCard(
                          icon: Icons.language_rounded,
                          title: 'Website',
                          addLabel: 'Add website',
                          rows: form.websites,
                          options: EditorLabels.website,
                          keyboard: TextInputType.url,
                          newLabel: 'homepage',
                        ),
                        _listCard(
                          icon: Icons.diversity_3_outlined,
                          title: 'Relationships',
                          addLabel: 'Add relationship',
                          rows: form.relations,
                          options: EditorLabels.relation,
                          newLabel: 'friend',
                          capitalization: TextCapitalization.words,
                        ),
                        EditorCard(
                          children: [
                            EditorRow(
                              icon: Icons.sticky_note_2_outlined,
                              child: EditorField(
                                hint: 'Notes',
                                value: form.notes,
                                maxLines: null,
                                onChanged: (v) => setState(() => form.notes = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _more = !_more),
                          icon: Icon(_more ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                          label: Text(_more ? 'View less' : 'View more', style: const TextStyle(fontSize: 17)),
                          style: TextButton.styleFrom(foregroundColor: OneUITheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OneUIFloatingCancelSavePill(
                          onCancel: () => Navigator.of(context).maybePop(),
                          onSave: _save,
                          canSave: !form.isEmpty && !_saving,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Account ---------------------------------------------------------------

  Widget _accountRow() {
    final account = _account;
    return InkWell(
      borderRadius: OneUITheme.pillBorderRadius,
      onTap: _chooseAccount,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _accountIcon(account),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                account?.name ?? 'Phone',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _accountIcon(Account? a) {
    final google = a?.type.contains('google') ?? false;
    return CircleAvatar(
      radius: 16,
      backgroundColor: google ? Colors.white : OneUITheme.surfacePill,
      child: google
          ? const Text(
              'G',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4285F4)),
            )
          : const Icon(Icons.smartphone_rounded, size: 18, color: OneUITheme.textSecondary),
    );
  }

  Future<void> _chooseAccount() async {
    final picked = await OneUIFloatingModal.show<Account>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Save contact to', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final a in _accounts)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(ctx, a),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    OneUIRadio(isSelected: a.id == _account?.id && a.type == _account?.type),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_accountTypeName(a), style: const TextStyle(fontSize: 17)),
                          Text(a.name, style: const TextStyle(fontSize: 14, color: OneUITheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final groups = _userGroups(await FlutterContacts.groups.getAll(accounts: [picked]));
    setState(() {
      _account = picked;
      _groups = groups;
      _form!.groupIds = {}; // groups belong to an account
    });
  }

  static String _accountTypeName(Account a) => switch (a.type) {
    final t when t.contains('google') => 'Google',
    final t when t.contains('samsung') => 'Samsung account',
    final t when t.contains('whatsapp') => 'WhatsApp',
    final t when t.contains('sim') => 'SIM',
    _ => 'Phone',
  };

  // --- Photo -----------------------------------------------------------------

  Widget _photo(ContactForm form) {
    final existing = form.photoRemoved ? null : (_base?.photo?.fullSize ?? _base?.photo?.thumbnail);
    final photo = form.newPhoto ?? existing;
    return Column(
      children: [
        LetterAvatar(
          name: form.fullName.isEmpty ? (form.phones.firstOrNull?.value ?? '') : form.fullName,
          photo: photo,
          size: 128,
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(
          onPressed: () => _photoMenu(hasPhoto: photo != null),
          style: FilledButton.styleFrom(
            backgroundColor: OneUITheme.surfacePill,
            foregroundColor: OneUITheme.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          ),
          child: const Text('Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Future<void> _photoMenu({required bool hasPhoto}) async {
    Future<void> gallery() async {
      final bytes = await TelecomBridge.instance.pickPhoto();
      if (bytes != null) {
        setState(
          () => _form!
            ..newPhoto = bytes
            ..photoRemoved = false,
        );
      }
    }

    if (!hasPhoto) return gallery();
    await OneUIFloatingMenu.show(
      context: context,
      fallbackTop: 300,
      fallbackRight: 80,
      items: [
        OneUIFloatingMenuItem(label: 'Gallery', icon: Icons.photo_library_outlined, onTap: gallery),
        OneUIFloatingMenuItem(
          label: 'Remove picture',
          icon: Icons.delete_outline_rounded,
          onTap: () => setState(
            () => _form!
              ..newPhoto = null
              ..photoRemoved = true,
          ),
        ),
      ],
    );
  }

  // --- Name, phones, work ----------------------------------------------------

  Widget _mainCard(ContactForm form) {
    return EditorCard(
      children: [
        EditorRow(
          icon: Icons.person_outline_rounded,
          iconColor: OneUITheme.accentBlue,
          trailing: IconButton(
            tooltip: _nameExpanded ? 'Fewer name fields' : 'More name fields',
            onPressed: () => setState(() => _nameExpanded = !_nameExpanded),
            icon: Icon(_nameExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 30),
          ),
          child: _nameExpanded
              ? Column(
                  key: const ValueKey('name-parts'),
                  children: [
                    for (final (hint, get, set) in <(String, String Function(), void Function(String))>[
                      ('Name prefix', () => form.prefix, (v) => form.prefix = v),
                      ('First name', () => form.first, (v) => form.first = v),
                      ('Middle name', () => form.middle, (v) => form.middle = v),
                      ('Last name', () => form.last, (v) => form.last = v),
                      ('Name suffix', () => form.suffix, (v) => form.suffix = v),
                    ])
                      EditorField(
                        hint: hint,
                        value: get(),
                        capitalization: TextCapitalization.words,
                        onChanged: (v) => setState(() => set(v)),
                      ),
                  ],
                )
              : EditorField(
                  key: const ValueKey('name-full'),
                  hint: 'Name',
                  value: form.fullName,
                  autofocus: _isNew && widget.initialNumber == null,
                  capitalization: TextCapitalization.words,
                  onChanged: (v) => setState(() => form.fullName = v),
                ),
        ),
        for (final (i, phone) in form.phones.indexed)
          EditorRow(
            key: ObjectKey(phone),
            icon: i == 0 ? Icons.call_outlined : null,
            iconColor: OneUITheme.accentBlue,
            trailing: RemoveButton(onPressed: () => setState(() => form.phones.remove(phone))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelButton(
                  label: phone.label,
                  options: EditorLabels.phone,
                  onChanged: (l) => setState(() => phone.label = l),
                ),
                EditorField(
                  hint: 'Phone',
                  value: phone.value,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => setState(() => phone.value = v),
                ),
              ],
            ),
          ),
        AddRow(
          label: 'Add phone number',
          onTap: () => setState(() => form.phones.add(LabeledValue(label: 'mobile'))),
        ),
        if (!_workOpen)
          PlaceholderRow(
            icon: Icons.work_outline_rounded,
            label: 'Work info',
            onTap: () => setState(() => _workOpen = true),
          )
        else
          EditorRow(
            icon: Icons.work_outline_rounded,
            child: Column(
              children: [
                EditorField(hint: 'Company', value: form.company, onChanged: (v) => setState(() => form.company = v)),
                EditorField(
                  hint: 'Job title',
                  value: form.jobTitle,
                  onChanged: (v) => setState(() => form.jobTitle = v),
                ),
                EditorField(
                  hint: 'Department',
                  value: form.department,
                  onChanged: (v) => setState(() => form.department = v),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- Emails, websites, relationships --------------------------------------

  Widget _listCard({
    required IconData icon,
    required String title,
    required String addLabel,
    required List<LabeledValue> rows,
    required List<String> options,
    required String newLabel,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    if (rows.isEmpty) {
      return EditorCard(
        children: [
          PlaceholderRow(
            icon: icon,
            label: title,
            onTap: () => setState(() => rows.add(LabeledValue(label: newLabel))),
          ),
        ],
      );
    }
    return EditorCard(
      children: [
        for (final (i, row) in rows.indexed)
          EditorRow(
            key: ObjectKey(row),
            icon: i == 0 ? icon : null,
            trailing: RemoveButton(onPressed: () => setState(() => rows.remove(row))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelButton(label: row.label, options: options, onChanged: (l) => setState(() => row.label = l)),
                EditorField(
                  hint: title,
                  value: row.value,
                  keyboardType: keyboard,
                  capitalization: capitalization,
                  autofocus: row.value.isEmpty && i == rows.length - 1,
                  onChanged: (v) => setState(() => row.value = v),
                ),
              ],
            ),
          ),
        AddRow(
          label: addLabel,
          onTap: () => setState(() => rows.add(LabeledValue(label: newLabel))),
        ),
      ],
    );
  }

  // --- Address ---------------------------------------------------------------

  Widget _addressCard(ContactForm form) {
    if (form.addresses.isEmpty) {
      return EditorCard(
        children: [
          PlaceholderRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            onTap: () => setState(() => form.addresses.add(AddressValue())),
          ),
        ],
      );
    }
    return EditorCard(
      children: [
        for (final (i, a) in form.addresses.indexed)
          EditorRow(
            key: ObjectKey(a),
            icon: i == 0 ? Icons.location_on_outlined : null,
            trailing: RemoveButton(onPressed: () => setState(() => form.addresses.remove(a))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelButton(
                  label: a.label,
                  options: EditorLabels.address,
                  onChanged: (l) => setState(() => a.label = l),
                ),
                EditorField(
                  hint: 'Street',
                  value: a.street,
                  maxLines: null,
                  onChanged: (v) => setState(() => a.street = v),
                ),
                EditorField(hint: 'City', value: a.city, onChanged: (v) => setState(() => a.city = v)),
                EditorField(hint: 'State/Province', value: a.region, onChanged: (v) => setState(() => a.region = v)),
                EditorField(
                  hint: 'Postal code',
                  value: a.postcode,
                  keyboardType: TextInputType.streetAddress,
                  onChanged: (v) => setState(() => a.postcode = v),
                ),
                EditorField(hint: 'Country', value: a.country, onChanged: (v) => setState(() => a.country = v)),
              ],
            ),
          ),
        AddRow(label: 'Add address', onTap: () => setState(() => form.addresses.add(AddressValue()))),
      ],
    );
  }

  // --- Important dates -------------------------------------------------------

  Widget _datesCard(ContactForm form) {
    String format(DateValue d) => d.year == null
        ? DateFormat.MMMMd().format(DateTime(2000, d.month, d.day))
        : DateFormat.yMMMMd().format(DateTime(d.year!, d.month, d.day));

    Future<void> pick(DateValue? existing) async {
      final now = DateTime.now();
      var chosen = existing == null ? now : DateTime(existing.year ?? now.year, existing.month, existing.day);
      final ok = await OneUIFloatingModal.show<bool>(
        context: context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Important date', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            OneUIDateWheel(
              date: chosen,
              firstDate: DateTime(1900),
              lastDate: DateTime(now.year + 50),
              onChanged: (d) => chosen = d,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ),
                Expanded(
                  child: TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Done')),
                ),
              ],
            ),
          ],
        ),
      );
      if (ok != true) return;
      setState(() {
        if (existing == null) {
          form.dates.add(DateValue(year: chosen.year, month: chosen.month, day: chosen.day));
        } else {
          existing
            ..year = chosen.year
            ..month = chosen.month
            ..day = chosen.day;
        }
      });
    }

    if (form.dates.isEmpty) {
      return EditorCard(
        children: [PlaceholderRow(icon: Icons.event_note_outlined, label: 'Important dates', onTap: () => pick(null))],
      );
    }
    return EditorCard(
      children: [
        for (final (i, d) in form.dates.indexed)
          EditorRow(
            key: ObjectKey(d),
            icon: i == 0 ? Icons.event_note_outlined : null,
            trailing: RemoveButton(onPressed: () => setState(() => form.dates.remove(d))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelButton(label: d.label, options: EditorLabels.date, onChanged: (l) => setState(() => d.label = l)),
                InkWell(
                  onTap: () => pick(d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(format(d), style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        AddRow(label: 'Add important date', onTap: () => pick(null)),
      ],
    );
  }

  // --- Groups ----------------------------------------------------------------

  Widget _groupsCard(ContactForm form) {
    final names = [
      for (final g in _groups)
        if (form.groupIds.contains(g.id)) g.name,
    ];
    return EditorCard(
      children: [
        InkWell(
          borderRadius: OneUITheme.cardBorderRadius,
          onTap: _groups.isEmpty ? null : () => _chooseGroups(form),
          child: EditorRow(
            icon: Icons.group_outlined,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                names.isEmpty ? (_groups.isEmpty ? 'No groups in this account' : 'Groups') : names.join(', '),
                style: TextStyle(
                  fontSize: 18,
                  color: names.isEmpty ? OneUITheme.textSecondary : OneUITheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseGroups(ContactForm form) async {
    final selected = {...form.groupIds};
    final ok = await OneUIFloatingModal.show<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Groups', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final g in _groups)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(g.id),
                      title: Text(g.name),
                      activeColor: OneUITheme.accentBlue,
                      onChanged: (v) => setModal(() => v == true ? selected.add(g.id!) : selected.remove(g.id)),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ),
                Expanded(
                  child: TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Done')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok == true) setState(() => form.groupIds = selected);
  }
}
