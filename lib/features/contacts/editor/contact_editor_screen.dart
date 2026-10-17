import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/layout.dart';

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
  bool _closing = false, _confirming = false, _loadFailed = false;
  final _loadReady = ValueNotifier(false);
  bool get _ready => _loadReady.value;
  final _nameFocus = FocusNode();
  final _entered = Completer<void>();
  Animation<double>? _routeAnimation;
  MediaQueryData? _exitMediaQuery;

  bool get _active => mounted && !_closing;

  bool get _isNew => widget.contactId == null;

  static List<Group> _userGroups(List<Group> all) => [
    for (final g in all)
      if (!hiddenGroupNames.contains(g.name)) g,
  ];
  bool get _dirty => _form != null && _form!.signature != _savedSignature;

  @override
  void initState() {
    super.initState();
    if (_isNew) _form = _prepareForm(ContactForm());
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_routeStatusChanged);
      _routeAnimation = animation;
      animation?.addStatusListener(_routeStatusChanged);
    }
    // Flutter initially exposes an always-complete proxy before wiring the
    // route's actual animation. Check it after that first frame, not during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_active && (_routeAnimation == null || _routeAnimation!.isCompleted)) {
        _routeStatusChanged(AnimationStatus.completed);
      }
    });
  }

  void _routeStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_entered.isCompleted) {
      _entered.complete();
    }
  }

  @override
  void dispose() {
    _closing = true;
    _routeAnimation?.removeStatusListener(_routeStatusChanged);
    if (!_entered.isCompleted) _entered.complete();
    _nameFocus.dispose();
    _loadReady.dispose();
    super.dispose();
  }

  ContactForm _prepareForm(ContactForm form) {
    final initialNumber = widget.initialNumber?.trim() ?? '';
    // A blank phone row is not a change; a supplied number is.
    if (form.phones.isEmpty && initialNumber.isEmpty) {
      form.phones.add(LabeledValue(label: 'mobile'));
    }
    _savedSignature = form.signature;
    if (initialNumber.isNotEmpty) {
      form.phones.add(LabeledValue(label: 'mobile', value: initialNumber));
    }
    return form;
  }

  Future<void> _load() async {
    try {
      await _loadData();
    } catch (_) {
      // Record waits wrap platform failures in ParallelWaitError.
      if (_active) setState(() => _loadFailed = true);
    }
  }

  void _retryLoad() {
    setState(() => _loadFailed = false);
    _load();
  }

  Future<void> _loadData() async {
    if (!_isNew) {
      final (c, membership, groups) = await (
        FlutterContacts.get(widget.contactId!, properties: ContactProperties.all),
        FlutterContacts.groups.getOf(widget.contactId!),
        FlutterContacts.groups.getAll(),
      ).wait;
      await _entered.future;
      if (!_active) return;
      if (c == null) {
        _close();
        return;
      }
      setState(() {
        _base = c;
        _initialGroups = {for (final g in membership) ?g.id};
        final form = _prepareForm(ContactForm.fromContact(c, groupIds: _initialGroups));
        _form = form;
        _groups = _userGroups(groups);
        _workOpen = form.company.isNotEmpty || form.jobTitle.isNotEmpty || form.department.isNotEmpty;
        _more = form.dates.isNotEmpty || form.websites.isNotEmpty || form.relations.isNotEmpty || form.notes.isNotEmpty;
        _loadReady.value = true;
      });
    } else {
      final (all, fallback) = await (FlutterContacts.accounts.getAll(), FlutterContacts.accounts.getDefault()).wait;
      if (!_active) return;
      final accounts = _contactAccounts(all);
      final account =
          accounts.where((a) => a.type == fallback?.type && a.name == fallback?.name).firstOrNull ??
          accounts.where((a) => a.type == 'com.google').firstOrNull ??
          accounts.firstOrNull;
      final groups = await FlutterContacts.groups.getAll(accounts: account == null ? null : [account]);
      await _entered.future;
      if (!_active) return;
      setState(() {
        _accounts = accounts;
        _account = account;
        _groups = _userGroups(groups);
        _loadReady.value = true;
      });
      if (widget.initialNumber == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_active &&
              !_nameExpanded &&
              ModalRoute.of(context)?.isCurrent == true &&
              FocusScope.of(context).focusedChild == null) {
            _nameFocus.requestFocus();
          }
        });
      }
    }
  }

  void _close([String? result]) {
    if (!_active) return;
    // Freeze the outgoing layout while Android dismisses the keyboard. The route
    // can slide out immediately without resizing its form and floating pill.
    setState(() {
      _exitMediaQuery = MediaQuery.of(context);
      _closing = true;
    });
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  void _requestLeave() {
    if (!_active || _saving || _confirming) return;
    _dirty ? _confirmLeave() : _close();
  }

  Future<void> _save() async {
    final form = _form!;
    if (form.isEmpty || _saving || !_ready || !_active) return;
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
      if (_active) _close(id);
    } on PlatformException catch (e) {
      if (!mounted || _closing) return;
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

  static String _avatarName(ContactForm form) =>
      form.fullName.isEmpty ? (form.phones.firstOrNull?.value ?? '') : form.fullName;

  (bool, String)? _shown;

  /// Text edits only rebuild the screen when something drawn from the text changes:
  /// the Save pill (empty or not) and the photo's initials.
  void _edited() {
    final form = _form!;
    final shown = (form.isEmpty, LetterAvatar.initials(_avatarName(form)));
    if (shown != _shown) setState(() => _shown = shown);
  }

  /// "Save your changes or discard them?" on back with unsaved changes.
  Future<void> _confirmLeave() async {
    _confirming = true;
    final choice = await OneUIFloatingModal.show<String>(
      context: context,
      builder: (ctx) => ValueListenableBuilder(
        valueListenable: _loadReady,
        builder: (ctx, ready, _) => Column(
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
                      onPressed: value == 'save' && !ready ? null : () => Navigator.pop(ctx, value),
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
      ),
    );
    _confirming = false;
    if (!_active) return;
    if (choice == 'discard') _close();
    if (choice == 'save') await _save();
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    final screen = PopScope(
      // Decided at back-press time, so typing doesn't have to rebuild to keep it current.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _closing = true;
          return;
        }
        _requestLeave();
      },
      child: Scaffold(
        body: form == null
            ? Center(
                child: _loadFailed
                    ? TextButton(onPressed: _retryLoad, child: const Text("Couldn't load the contact. Retry"))
                    : const CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  ListView(
                    physics: const OneUIScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 140),
                    children: [
                      if (_isNew) _accountRow(),
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
                                onChanged: (v) {
                                  form.notes = v;
                                  _edited();
                                },
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
                        // Same baseline as every bottom floating bar.
                        padding: const EdgeInsets.only(bottom: kNavBarVerticalPadding),
                        child: OneUIFloatingCancelSavePill(
                          onCancel: () => Navigator.of(context).maybePop(),
                          onSave: _save,
                          canSave: _ready && !form.isEmpty && !_saving && !_closing,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
    return MediaQuery(data: _exitMediaQuery ?? MediaQuery.of(context), child: screen);
  }

  // --- Account ---------------------------------------------------------------

  final _accountKey = GlobalKey();

  Widget _accountRow() {
    final account = _account;
    return InkWell(
      key: _accountKey,
      borderRadius: OneUITheme.pillBorderRadius,
      onTap: _loadFailed
          ? _retryLoad
          : _ready
          ? _chooseAccount
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _accountIcon(account),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                !_ready
                    ? (_loadFailed ? "Couldn't load accounts" : 'Loading accounts…')
                    : account == null || account.type.contains('phone')
                    ? 'Phone'
                    : account.name,
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

  /// Samsung's anchored "Save contact to" popup.
  Future<void> _chooseAccount() async {
    Account? picked;
    await OneUIFloatingMenu.show(
      context: context,
      anchorKey: _accountKey,
      width: 300,
      items: [
        for (final a in _accounts)
          OneUIFloatingMenuItem(
            icon: a.type == _account?.type && a.name == _account?.name ? Icons.check_circle_rounded : null,
            label: a.type.contains('phone') ? 'Phone' : '${_accountTypeName(a)}\n${a.name}',
            onTap: () => picked = a,
          ),
      ],
    );
    final account = picked;
    if (account == null || !_active) return;
    final groups = _userGroups(await FlutterContacts.groups.getAll(accounts: [account]));
    if (!_active) return;
    setState(() {
      _account = account;
      _groups = groups;
      _form!.groupIds = {}; // groups belong to an account
    });
  }

  /// Samsung's "Save contact to" choices: Samsung account, Phone and Google accounts,
  /// not every app that syncs contacts (WhatsApp, Meet, a second Samsung service, ...).
  static List<Account> _contactAccounts(List<Account> all) {
    final seen = <String>{};
    final keep = [
      for (final a in all)
        if ((a.type == 'com.google' ||
                a.type == 'com.osp.app.signin' ||
                a.type.contains('phone') ||
                a.type.contains('local')) &&
            seen.add('${a.type}|${a.name}'))
          a,
    ];
    // shortcut: flutter_contacts doesn't report the two accounts Samsung Contacts saves to
    // (Samsung account `com.osp.app.signin` and the on-device `vnd.sec.contact.phone`), only
    // Samsung's other services (`com.samsung.*`). On Samsung phones add those two, in Samsung's
    // order; other phones keep their own list.
    final samsung = all.where((a) => a.type.startsWith('com.samsung') || a.type == 'com.osp.app.signin').firstOrNull;
    if (samsung != null) {
      final extra = [
        Account(id: '', name: samsung.name, type: 'com.osp.app.signin'),
        const Account(id: '', name: 'vnd.sec.contact.phone', type: 'vnd.sec.contact.phone'),
      ];
      keep.removeWhere((a) => a.type == 'com.osp.app.signin');
      keep.insertAll(0, extra);
    }
    return keep;
  }

  static String _accountTypeName(Account a) => switch (a.type) {
    final t when t.contains('google') => 'Google',
    'com.osp.app.signin' => 'Samsung account',
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
        LetterAvatar(name: _avatarName(form), photo: photo, size: 98),
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
      if (bytes != null && _active) {
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
                        onChanged: (v) {
                          set(v);
                          _edited();
                        },
                      ),
                  ],
                )
              : EditorField(
                  key: const ValueKey('name-full'),
                  hint: 'Name',
                  value: form.fullName,
                  focusNode: _nameFocus,
                  capitalization: TextCapitalization.words,
                  onChanged: (v) {
                    form.fullName = v;
                    _edited();
                  },
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
                  onChanged: (v) {
                    phone.value = v;
                    _edited();
                  },
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
                EditorField(
                  hint: 'Company',
                  value: form.company,
                  onChanged: (v) {
                    form.company = v;
                    _edited();
                  },
                ),
                EditorField(
                  hint: 'Job title',
                  value: form.jobTitle,
                  onChanged: (v) {
                    form.jobTitle = v;
                    _edited();
                  },
                ),
                EditorField(
                  hint: 'Department',
                  value: form.department,
                  onChanged: (v) {
                    form.department = v;
                    _edited();
                  },
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
                  onChanged: (v) {
                    row.value = v;
                    _edited();
                  },
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
                  onChanged: (v) {
                    a.street = v;
                    _edited();
                  },
                ),
                EditorField(
                  hint: 'City',
                  value: a.city,
                  onChanged: (v) {
                    a.city = v;
                    _edited();
                  },
                ),
                EditorField(
                  hint: 'State/Province',
                  value: a.region,
                  onChanged: (v) {
                    a.region = v;
                    _edited();
                  },
                ),
                EditorField(
                  hint: 'Postal code',
                  value: a.postcode,
                  keyboardType: TextInputType.streetAddress,
                  onChanged: (v) {
                    a.postcode = v;
                    _edited();
                  },
                ),
                EditorField(
                  hint: 'Country',
                  value: a.country,
                  onChanged: (v) {
                    a.country = v;
                    _edited();
                  },
                ),
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
      if (ok != true || !_active) return;
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
    if (ok == true && _active) setState(() => form.groupIds = selected);
  }
}
