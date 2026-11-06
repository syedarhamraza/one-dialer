import 'dart:typed_data';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart' show listEquals;
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
import '../../widgets/call_glyph.dart';
import '../../widgets/press_glow.dart';
import '../../widgets/round_header_controls.dart';
import '../blocking/blocking_repository.dart';
import '../recents/call_details_screen.dart' show CallNotesCard;
import '../recents/call_log.dart';
import '../recents/app_calls.dart' show appCallLabel;
import '../recents/call_log_repository.dart';
import '../recents/recents_screen.dart' show CallTypeIcon, SimBadge;
import 'contact_actions.dart';
import 'contact_subpages.dart';
import 'editor/contact_editor_screen.dart';
import 'editor/contact_form.dart' show labelDisplay, labelText;
import '../../l10n/l10n.dart';

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
  String? _ringtone; // the custom ringtone's name; null follows the system
  Map<String, ({String? formatted, String? location})> _display = const {}; // number → grouped + country

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
    final (sims, simId, apps, raw, ringtone) = await (
      _bridge.getSims(),
      DialerPrefs.instance.contactSim(widget.contactId),
      _bridge.getMessagingApps(widget.contactId),
      _bridge.getRawContacts(widget.contactId),
      _bridge.getRingtoneTitle(widget.contactId),
    ).wait;
    if (!mounted) return;
    setState(() {
      _sims = sims;
      _simId = simId;
      _apps = apps;
      _ringtone = ringtone;
      // Where it's stored, e.g. "Google · WhatsApp".
      _storage = {for (final r in raw) accountApp(context.l10n, r['accountType'] as String?)}.join(' · ');
    });
    await _loadFull();
  }

  /// Formats [numbers] for [_display] once per set: the contact may load after the page opens
  /// (a cold start from another app), and an edit can change its numbers.
  void _describe(List<String> numbers) {
    if (listEquals(_described, numbers)) return;
    _described = numbers;
    _bridge.describeNumbers(numbers).then((d) {
      if (!mounted || _described != numbers) return;
      setState(
        () => _display = {
          for (final (i, n) in numbers.indexed)
            if (i < d.length) n: d[i],
        },
      );
    });
  }

  List<String>? _described;

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
        label: context.l10n.shareVcf,
        onTap: () {
          if (_full != null) ContactActions.shareVCard(context.l10n, _full!);
        },
      ),
      OneUIFloatingMenuItem(
        label: context.l10n.shareText,
        onTap: () => ContactActions.shareText(context.l10n, contact),
      ),
      OneUIFloatingMenuItem(
        label: context.l10n.qrCode,
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
        OneUIFloatingMenuItem(label: context.l10n.share, onTap: () => _share(contact)),
        OneUIFloatingMenuItem(
          label: blocked ? context.l10n.unblockContact : context.l10n.blockContact,
          onTap: () async {
            for (final n in contact.numbers) {
              await blocking.setBlocked(n, !blocked);
            }
          },
        ),
        OneUIFloatingMenuItem(
          label: context.l10n.delete,
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
        for (final (id, label) in [(null, context.l10n.askEveryTime), for (final s in _sims) (s.id, s.label)])
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
                Center(
                  child: Text(context.l10n.contactNotFound, style: TextStyle(color: context.palette.textSecondary)),
                ),
                Positioned(
                  left: 16,
                  top: MediaQuery.paddingOf(context).top + 8,
                  child: RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: context.l10n.back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ),
          );
        }
        _describe(contact.numbers);
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
                      photo: !DialerPrefs.instance.showPhotos.value
                          ? null
                          : _full?.photo?.fullSize ?? ContactsRepository.instance.cachedThumbnail(contact.id),
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
                          label: context.l10n.call,
                          onTap: () => _call(primary, _callTileKey),
                        ),
                      ),
                      Expanded(
                        child: DetailsActionTile(
                          icon: Icons.chat_rounded,
                          label: context.l10n.message,
                          onTap: () => _bridge.sendSms(primary),
                        ),
                      ),
                      // Google Meet, when the contact has a Meet video row; greyed out otherwise.
                      Expanded(
                        child: DetailsActionTile(
                          icon: Icons.videocam_rounded,
                          label: context.l10n.video,
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
                  if (_full case final full?) ..._detailCards(full),
                  if (_chatApps.isNotEmpty) _appsCard(),
                  CallNotesCard(numbers: contact.numbers),
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
                      tooltip: context.l10n.back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    // RoundIconButton with an orange star when it's a favourite.
                    CallGlass(
                      child: IconButton(
                        tooltip: contact.isFavorite ? context.l10n.removeFromFavourites : context.l10n.addToFavourites,
                        onPressed: () => repo.setFavorite(contact.id, !contact.isFavorite),
                        style: IconButton.styleFrom(
                          foregroundColor: contact.isFavorite ? const Color(0xFFF7A93B) : context.palette.textPrimary,
                          fixedSize: const Size.square(_button),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(contact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, size: 26),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: context.l10n.edit,
                      onTap: () => openContactEditor(context, contactId: contact.id),
                    ),
                    const SizedBox(width: 8),
                    // The menu measures this wrapper, outside the glass press, like Calls' menu.
                    KeyedSubtree(
                      key: _moreKey,
                      child: RoundIconButton(
                        icon: Icons.more_vert_rounded,
                        tooltip: context.l10n.moreOptions,
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
  String? _simBadge(String? simId) {
    if (_sims.length < 2 || simId == null) return null;
    final i = _sims.indexWhere((s) => s.id == simId);
    return i < 0 ? null : '${i + 1}';
  }

  /// Which of a several-number contact's numbers a call used ("Mobile · 0311 1234567"); null
  /// for a one-number contact, where the row needs no number.
  String? _numberLine(DialerContact contact, String number) {
    if (contact.numbers.length < 2) return null;
    final i = contact.numbers.indexWhere((n) => numberKey(n) == numberKey(number));
    if (i < 0) return number;
    final n = contact.numbers[i];
    return [
      labelDisplay(context.l10n, contact.labels[i]),
      _display[n]?.formatted ?? n,
    ].where((s) => s.isNotEmpty).join(' · ');
  }

  /// ColorOS's main card: every number (tap to call; Message is the tile above), then the
  /// contact's ringtone, SIM for calls and where it's saved, each value over its name.
  Widget _numbersCard(DialerContact contact) {
    final simLabel = _simLabel;
    return DetailsCard(
      padding: _cardPadding,
      children: [
        for (final (i, n) in contact.numbers.indexed)
          KeyedSubtree(
            key: _numberKeys.putIfAbsent(n, GlobalKey.new),
            child: _ValueRow(
              label: [
                labelDisplay(context.l10n, contact.labels[i]),
                if (contact.numbers.length > 1 && i == contact.primaryIndex) context.l10n.defaultNumber,
                _display[n]?.location,
                simLabel,
              ].whereType<String>().where((s) => s.isNotEmpty).join('  |  '),
              value: _display[n]?.formatted ?? n,
              onTap: () => _call(n, _numberKeys[n]!),
            ),
          ),
        _ValueRow(
          value: _ringtone ?? context.l10n.followSystem,
          label: context.l10n.ringtone,
          onTap: () async {
            await ContactActions.changeRingtone(contact.id);
            final ringtone = await _bridge.getRingtoneTitle(contact.id);
            if (mounted) setState(() => _ringtone = ringtone);
          },
        ),
        if (_sims.length > 1)
          KeyedSubtree(
            key: _simRowKey,
            child: _ValueRow(
              value: _sims.where((s) => s.id == _simId).map((s) => s.label).firstOrNull ?? context.l10n.askEveryTime,
              label: context.l10n.simForCalls,
              onTap: _chooseSim,
            ),
          ),
        _ValueRow(
          value: _storage.isEmpty ? context.l10n.storageLocations : _storage,
          label: _storage.isEmpty ? '' : context.l10n.storageLocations,
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => StorageLocationsScreen(contact: contact)));
            _load(); // unlinking changes where it's stored
          },
        ),
      ],
    );
  }

  /// Text inset the same from both edges, so the hairlines are too.
  static const _cardPadding = EdgeInsets.fromLTRB(18, 8, 18, 8);

  /// Emails, addresses, dates, work, websites, relationships and notes, when present, in one card.
  List<Widget> _detailCards(Contact c) {
    final l10n = context.l10n;
    final organizations = [
      for (final o in c.organizations)
        if ([o.name, o.jobTitle, o.departmentName].any((s) => s?.isNotEmpty ?? false)) o,
    ];
    final notes = [
      for (final n in c.notes)
        if (n.note.trim().isNotEmpty) n.note.trim(),
    ];
    final rows = <Widget>[
      for (final e in c.emails)
        _ValueRow(
          label: labelDisplay(l10n, labelText(e.label)),
          value: e.address,
          onTap: () => _bridge.openSystemSettings('url:mailto:${e.address}'),
        ),
      for (final a in c.addresses)
        _ValueRow(
          label: l10n.addressLabel(labelDisplay(l10n, labelText(a.label))),
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
          label: labelDisplay(l10n, labelText(d.label)),
          value: d.year == null
              ? DateFormat.MMMMd().format(DateTime(2000, d.month, d.day))
              : DateFormat.yMMMMd().format(DateTime(d.year!, d.month, d.day)),
        ),
      for (final o in organizations)
        _ValueRow(
          label: l10n.organization,
          value: [o.jobTitle, o.departmentName, o.name].whereType<String>().where((s) => s.isNotEmpty).join(', '),
        ),
      for (final w in c.websites)
        _ValueRow(
          label: l10n.website,
          value: w.url,
          onTap: () => _bridge.openSystemSettings('url:${w.url.contains('://') ? w.url : 'https://${w.url}'}'),
        ),
      for (final r in c.relations) _ValueRow(label: labelDisplay(l10n, labelText(r.label)), value: r.name),
      for (final n in notes) _ValueRow(label: l10n.notes, value: n),
    ];
    return rows.isEmpty ? const [] : [DetailsCard(padding: _cardPadding, children: rows)];
  }

  /// Chat apps (WhatsApp...) as the details card's rows, the app's icon in the icon column.
  Widget _appsCard() {
    return DetailsCard(
      dividerIndent: 40,
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
                  : const Icon(CupertinoIcons.chat_bubble, size: 26),
            ),
            value: app['label']! as String,
            onTap: () => _openApp(app),
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
        final grey = context.palette.textSecondary;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(context.l10n.callLogs, style: TextStyle(fontSize: 15, color: grey)),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => ContactHistoryScreen(contact: contact))),
                    style: TextButton.styleFrom(foregroundColor: grey),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The button's own label style is medium weight; match the plain "Call logs".
                        Text(context.l10n.viewAll, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DetailsCard(
              padding: _cardPadding,
              children: [
                for (final c in calls)
                  ContactCallLogRow(
                    call: c,
                    simBadge: _simBadge(c.simId),
                    now: now,
                    numberLine: _numberLine(contact, c.number),
                  ),
              ],
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
    // Claims vertical drags that start on it (as CallGlass does), so holding and moving a tile
    // plays the press instead of scrolling the page.
    return GestureDetector(
      onVerticalDragStart: _holdStill,
      child: PressGlow(
        radius: 999,
        child: Material(
          color: context.palette.card,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            // Full width: the glass press hands its child loose constraints.
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  CallGlyph(
                    icon,
                    color: onTap == null ? context.palette.textTertiary : context.palette.textPrimary,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: onTap == null ? context.palette.textTertiary : context.palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _holdStill(DragStartDetails _) {}
}

class DetailsCard extends StatelessWidget {
  const DetailsCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(18, 8, 12, 8),
    this.dividerIndent = 0,
    this.dividerEndIndent = 0,
  });

  final List<Widget> children;
  final EdgeInsets padding;

  /// Where the hairline between rows starts and ends, inside [padding].
  final double dividerIndent, dividerEndIndent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: padding,
      decoration: ShapeDecoration(color: context.palette.card, shape: OneUITheme.cardShape),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) RowDivider(indent: dividerIndent, endIndent: dividerEndIndent),
            child,
          ],
        ],
      ),
    );
  }
}

