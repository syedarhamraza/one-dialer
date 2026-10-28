import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';

import '../contact_subpages.dart' show accountApp;
import '../../../core/contacts/contacts_repository.dart';
import '../../../core/telecom/telecom_bridge.dart';
import '../../../core/prefs/dialer_prefs.dart';
import '../../../theme/one_ui_scroll.dart';
import '../../../theme/one_ui_theme.dart';
import '../../../widgets/cos_dialog.dart';
import '../../../widgets/letter_avatar.dart';
import '../../../widgets/rise_route.dart';
import '../../../widgets/one_ui_toast.dart';
import '../../../widgets/call_glass.dart';
import '../../../widgets/one_ui_date_wheel.dart';
import '../../../widgets/one_ui_floating_menu.dart';
import '../../../widgets/one_ui_floating_modal.dart';
import '../../../widgets/press_glow.dart';
import 'contact_form.dart';
import 'editor_widgets.dart';

/// Opens the editor: a new contact (optionally with [number] and [name], as another app's
/// "add contact" sends) or [contactId] (optionally adding [number] to it). Returns the saved contact's id, or null if cancelled. With
/// [rise] slides it up from the bottom like the keypad sheet (the Contacts tab's +).
Future<String?> openContactEditor(
  BuildContext context, {
  String? contactId,
  String? number,
  String? name,
  bool rise = false,
}) {
  Widget page(BuildContext _) => ContactEditorScreen(contactId: contactId, initialNumber: number, initialName: name);
  return Navigator.of(context).push<String>(rise ? RisePageRoute(builder: page) : MaterialPageRoute(builder: page));
}

/// Google's built-in groups that aren't real user groups.
const hiddenGroupNames = {'My Contacts', 'Starred in Android'};

/// Samsung-style add/edit contact screen (replaces Android's contact editor).
class ContactEditorScreen extends StatefulWidget {
  const ContactEditorScreen({super.key, this.contactId, this.initialNumber, this.initialName});

  final String? contactId;
  final String? initialNumber;
  final String? initialName;

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

  /// The contact's ringtone URI, "" for the system one; saved with the contact.
  String _ringtone = '', _savedRingtone = '';

