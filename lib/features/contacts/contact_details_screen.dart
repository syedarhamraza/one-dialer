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
  String _storage = '';

  @override
  void initState() {
    super.initState();
    ContactsRepository.instance.revision.addListener(_loadFull);
    _load();
  }

  @override
  void dispose() {
    ContactsRepository.instance.revision.removeListener(_loadFull);
    super.dispose();
  }

  Future<void> _load() async {
    // Together, so the page rebuilds once, early in its slide-in.
    final (sims, simId, apps, raw) = await (
      _bridge.getSims(),
      DialerPrefs.instance.contactSim(widget.contactId),
      _bridge.getMessagingApps(widget.contactId),
      _bridge.getRawContacts(widget.contactId),
    ).wait;
    if (!mounted) return;
    setState(() {
      _sims = sims;
      _simId = simId;
      _apps = apps;
      // Where it's stored, e.g. "Google · WhatsApp".
      _storage = {for (final r in raw) accountApp(r['accountType'] as String?)}.join(' · ');
    });
    await _loadFull();
  }

  /// Meet's video row (the Video tile) and the chat apps (their own card).
  Map<Object?, Object?>? get _meet => _apps.where(_isMeet).firstOrNull;
  Iterable<Map<Object?, Object?>> get _chatApps => _apps.where((a) => !_isMeet(a));
  static bool _isMeet(Map<Object?, Object?> app) => (app['mimeType'] as String?)?.contains('tachyon') ?? false;

  Future<void> _openApp(Map<Object?, Object?> app) =>
      _bridge.openContactData(app['dataId']! as int, app['mimeType']! as String);

  /// Reloads all fields (after editing, the repository notifies).
  Future<void> _loadFull() async {
    final full = await FlutterContacts.get(widget.contactId, properties: ContactProperties.all);
    if (mounted) setState(() => _full = full);
  }

  /// The SIM menu pops from what was tapped: the Call tile, or that number's row.
  final _callTileKey = GlobalKey();
  final _numberKeys = <String, GlobalKey>{};

  Future<void> _call(String number, GlobalKey anchor) => placeCall(context, number, simId: _simId, anchorKey: anchor);

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

  /// The "SIM card for calls" row: its choices pop from it.
  final _simRowKey = GlobalKey();

  Future<void> _chooseSim() async {
    (String?,)? picked;
    await OneUIFloatingMenu.show(
      context: context,
      anchorKey: _simRowKey,
      width: 240,
      items: [
        for (final (id, label) in [(null, 'Ask every time'), for (final s in _sims) (s.id, s.label)])
          OneUIFloatingMenuItem(
            label: label,
            icon: id == _simId ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            onTap: () => picked = (id,),
          ),
      ],
    );
    final choice = picked; // set from the menu's callback
    if (choice == null) return;
    await DialerPrefs.instance.setContactSim(widget.contactId, choice.$1);
    if (mounted) setState(() => _simId = choice.$1);
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
            body: Stack(
              children: [
                const Center(
                  child: Text('Contact not found', style: TextStyle(color: OneUITheme.textSecondary)),
                ),
                Positioned(
                  left: 16,
                  top: MediaQuery.paddingOf(context).top + 8,
                  child: RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
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
                    spacing: 12,
                    children: [
                      Expanded(
                        child: DetailsActionTile(
                          key: _callTileKey,
                          icon: Icons.call_rounded,
                          label: 'Call',
                          onTap: () => _call(primary, _callTileKey),
                        ),
                      ),
                      Expanded(
                        child: DetailsActionTile(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Message',
                          onTap: () => _bridge.sendSms(primary),
                        ),
                      ),
                      // Google Meet, when the contact has a Meet video row; greyed out otherwise.
                      Expanded(
                        child: DetailsActionTile(
                          icon: Icons.videocam_rounded,
                          label: 'Video',
                          onTap: switch (_meet) {
                            final meet? => () => _openApp(meet),
                            null => null,
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _numbersCard(contact),
                  _settingsCard(contact),
                  if (_full case final full?) ..._detailCards(full),
                  if (_chatApps.isNotEmpty) _appsCard(),
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

  /// Every number (tap to call; Message is the tile above), then the contact's ringtone.
  Widget _numbersCard(DialerContact contact) {
    final simLabel = _simLabel;
    return DetailsCard(
      children: [
        for (final (i, n) in contact.numbers.indexed)
          KeyedSubtree(
            key: _numberKeys.putIfAbsent(n, GlobalKey.new),
            child: _ValueRow(
              icon: Icons.call_outlined,
              showIcon: i == 0,
              label: [
                contact.labels[i],
                if (contact.numbers.length > 1 && i == contact.primaryIndex) 'Default',
                ?simLabel,
              ].join(' · '),
              value: n,
              onTap: () => _call(n, _numberKeys[n]!),
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

  /// Chat apps (WhatsApp...) as the details card's rows, the app's icon in the icon column.
  Widget _appsCard() {
    return DetailsCard(
      children: [
        for (final app in _chatApps)
          _ValueRow(
            leading: Align(
              alignment: Alignment.centerLeft,
              child: app['icon'] is Uint8List
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.memory(app['icon']! as Uint8List, width: 26, height: 26),
                    )
                  : const Icon(Icons.chat_outlined, size: 24),
            ),
            value: app['label']! as String,
            onTap: () => _openApp(app),
          ),
      ],
    );
  }

  /// SIM card for calls and Storage locations, on the page as on ColorOS (not in More).
  Widget _settingsCard(DialerContact contact) {
    return DetailsCard(
      children: [
        if (_sims.length > 1)
          KeyedSubtree(
            key: _simRowKey,
            child: _ValueRow(
              icon: Icons.sim_card_outlined,
              value: 'SIM card for calls',
              label: _sims.where((s) => s.id == _simId).map((s) => s.label).firstOrNull ?? 'Ask every time',
              onTap: _chooseSim,
            ),
          ),
        _ValueRow(
          icon: Icons.inventory_2_outlined,
          value: 'Storage locations',
          label: _storage,
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => StorageLocationsScreen(contact: contact)));
            _load(); // unlinking changes where it's stored
          },
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
              children: [for (final c in calls) ContactCallLogRow(call: c, simBadge: _simBadge(c.simId), now: now)],
            ),
          ],
        );
      },
    );
  }
}

/// Call / Message / Video tile, ColorOS style: a mono icon over its label on a flat card (no
/// glass: it scrolls); greyed out without [onTap]. Shared with the unsaved-number page.
class DetailsActionTile extends StatelessWidget {
  const DetailsActionTile({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

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
                Icon(icon, color: onTap == null ? OneUITheme.textTertiary : OneUITheme.textPrimary, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: onTap == null ? OneUITheme.textTertiary : OneUITheme.textPrimary,
                  ),
                ),
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
/// the value; rows with an icon column ([icon] or [leading]) put it below. [showIcon] false
/// keeps the column empty, so a contact's later numbers line up under the first.
class _ValueRow extends StatelessWidget {
  const _ValueRow({this.icon, this.leading, this.showIcon = true, this.label = '', required this.value, this.onTap});

  final IconData? icon;
  final Widget? leading;
  final bool showIcon;
  final String label;
  final String value;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final caption = label.isEmpty
        ? null
        : Text(label, style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary));
    final numberRow = icon != null || leading != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (numberRow)
              SizedBox(width: 40, child: !showIcon ? null : leading ?? (icon == null ? null : Icon(icon, size: 24))),
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
          ],
        ),
      ),
    );
  }
}

/// One logged call on the contact page and its Call logs page: muted arrow, when, SIM badge
/// and number, then talk time (or the type when there was none).
class ContactCallLogRow extends StatelessWidget {
  const ContactCallLogRow({super.key, required this.call, required this.simBadge, required this.now});

  final CallLogEntry call;
  final (String, Color)? simBadge;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = call;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 40, child: CallTypeIcon(type: c.type, muted: true)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${dayLabel(c.date, now)}, ${timeLabel(c.date)}', style: const TextStyle(fontSize: 17)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (simBadge case final badge?) ...[SimBadge(badge: badge), const SizedBox(width: 6)],
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
            c.type != CallType.missed && c.duration > Duration.zero ? durationLabel(c.duration) : callTypeLabel(c.type),
            style: TextStyle(
              fontSize: 13,
              color: c.type == CallType.missed ? OneUITheme.accentRed : OneUITheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