/// [DetailsCard] as a sliver for long lists (call logs): rows build as they scroll in.
class DetailsCardSliver extends StatelessWidget {
  const DetailsCardSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.padding,
    this.dividerIndent = 0,
    this.dividerEndIndent = 0,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;
  final double dividerIndent, dividerEndIndent;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 20),
      sliver: DecoratedSliver(
        decoration: ShapeDecoration(color: context.palette.card, shape: OneUITheme.cardShape),
        sliver: SliverPadding(
          padding: padding,
          sliver: SliverList.separated(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            separatorBuilder: (_, _) => RowDivider(indent: dividerIndent, endIndent: dividerEndIndent),
          ),
        ),
      ),
    );
  }
}

/// The hairline between rows of a details card.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key, this.indent = 0, this.endIndent = 0});

  final double indent, endIndent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 0.8, indent: indent, endIndent: endIndent, color: context.palette.divider);
}

/// A value over its grey label, ColorOS style, with no icon column ([leading] is a chat app's own
/// icon); tappable when [onTap] is set.
class _ValueRow extends StatelessWidget {
  const _ValueRow({this.leading, this.label = '', required this.value, this.onTap});

  final Widget? leading;
  final String label;
  final String value;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: SquircleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (leading case final leading?) SizedBox(width: 40, child: leading),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 19, height: 1.3)),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(fontSize: 14, color: context.palette.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One logged call on the contact, Call logs and unsaved-number pages: the time, then one grey
/// line with the arrow, SIM badge, number, type and talk time.
class ContactCallLogRow extends StatelessWidget {
  const ContactCallLogRow({super.key, required this.call, required this.simBadge, required this.now, this.numberLine});

  final CallLogEntry call;
  final String? simBadge;
  final DateTime now;

  /// Which number the call used, for a contact with several; null leaves it out.
  final String? numberLine;

  @override
  Widget build(BuildContext context) {
    final c = call;
    final l10n = context.l10n;
    final grey = context.palette.textSecondary;
    final locale = l10n.localeName;
    // ColorOS's history: "8/21/26 15:28", with the clock as the phone sets it.
    final date = DateFormat(DateFormat.yMd(locale).pattern!.replaceAll(RegExp('y+'), 'yy'), locale).format(c.date);
    final time = MediaQuery.alwaysUse24HourFormatOf(context)
        ? DateFormat.Hm(locale).format(c.date)
        : timeLabel(l10n, c.date);
    final type = switch (c.type) {
      CallType.outgoing => l10n.logOutgoing,
      CallType.missed => l10n.logMissed,
      CallType.rejected => l10n.logRejected,
      CallType.blocked => l10n.logBlocked,
      CallType.voicemail => l10n.callTypeVoicemail,
      _ => l10n.logIncoming,
    };
    // Talk time for answered calls; for missed and rejected ones the log's duration is ring time.
    final talked = c.type == CallType.incoming || c.type == CallType.outgoing;
    final rang = (c.type == CallType.missed || c.type == CallType.rejected) && c.duration > Duration.zero;
    final detail = [
      if (c.isApp)
        appCallLabel(l10n, c)
      else if (rang)
        l10n.logRangFor(type, durationLabel(l10n, c.duration))
      else if (talked)
        '$type  ${c.duration > Duration.zero ? durationLabel(l10n, c.duration) : l10n.callNotConnected}'
      else
        type,
    ].join('  ');
    final badge = c.isApp ? null : simBadge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$date $time',
            style: TextStyle(fontSize: 18, color: c.type == CallType.missed ? OneUITheme.accentRed : null),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              CallTypeIcon(type: c.type, size: 15),
              const SizedBox(width: 6),
              if (badge != null) ...[SimBadge(label: badge), const SizedBox(width: 6)],
              if (c.isVolte) ...[_VolteMark(color: grey), const SizedBox(width: 6)],
              if (c.isHd) ...[_HdMark(color: grey), const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: grey),
                ),
              ),
            ],
          ),
          // Its own line, so the badges and duration never cut the number off.
          if (numberLine case final line?) ...[
            const SizedBox(height: 2),
            Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: grey)),
          ],
        ],
      ),
    );
  }
}

/// The history's VoLTE mark: "Vo" over "LTE", tiny and grey.
class _VolteMark extends StatelessWidget {
  const _VolteMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 6.5, height: 1, fontWeight: FontWeight.w700, color: color);
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Vo', style: style),
          Text('LTE', style: style),
        ],
      ),
    );
  }
}

/// The history's HD voice mark: "HD" knocked out of a small grey tag.
class _HdMark extends StatelessWidget {
  const _HdMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        child: Text(
          'HD',
          style: TextStyle(fontSize: 8, height: 1.1, fontWeight: FontWeight.w800, color: context.palette.card),
        ),
      ),
    );
  }
}