  /// The account copies of an existing contact, for "From the following account".
  List<Map<Object?, Object?>> _raw = const [];
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
  bool get _dirty => _form != null && (_form!.signature != _savedSignature || _ringtone != _savedRingtone);

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
    // A supplied number is a change; the blank row isn't (the signature skips it).
    _savedSignature = form.signature;
    // Another app's "add contact" may send several, one per line (a scanned QR card).
    for (final number in (widget.initialNumber ?? '').split('\n')) {
      if (number.trim().isNotEmpty) form.phones.add(LabeledValue(label: 'mobile', value: number.trim()));
    }
    final initialName = widget.initialName?.trim() ?? '';
    if (initialName.isNotEmpty && form.fullName.isEmpty) form.fullName = initialName;
    _keepBlankPhone(form);
    return form;
  }

  /// ColorOS keeps an empty number row at the end to type the next one into.
  static bool _keepBlankPhone(ContactForm form) {
    if (form.phones.isNotEmpty && form.phones.last.value.trim().isEmpty) return false;
    form.phones.add(LabeledValue(label: 'mobile'));
    return true;
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
      final (c, membership, groups, ringtone, raw) = await (
        FlutterContacts.get(widget.contactId!, properties: ContactProperties.all),
        FlutterContacts.groups.getOf(widget.contactId!),
        FlutterContacts.groups.getAll(),
        TelecomBridge.instance.getRingtone(widget.contactId!),
        TelecomBridge.instance.getRawContacts(widget.contactId!),
      ).wait;
      await _entered.future;
      if (!_active) return;
      if (c == null) {
        _close();
        return;
      }
      setState(() {
        _base = c;
        _ringtone = _savedRingtone = ringtone ?? '';
        _raw = raw;
        _initialGroups = {for (final g in membership) ?g.id};
        final form = _prepareForm(ContactForm.fromContact(c, groupIds: _initialGroups));
        _form = form;
        _groups = _userGroups(groups);
        _workOpen = form.company.isNotEmpty || form.jobTitle.isNotEmpty || form.department.isNotEmpty;
        _more =
            _workOpen ||
            form.dates.isNotEmpty ||
            form.websites.isNotEmpty ||
            form.relations.isNotEmpty ||
            form.notes.isNotEmpty;
        _loadReady.value = true;
      });
    } else {
      final (all, fallback) = await (
        TelecomBridge.instance.getContactAccounts(),
        FlutterContacts.accounts.getDefault(),
      ).wait;
      if (!_active) return;
      // Android 16 refuses phone and SIM saves while the default contacts account is a cloud
      // one ("Cannot add contacts to local or SIM accounts when default account is set to
      // cloud"), so only offer them when it isn't.
      final cloudDefault = fallback != null && fallback.type == 'com.google';
      final accounts = [
        for (final a in all)
          if (!cloudDefault || a['type'] == 'com.google')
            Account(id: '', name: (a['name'] as String?) ?? '', type: (a['type'] as String?) ?? ''),
      ];
      // Manage contacts › Default save location first, when this phone still offers it.
      final saved = DialerPrefs.instance.saveAccount.value;
      final account =
          accounts.where((a) => '${a.type}|${a.name}' == saved).firstOrNull ??
          accounts.where((a) => a.type == fallback?.type && a.name == fallback?.name).firstOrNull ??
          accounts.where((a) => a.type == 'com.google').firstOrNull ??
          accounts.firstOrNull;
      final groups = await _accountGroups(account);
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
    // can slide out immediately without resizing its form.
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
    if (form.isEmpty || _saving || _confirming || !_ready || !_active) return;
    // Only waits when there's a duplicate to ask about, so a double tap can't save twice.
    final duplicate = _base == null ? _duplicateOf(form) : null;
    if (duplicate != null && !await _confirmDuplicate(duplicate)) return;
    setState(() => _saving = true);
    try {
      final String id;
      if (_base == null && _isDevice(_account)) {
        // The contacts package can't create a no-account contact (it falls back to the default
        // account), so make an empty one natively and fill it in.
        id = await TelecomBridge.instance.createLocalContact();
        try {
          await FlutterContacts.update(form.applyTo(Contact(id: id)));
        } catch (_) {
          await FlutterContacts.delete(id);
          rethrow;
        }
      } else if (_base == null) {
        id = await FlutterContacts.create(form.applyTo(const Contact()), account: _account);
      } else {
        await FlutterContacts.update(form.applyTo(_base!));
        id = _base!.id!;
      }
      if (_ringtone != _savedRingtone) {
        await TelecomBridge.instance.setRingtone(id, _ringtone.isEmpty ? null : _ringtone);
      }
      for (final g in form.groupIds.difference(_initialGroups)) {
        await FlutterContacts.groups.addContacts(groupId: g, contactIds: [id]);
      }
      for (final g in _initialGroups.difference(form.groupIds)) {
        await FlutterContacts.groups.removeContacts(groupId: g, contactIds: [id]);
      }
      if (_active) _close(id);
    } on PlatformException catch (e) {
      debugPrint('Saving the contact failed: ${e.code} ${e.message}');
      if (!mounted || _closing) return;
      setState(() => _saving = false);
      OneUIToast.show(
        context,
        e.code == 'read_only_contact'
            ? "This contact's account is read-only, so it can't be changed here"
            : "Couldn't save the contact",
        long: true,
      );
    }
  }

  static String _avatarName(ContactForm form) =>
      form.fullName.isEmpty ? (form.phones.firstOrNull?.value ?? '') : form.fullName;

  (bool, String)? _shown;

  /// Text edits only rebuild the screen when something drawn from the text changes:
  /// the Done pill (empty or not) and the photo's initials.
  void _edited() {
    final form = _form!;
    final shown = (form.isEmpty, LetterAvatar.initials(_avatarName(form)));
    if (shown != _shown) setState(() => _shown = shown);
  }

  /// For a new contact, the saved contact that already has one of its numbers or its name
  /// (typed, or from a QR code or another app), as the line that says so.
  String? _duplicateOf(ContactForm form) {
    final repo = ContactsRepository.instance;
    final byNumber = [
      for (final p in form.phones)
        if (repo.contactFor(p.value) case final c?) (c, p.value.trim()),
    ].firstOrNull;
    final name = [form.first, form.middle, form.last].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');
    final byName = name.isEmpty
        ? null
        : repo.allContacts.value.where((c) => c.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    final existing = byNumber?.$1 ?? byName;
    if (existing == null) return null;
    return byNumber != null
        ? '${byNumber.$2} is already saved as ${existing.name}.'
        : '${existing.name} is already in your contacts.';
  }

  /// Says who already has it before making a second copy. True to save anyway.
  Future<bool> _confirmDuplicate(String duplicate) async {
    _confirming = true;
    final choice = await showCosActions<bool>(
      context,
      title: 'Already in contacts',
      message: '$duplicate Save another contact anyway?',
      actions: [
        (label: 'Save anyway', value: true, destructive: false),
        (label: 'Cancel', value: false, destructive: false),
      ],
    );
    _confirming = false;
    return choice == true && _active;
  }

  /// "Save your changes or discard them?" on back with unsaved changes.
  Future<void> _confirmLeave() async {
    _confirming = true;
    final choice = await showCosActions<String?>(
      context,
      message: 'Save your changes or discard them?',
      actions: [
        // Saving needs the form loaded; until then only Discard and Cancel make sense.
        if (_loadReady.value) (label: 'Save', value: 'save', destructive: false),
        (label: 'Discard', value: 'discard', destructive: true),
        (label: 'Cancel', value: null, destructive: false),
      ],
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
        body: Column(
          children: [
            _header(canSave: form != null && _ready && !form.isEmpty && !_saving && !_closing),
            Expanded(
              child: form == null
                  ? Center(
                      child: _loadFailed
                          ? TextButton(onPressed: _retryLoad, child: const Text("Couldn't load the contact. Retry"))
                          : const CircularProgressIndicator(),
                    )
                  : ListView(
                      physics: const OneUIScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 24),
                      children: [
                        _photo(form),
                        if (_isNew) _accountRow(),
                        const SizedBox(height: 24),
                        ..._mainCards(form),
                        _ringtoneCard(),
                        _groupsCard(form),
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
                          _workCard(form),
                          _datesCard(form),
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
                            iconAlignment: IconAlignment.end,
                            icon: Icon(_more ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                            label: Text(_more ? 'Show less' : 'Show more', style: const TextStyle(fontSize: 17)),
                            style: TextButton.styleFrom(foregroundColor: context.palette.textPrimary),
                          ),
                        ),
                        if (!_isNew && _raw.isNotEmpty) ..._accountsCard(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
    // Only while leaving: depending on the whole MediaQuery would rebuild the form on every
    // frame of a keyboard animation.
    final exit = _exitMediaQuery;
    return exit == null ? screen : MediaQuery(data: exit, child: screen);
  }

  // --- Header --------------------------------------------------------------

  /// ColorOS's top bar: Cancel | title | Done, as call-glass pills tinted red and green
  /// (a wash through the glass, white text); a disabled Done is plain glass.
  Widget _header({required bool canSave}) {
    Widget pill(String label, VoidCallback? onPressed, Color tint) => CallGlass(
      radius: 24,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: onPressed == null ? null : tint.withValues(alpha: .28),
          shape: const StadiumBorder(),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: context.palette.textPrimary,
            disabledForegroundColor: context.palette.textTertiary,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const StadiumBorder(),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 8),
      child: SizedBox(
        height: 48,
        child: NavigationToolbar(
          leading: pill('Cancel', () => Navigator.of(context).maybePop(), OneUITheme.accentRed),
          middle: Text(
            _isNew ? 'New contact' : 'Edit contact',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: context.palette.textPrimary),
          ),
          trailing: pill('Done', canSave ? _save : null, OneUITheme.accentGreen),
          middleSpacing: 12,
        ),
      ),
    );
  }

  // --- Account ---------------------------------------------------------------

  final _accountKey = GlobalKey();

  /// ColorOS's centred "Save to (account) ▾".
  Widget _accountRow() {
    final account = _account;
    return Center(
      child: InkWell(
        key: _accountKey,
        borderRadius: OneUITheme.pillBorderRadius,
        onTap: _loadFailed
            ? _retryLoad
            : _ready
            ? _chooseAccount
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  !_ready
                      ? (_loadFailed ? "Couldn't load accounts" : 'Loading accounts…')
                      : 'Save to ${account == null ? 'This device' : _accountName(account)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: context.palette.textSecondary),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: context.palette.textSecondary),
            ],
          ),
        ),
      ),
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
            // Radio marks on every row keep the names lined up; menu rows are one line, so a
            // Google account is named by its email.
            icon: a.type == _account?.type && a.name == _account?.name
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            label: _accountName(a),
            onTap: () => picked = a,
          ),
      ],
    );
    final account = picked;
    if (account == null || !_active) return;
    final groups = await _accountGroups(account);
    if (!_active) return;
    setState(() {
      _account = account;
      _groups = groups;
      _form!.groupIds = {}; // groups belong to an account
    });
  }

  /// Only Google accounts have contact groups; the phone and SIMs don't.
  Future<List<Group>> _accountGroups(Account? account) async =>
      account?.type == 'com.google' ? _userGroups(await FlutterContacts.groups.getAll(accounts: [account!])) : const [];

  /// The phone's own storage: the NULL account, or an OEM's local account type.
  static bool _isDevice(Account? a) =>
      a != null && (a.type.isEmpty || a.type.toLowerCase().contains('local') || a.type.toLowerCase().contains('phone'));

  /// "This device", "SIM card", or the Google account's email.
  String _accountName(Account a) {
    if (_isDevice(a)) return 'This device';
    if (a.type.toLowerCase().contains('sim')) {
      // Dual SIM: tell the cards apart by their account name.
      final sims = _accounts.where((x) => x.type.toLowerCase().contains('sim')).length;
      return sims > 1 ? 'SIM card (${a.name})' : 'SIM card';
    }
    return a.name;
  }

  // --- Photo -----------------------------------------------------------------

  Widget _photo(ContactForm form) {
    final existing = form.photoRemoved ? null : (_base?.photo?.fullSize ?? _base?.photo?.thumbnail);
    final photo = form.newPhoto ?? existing;
    return Column(
      children: [
        LetterAvatar(name: _avatarName(form), photo: photo, size: 120),
        const SizedBox(height: 14),
        PressGlow(
          child: FilledButton(
            onPressed: () => _photoMenu(hasPhoto: photo != null),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.pill,
              foregroundColor: context.palette.textPrimary,
              minimumSize: const Size(88, 40),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            child: const Text('Change', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  /// ColorOS's "Profile picture" sheet: Camera | Select photos, and Delete when there's one.
  Future<void> _photoMenu({required bool hasPhoto}) async {
    final choice = await OneUIFloatingModal.show<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(foregroundColor: OneUITheme.textPrimary),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const Text('Profile picture', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (icon, label, value) in [
                (Icons.photo_camera_outlined, 'Camera', 'camera'),
                (Icons.photo_library_outlined, 'Select photos', 'gallery'),
              ]) ...[
                if (value == 'gallery') const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: context.palette.cardHighlight,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(ctx, value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          children: [
                            Icon(icon, size: 26),
                            const SizedBox(height: 8),
                            Text(label, style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasPhoto) ...[
            const SizedBox(height: 12),
            Material(
              color: context.palette.cardHighlight,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(ctx, 'delete'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Text('Delete profile picture', style: TextStyle(fontSize: 16, color: OneUITheme.accentRed)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (choice == null || !_active) return;
    if (choice == 'delete') {
      setState(
        () => _form!
          ..newPhoto = null
          ..photoRemoved = true,
      );
      return;
    }
    final Uint8List? bytes;
    try {
      bytes = choice == 'camera' ? await TelecomBridge.instance.takePhoto() : await TelecomBridge.instance.pickPhoto();
    } on PlatformException {
      if (mounted) OneUIToast.show(context, "Couldn't open the camera");
      return;
    }
    if (bytes != null && _active) {
      setState(
        () => _form!
          ..newPhoto = bytes
          ..photoRemoved = false,
      );
    }
  }

  // --- Ringtone, accounts ------------------------------------------------------

  /// "Follow system", or the contact's own tone; saved with the contact.
  Widget _ringtoneCard() {
    return EditorCard(
      children: [
        InkWell(
          borderRadius: OneUITheme.cardBorderRadius,
          onTap: () async {
            final picked = await TelecomBridge.instance.pickRingtone(_ringtone.isEmpty ? null : _ringtone);
            if (picked != null && _active) setState(() => _ringtone = picked);
          },
          child: EditorRow(
            icon: Icons.notifications_none_rounded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _ringtone.isEmpty ? 'Follow system' : 'Custom ringtone',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ColorOS's "From the following account": where this contact is saved.
  List<Widget> _accountsCard() {
    final byAccount = <(String, String?), int>{};
    for (final r in _raw) {
      final key = (accountApp(r['accountType'] as String?), r['accountName'] as String?);
      byAccount[key] = (byAccount[key] ?? 0) + 1;
    }
    return [
      const SizedBox(height: 16),
      Padding(
        padding: EdgeInsets.only(left: 18, bottom: 8),
        child: Text('From the following account', style: TextStyle(fontSize: 14, color: context.palette.textSecondary)),
      ),
      EditorCard(
        children: [
          for (final MapEntry(key: (app, name), value: count) in byAccount.entries)
            EditorRow(
              icon: Icons.account_box_outlined,
              trailing: const SizedBox.shrink(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          if (name != null && name.isNotEmpty)
                            Text(name, style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      count == 1 ? '1 contact' : '$count contacts',
                      style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ];
  }

  // --- Name, phones, work ----------------------------------------------------

  List<Widget> _mainCards(ContactForm form) {
    return [
      EditorCard(
        children: [
          EditorRow(
            icon: Icons.person_outline_rounded,
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
                          divider: hint != 'Name suffix',
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
        ],
      ),
      EditorCard(
        children: [
          for (final (i, phone) in form.phones.indexed)
            EditorRow(
              key: ObjectKey(phone),
              icon: i == 0 ? Icons.call_outlined : null,
              trailing: phone.value.trim().isEmpty && i == form.phones.length - 1
                  ? null
                  : RemoveButton(onPressed: () => setState(() => form.phones.remove(phone))),
              child: InlineLabeledField(
                label: LabelButton(
                  label: phone.label,
                  options: EditorLabels.phone,
                  onChanged: (l) => setState(() => phone.label = l),
                ),
                field: EditorField(
                  hint: 'Number',
                  value: phone.value,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) {
                    phone.value = v;
                    // Typing in the blank row adds the next one (and its remove button).
                    if (v.trim().isNotEmpty && i == form.phones.length - 1 && _keepBlankPhone(form)) {
                      setState(() {});
                    }
                    _edited();
                  },
                ),
              ),
            ),
        ],
      ),
    ];
  }

  Widget _workCard(ContactForm form) {
    return EditorCard(
      children: [
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
                  divider: true,
                  hint: 'Company',
                  value: form.company,
                  onChanged: (v) {
                    form.company = v;
                    _edited();
                  },
                ),
                EditorField(
                  divider: true,
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
            child: InlineLabeledField(
              label: LabelButton(label: row.label, options: options, onChanged: (l) => setState(() => row.label = l)),
              field: EditorField(
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
                  color: names.isEmpty ? context.palette.textSecondary : context.palette.textPrimary,
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
                physics: const HoldStillScrollPhysics(), // a popup list holds still
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
