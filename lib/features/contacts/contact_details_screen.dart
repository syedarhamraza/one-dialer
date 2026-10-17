import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_bottom_vignette.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/place_call.dart';
import '../blocking/blocking_repository.dart';
import 'contact_actions.dart';
import 'contact_subpages.dart';
import 'editor/contact_editor_screen.dart';
import 'editor/contact_form.dart' show labelDisplay, labelText;

/// Samsung-style contact page: hero card, numbers, details, messaging apps, History and
/// Storage locations, and a floating Favorites / Edit / Share / More bar.
class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _bridge = TelecomBridge.instance;
  final _shareKey = GlobalKey();
  final _moreKey = GlobalKey();
  Contact? _full; // every field, for details, Share and QR
  List<Map<Object?, Object?>> _apps = const [];
  List<SimCard> _sims = const [];
  String? _simId;

  @override
  void initState() {
    super.initState();
    ContactsRepository.instance.contacts.addListener(_loadFull);
    _load();
  }

  @override
  void dispose() {
    ContactsRepository.instance.contacts.removeListener(_loadFull);
    super.dispose();
  }

  Future<void> _load() async {
    final sims = await _bridge.getSims();
    final simId = await DialerPrefs.instance.contactSim(widget.contactId);
    final apps = await _bridge.getMessagingApps(widget.contactId);
    if (!mounted) return;
    setState(() {
      _sims = sims;
      _simId = simId;
      _apps = apps;
    });
    await _loadFull();
  }

  /// Reloads all fields (after editing, the repository notifies).
  Future<void> _loadFull() async {
    final full = await FlutterContacts.get(widget.contactId, properties: ContactProperties.all);
    if (mounted) setState(() => _full = full);
  }

  Future<void> _call(String number) => placeCall(context, number, simId: _simId);

  // --- Share / More --------------------------------------------------------------

  void _share(DialerContact contact) => OneUIFloatingMenu.show(
    context: context,
    anchorKey: _shareKey,
    width: 230,
    items: [
      OneUIFloatingMenuItem(
        label: 'vCard file (VCF)',
        onTap: () {
          if (_full != null) ContactActions.shareVCard(_full!);
        },
      ),
      OneUIFloatingMenuItem(label: 'Text', onTap: () => ContactActions.shareText(contact)),
    ],
  );

  void _more(DialerContact contact) {
    final blocking = BlockingRepository.instance;
    final blocked = contact.numbers.every(blocking.isBlocked);
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _moreKey,
      width: 270,
      items: [
        OneUIFloatingMenuItem(
          label: 'Delete',
          onTap: () async {
            if (await ContactActions.delete(context, contact.id, contact.name) && mounted) Navigator.of(context).pop();
          },
        ),
        OneUIFloatingMenuItem(
          label: 'QR code',
          onTap: () {
            if (_full != null) ContactActions.showQr(context, _full!);
          },
        ),
        OneUIFloatingMenuItem(
          label: blocked ? 'Unblock contact' : 'Block contact',
          onTap: () async {
            for (final n in contact.numbers) {
              await blocking.setBlocked(n, !blocked);
            }
          },
        ),
        OneUIFloatingMenuItem(label: 'SIM card for calls', onTap: _chooseSim),
        OneUIFloatingMenuItem(label: 'Change ringtone', onTap: () => ContactActions.changeRingtone(contact.id)),
      ],
    );
  }

  Future<void> _chooseSim() async {
    final picked = await OneUIFloatingModal.show<(String?,)>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Call this contact using', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final (id, label) in [(null, 'Ask every time'), for (final s in _sims) (s.id, s.label)])
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(ctx, (id,)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    OneUIRadio(isSelected: id == _simId),
                    const SizedBox(width: 20),
                    Text(label, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await DialerPrefs.instance.setContactSim(widget.contactId, picked.$1);
    if (mounted) setState(() => _simId = picked.$1);
  }

  // --- Build ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final repo = ContactsRepository.instance;
    return ValueListenableBuilder<List<DialerContact>>(
      valueListenable: repo.contacts,
      builder: (context, all, _) {
        final contact = all.where((c) => c.id == widget.contactId).firstOrNull;
        if (contact == null) {
          // Deleted, unlinked into another contact, or lost its numbers.
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Contact not found', style: TextStyle(color: OneUITheme.textSecondary)),
            ),
          );
        }
        return Scaffold(
          body: Stack(
            children: [
              ListView(
                physics: const OneUIScrollPhysics(),
                padding: EdgeInsets.fromLTRB(10, MediaQuery.paddingOf(context).top + 4, 10, 140),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Hero(contact: contact, onCall: _call, simLabel: _simLabel),
                  if (contact.numbers.length > 1 || contact.primaryIndex > 0) _numbersCard(contact),
                  if (_full case final full?) ..._detailCards(full),
                  if (_apps.isNotEmpty) _appsCard(),
                  const SizedBox(height: 8),
                  _PillButton(
                    label: 'History',
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => ContactHistoryScreen(contact: contact))),
                  ),
                  _PillButton(
                    label: 'Storage locations',
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => StorageLocationsScreen(contact: contact))),
                  ),
                ],
              ),
              // Same placement as OneSpend's detail screens: a bottom vignette, and the bar
              // centred at its own (content) width, with its own safe area and padding.
              const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: OneUIFloatingActionBar(
                    items: [
                      OneUIFloatingActionBarItem(
                        icon: contact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        label: 'Favorites',
                        color: contact.isFavorite ? const Color(0xFFF7A93B) : null,
                        onTap: () => repo.setFavorite(contact.id, !contact.isFavorite),
                      ),
                      OneUIFloatingActionBarItem(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: () => openContactEditor(context, contactId: contact.id),
                      ),
                      OneUIFloatingActionBarItem(
                        key: _shareKey,
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () => _share(contact),
                      ),
                      OneUIFloatingActionBarItem(
                        key: _moreKey,
                        icon: Icons.more_vert_rounded,
                        label: 'More',
                        onTap: () => _more(contact),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? get _simLabel => _sims.length < 2 ? null : _sims.where((s) => s.id == _simId).map((s) => s.label).firstOrNull;

  /// Every number with its own call and message buttons (Samsung lists the extra numbers here).
  Widget _numbersCard(DialerContact contact) {
    return _Card(
      children: [
        for (final (i, n) in contact.numbers.indexed)
          _ValueRow(
            label: contact.labels[i] + (i == contact.primaryIndex ? ' · Default' : ''),
            value: n,
            actions: [
              _RowAction(
                icon: Icons.call_rounded,
                color: OneUITheme.accentGreen,
                tooltip: 'Call',
                onTap: () => _call(n),
              ),
              _RowAction(
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF3E9BFF),
                tooltip: 'Message',
                onTap: () => _bridge.sendSms(n),
              ),
            ],
          ),
      ],
    );
  }

  /// Emails, addresses, dates, work, websites, relationships and notes, when present.
  List<Widget> _detailCards(Contact c) {
    final rows = <Widget>[
      for (final e in c.emails)
        _ValueRow(
          label: labelDisplay(labelText(e.label)),
          value: e.address,
          onTap: () => _bridge.openSystemSettings('url:mailto:${e.address}'),
        ),
      for (final a in c.addresses)
        _ValueRow(
          label: '${labelDisplay(labelText(a.label))} address',
          value: [
            a.street,
            a.city,
            a.state,
            a.postalCode,
            a.country,
          ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          onTap: () => _bridge.openSystemSettings(
            'url:geo:0,0?q=${Uri.encodeComponent([a.street, a.city, a.country].whereType<String>().join(' '))}',
          ),
        ),
      for (final d in c.events)
        _ValueRow(
          label: labelDisplay(labelText(d.label)),
          value: d.year == null
              ? DateFormat.MMMMd().format(DateTime(2000, d.month, d.day))
              : DateFormat.yMMMMd().format(DateTime(d.year!, d.month, d.day)),
        ),
      for (final o in c.organizations)
        if ([o.name, o.jobTitle, o.departmentName].any((s) => s?.isNotEmpty ?? false))
          _ValueRow(
            label: 'Work',
            value: [o.jobTitle, o.departmentName, o.name].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          ),
      for (final w in c.websites)
        _ValueRow(
          label: 'Website',
          value: w.url,
          onTap: () => _bridge.openSystemSettings('url:${w.url.contains('://') ? w.url : 'https://${w.url}'}'),
        ),
      for (final r in c.relations) _ValueRow(label: labelDisplay(labelText(r.label)), value: r.name),
      for (final n in c.notes)
        if (n.note.trim().isNotEmpty) _ValueRow(label: 'Notes', value: n.note.trim()),
    ];
    return rows.isEmpty ? const [] : [_Card(children: rows)];
  }

  Widget _appsCard() {
    return OneUIGroupCard(
      items: [
        for (final app in _apps)
          OneUIGroupItem(
            title: app['label']! as String,
            trailing: app['icon'] is Uint8List
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(app['icon']! as Uint8List, width: 28, height: 28),
                  )
                : const Icon(Icons.chat_rounded),
            onTap: () => _bridge.openContactData(app['dataId']! as int, app['mimeType']! as String),
          ),
      ],
    );
  }
}

/// Name, default number, photo and the Call / Message buttons.
class _Hero extends StatelessWidget {
  const _Hero({required this.contact, required this.onCall, required this.simLabel});

  final DialerContact contact;
  final Future<void> Function(String) onCall;
  final String? simLabel;

  @override
  Widget build(BuildContext context) {
    final i = contact.primaryIndex >= 0 ? contact.primaryIndex : 0;
    final number = contact.numbers[i];
    return _Card(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${contact.labels[i]} $number',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  if (simLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Calls with $simLabel',
                        style: const TextStyle(fontSize: 14, color: OneUITheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            LetterAvatar(name: contact.name, photo: contact.thumbnail, size: 52),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BigAction(
              icon: Icons.call_rounded,
              color: OneUITheme.accentGreen,
              label: 'Call',
              onTap: () => onCall(number),
            ),
            _BigAction(
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF3E9BFF),
              label: 'Message',
              onTap: () => TelecomBridge.instance.sendSms(number),
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.padding = const EdgeInsets.fromLTRB(18, 8, 12, 8)});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: padding,
      decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: OneUITheme.cardBorderRadius),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// "Mobile / 0336…" with optional buttons on the right; tappable when [onTap] is set.
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value, this.actions = const [], this.onTap});

  final String label;
  final String value;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 19)),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({required this.icon, required this.color, required this.tooltip, required this.onTap});

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({required this.icon, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(backgroundColor: OneUITheme.surfacePill),
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// Samsung's wide grey pill buttons (History, Storage locations).
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: OneUITheme.surfacePill,
            foregroundColor: OneUITheme.textPrimary,
            minimumSize: const Size(230, 52),
          ),
          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
