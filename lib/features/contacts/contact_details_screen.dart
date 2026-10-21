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
import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/place_call.dart';
import '../../widgets/press_glow.dart';
import '../../widgets/round_header_controls.dart';
import '../blocking/blocking_repository.dart';
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
import '../recents/recents_screen.dart' show CallTypeIcon, SimBadge, callTypeLabel;
import 'contact_actions.dart';
import 'contact_subpages.dart';
import 'editor/contact_editor_screen.dart';
import 'editor/contact_form.dart' show labelDisplay, labelText;

/// ColorOS-style contact page in the Calls look: round glass Back / Favourite / Edit / More
/// buttons over a big avatar and name, Call and Message tiles, the numbers and ringtone,
/// details, messaging apps and the latest calls.
class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _bridge = TelecomBridge.instance;
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
    anchorKey: _moreKey,
    width: 230,
    items: [
      OneUIFloatingMenuItem(
        label: 'vCard file (VCF)',
        onTap: () {
          if (_full != null) ContactActions.shareVCard(_full!);
        },
      ),
      OneUIFloatingMenuItem(label: 'Text', onTap: () => ContactActions.shareText(contact)),
      OneUIFloatingMenuItem(
        label: 'QR code',
        onTap: () {
          if (_full != null) ContactActions.showQr(context, _full!);
        },
      ),
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
        OneUIFloatingMenuItem(label: 'Share', onTap: () => _share(contact)),
        OneUIFloatingMenuItem(
          label: 'Storage locations',
          onTap: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => StorageLocationsScreen(contact: contact))),
        ),
        OneUIFloatingMenuItem(label: 'SIM card for calls', onTap: _chooseSim),
        OneUIFloatingMenuItem(
          label: blocked ? 'Unblock contact' : 'Block contact',
          onTap: () async {
            for (final n in contact.numbers) {
              await blocking.setBlocked(n, !blocked);
            }
          },
        ),
        OneUIFloatingMenuItem(
          label: 'Delete',
          onTap: () async {
            if (await ContactActions.delete(context, contact.id, contact.name) && mounted) Navigator.of(context).pop();
          },
        ),
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

  static const double _button = 48;

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
        final padding = MediaQuery.paddingOf(context);
        final primary = contact.numbers[contact.primaryIndex >= 0 ? contact.primaryIndex : 0];
        return Scaffold(
          body: Stack(
            children: [
              ListView(
                physics: const OneUIScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, padding.top + 8 + _button + 16, 16, padding.bottom + 32),
                children: [
                  Center(
                    child: LetterAvatar(
                      name: contact.name,
                      // Full resolution once loaded; the thumbnail is soft at this size.
                      photo: _full?.photo?.fullSize ?? contact.thumbnail,
                      size: 112,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contact.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: DetailsActionTile(
                          icon: Icons.call_rounded,
                          color: OneUITheme.accentGreen,
                          label: 'Call',
                          onTap: () => _call(primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DetailsActionTile(
                          icon: Icons.chat_bubble_rounded,
                          color: const Color(0xFF3E9BFF),
                          label: 'Message',
                          onTap: () => _bridge.sendSms(primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _numbersCard(contact),
                  if (_full case final full?) ..._detailCards(full),
                  if (_apps.isNotEmpty) _appsCard(),
                  _callLogs(contact),
                ],
              ),
              const Positioned(left: 0, right: 0, top: 0, child: OneUIStatusBarScrim()),
              Positioned(
                left: 16,
                right: 16,
                top: padding.top + 8,
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    // RoundIconButton with an orange star when it's a favourite.
                    CallGlass(
                      child: IconButton(
                        tooltip: contact.isFavorite ? 'Remove from favourites' : 'Add to favourites',
                        onPressed: () => repo.setFavorite(contact.id, !contact.isFavorite),
                        style: IconButton.styleFrom(
                          foregroundColor: contact.isFavorite ? const Color(0xFFF7A93B) : OneUITheme.textPrimary,
                          fixedSize: const Size.square(_button),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(contact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, size: 24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onTap: () => openContactEditor(context, contactId: contact.id),
                    ),
                    const SizedBox(width: 8),
                    // The menu measures this wrapper, outside the glass press, like Calls' menu.
                    KeyedSubtree(
                      key: _moreKey,
                      child: RoundIconButton(
                        icon: Icons.more_vert_rounded,
                        tooltip: 'More options',
                        onTap: () => _more(contact),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? get _simLabel => _sims.length < 2 ? null : _sims.where((s) => s.id == _simId).map((s) => s.label).firstOrNull;

  /// "1"/"2" badge, only on dual-SIM phones (as in Calls).
  (String, Color)? _simBadge(String? simId) {
    if (_sims.length < 2 || simId == null) return null;
    final i = _sims.indexWhere((s) => s.id == simId);
    return i < 0 ? null : ('${i + 1}', _sims[i].color);
  }

  /// Every number (tap to call, message on the right), then the contact's ringtone.
  Widget _numbersCard(DialerContact contact) {
    final simLabel = _simLabel;
    return DetailsCard(
      children: [
        for (final (i, n) in contact.numbers.indexed)
          _ValueRow(
            icon: i == 0 ? Icons.call_outlined : null,
            label: [
              contact.labels[i],
              if (contact.numbers.length > 1 && i == contact.primaryIndex) 'Default',
              ?simLabel,
            ].join(' · '),
            value: n,
            onTap: () => _call(n),
            action: IconButton(
              tooltip: 'Message',
              onPressed: () => _bridge.sendSms(n),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 24),
            ),
          ),
        _ValueRow(
          icon: Icons.notifications_none_rounded,
          value: 'Ringtone',
          onTap: () => ContactActions.changeRingtone(contact.id),
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
    return rows.isEmpty ? const [] : [DetailsCard(children: rows)];
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

  /// The latest calls with this contact's numbers, hidden until there are any.
  Widget _callLogs(DialerContact contact) {
    final repo = CallLogRepository.instance;
    final keys = {for (final n in contact.numbers) numberKey(n)};
    return ListenableBuilder(
      listenable: repo.calls,
      builder: (context, _) {
        final calls = repo.calls.value.where((c) => keys.contains(numberKey(c.number))).take(3).toList();
        if (calls.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Call logs', style: TextStyle(fontSize: 15, color: OneUITheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => ContactHistoryScreen(contact: contact))),
                    child: const Text(
                      'View all',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.accentGreen),
                    ),
                  ),
                ],
              ),
            ),
            DetailsCard(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              children: [
                for (final c in calls)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 40, child: CallTypeIcon(type: c.type, muted: true)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dayLabel(c.date, now)}, ${timeLabel(c.date)}',
                                style: const TextStyle(fontSize: 17),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (_simBadge(c.simId) case final badge?) ...[
                                    SimBadge(badge: badge),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      c.number,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          c.type != CallType.missed && c.duration > Duration.zero
                              ? durationLabel(c.duration)
                              : callTypeLabel(c.type),
                          style: TextStyle(
                            fontSize: 13,
                            color: c.type == CallType.missed ? OneUITheme.accentRed : OneUITheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Call / Message tile: icon over label on a flat card (no glass: it scrolls). Shared with
/// the unsaved-number page (CallDetailsScreen).
class DetailsActionTile extends StatelessWidget {
  const DetailsActionTile({super.key, required this.icon, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressGlow(
      radius: OneUITheme.radiusCard,
      child: Material(
        color: OneUITheme.surfaceCard,
        borderRadius: OneUITheme.cardBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: OneUITheme.cardBorderRadius,
          // Full width: the glass press hands its child loose constraints.
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DetailsCard extends StatelessWidget {
  const DetailsCard({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(18, 8, 12, 8)});

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

/// A value with its label; tappable when [onTap] is set. Detail rows put the label above
/// the value, number rows (with an [icon] column or an [action]) put it below.
class _ValueRow extends StatelessWidget {
  const _ValueRow({this.icon, this.label = '', required this.value, this.action, this.onTap});

  final IconData? icon;
  final String label;
  final String value;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final caption = label.isEmpty
        ? null
        : Text(label, style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary));
    final numberRow = icon != null || action != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (numberRow) SizedBox(width: 40, child: icon == null ? null : Icon(icon, size: 24)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!numberRow && caption != null) ...[caption, const SizedBox(height: 2)],
                  Text(value, style: const TextStyle(fontSize: 19)),
                  if (numberRow && caption != null) ...[const SizedBox(height: 2), caption],
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
