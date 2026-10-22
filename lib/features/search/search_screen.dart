import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_search_field.dart';
import '../../widgets/one_ui_subpage.dart';
import '../contacts/contact_details_screen.dart';
import '../recents/call_details_screen.dart';
import '../recents/call_log.dart';
import '../recents/call_log_repository.dart';
import '../recents/recents_screen.dart' show CallTypeIcon;
import 'search.dart';

Future<void> openSearch(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));

/// Samsung's Phone search: Filters (call time / type chips), Recent searches, and results
/// grouped as Favorites, Contacts and Recents, with the search pill floating at the bottom.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  bool _showFilters = false;
  CallTime? _time;
  CallFilter? _type;
  List<String> _recent = const [];

  static const _types = [CallFilter.missed, CallFilter.rejected, CallFilter.outgoing, CallFilter.incoming];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await DialerPrefs.instance.recentSearches();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _remember() async {
    final q = _query.text.trim();
    if (q.isNotEmpty) await DialerPrefs.instance.updateRecentSearch(q);
    await _loadRecent();
  }

  void _open(Widget page) {
    _remember();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _setQuery(String q) {
    _query.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsRepo = ContactsRepository.instance;
    final callsRepo = CallLogRepository.instance;
    return OneUISubpage(
      title: '',
      listenable: Listenable.merge([_query, contactsRepo.contacts, callsRepo.calls]),
      bottomPill: SizedBox(
        width: MediaQuery.sizeOf(context).width - 32,
        child: OneUIFloatingSearchField(
          controller: _query,
          hintText: 'Search',
          autofocus: true,
          onSubmitted: (_) => _remember(),
        ),
      ),
      builder: (context) {
        final query = _query.text.trim();
        final filtering = _time != null || _type != null;
        // Like Samsung, call filters narrow the results to Recents.
        final hits = filtering ? const <ContactHit>[] : searchContacts(contactsRepo.contacts.value, query);
        final favorites = [
          for (final h in hits)
            if (h.contact.isFavorite) h,
        ];
        final calls = query.isEmpty && !filtering
            ? const <CallLogEntry>[]
            : searchCalls(
                callsRepo.calls.value,
                query,
                time: _time,
                type: _type,
                nameFor: contactsRepo.nameFor,
                now: DateTime.now(),
              );
        return [
          _FiltersHeader(open: _showFilters, onTap: () => setState(() => _showFilters = !_showFilters)),
          if (_showFilters)
            _Card(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              children: [
                const _Label('Call time'),
                _Chips(
                  labels: [for (final t in CallTime.values) t.label],
                  selected: _time?.index,
                  onTap: (i) => setState(() => _time = _time == CallTime.values[i] ? null : CallTime.values[i]),
                ),
                const SizedBox(height: 24),
                const _Label('Call type'),
                _Chips(
                  labels: [for (final t in _types) t.label],
                  selected: _type == null ? null : _types.indexOf(_type!),
                  onTap: (i) => setState(() => _type = _type == _types[i] ? null : _types[i]),
                ),
              ],
            ),
          if (query.isEmpty && !filtering && _recent.isNotEmpty)
            _Card(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
              children: [
                Row(
                  children: [
                    const Expanded(child: _Label('Recent searches')),
                    TextButton(
                      onPressed: () async {
                        await DialerPrefs.instance.clearRecentSearches();
                        await _loadRecent();
                      },
                      child: const Text(
                        'Clear all',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: OneUITheme.accentBlue),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in _recent)
                      _RecentChip(
                        label: s,
                        onTap: () => _setQuery(s),
                        onRemove: () async {
                          await DialerPrefs.instance.updateRecentSearch(s, remove: true);
                          await _loadRecent();
                        },
                      ),
                  ],
                ),
              ],
            ),
          if ((query.isNotEmpty || filtering) && hits.isEmpty && calls.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 200),
              child: Center(
                child: Text('No results found', style: TextStyle(fontSize: 22, color: OneUITheme.textSecondary)),
              ),
            ),
          for (final (title, list) in [
            ('Favorites', favorites),
            (
              'Contacts',
              [
                for (final h in hits)
                  if (!h.contact.isFavorite) h,
              ],
            ),
          ])
            if (list.isNotEmpty) ...[
              _SectionHeader(title: title, count: list.length),
              _Card(
                children: [
                  for (final (i, h) in list.indexed)
                    _ResultRow(
                      avatar: ContactAvatar(id: h.contact.id, name: h.contact.name, size: 36),
                      title: _highlighted(h.contact.name, h.nameRange, 19),
                      subtitle: _highlighted(h.number, h.numberRange, 15, color: OneUITheme.textSecondary),
                      divider: i > 0,
                      onTap: () => _open(ContactDetailsScreen(contactId: h.contact.id)),
                    ),
                ],
              ),
            ],
          if (calls.isNotEmpty) ...[
            _SectionHeader(title: 'Recents', count: calls.length),
            _Card(
              children: [
                // shortcut: shows the newest 100 matches, add paging if people need older calls here.
                for (final (i, c) in calls.take(100).indexed)
                  _ResultRow(
                    avatar: LetterAvatar(name: callName(c, contactsRepo.nameFor) ?? '', size: 36),
                    title: _highlighted(
                      c.isPrivate ? 'Private number' : callName(c, contactsRepo.nameFor) ?? c.number,
                      c.isPrivate ? null : matchRange(callName(c, contactsRepo.nameFor) ?? c.number, query),
                      19,
                    ),
                    subtitle: Row(
                      children: [
                        CallTypeIcon(type: c.type),
                        const SizedBox(width: 6),
                        Text(
                          '${dayLabel(c.date, DateTime.now())}, ${timeLabel(c.date)}',
                          style: const TextStyle(fontSize: 15, color: OneUITheme.textSecondary),
                        ),
                      ],
                    ),
                    divider: i > 0,
                    onTap: () {
                      _remember();
                      openCallDetails(context, c);
                    },
                  ),
              ],
            ),
          ],
        ];
      },
    );
  }

  static Widget _highlighted(String text, (int, int)? range, double size, {Color color = OneUITheme.textPrimary}) {
    final style = TextStyle(fontSize: size, color: color);
    if (range == null) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    final (start, end) = range;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(color: OneUITheme.accentBlue, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FiltersHeader extends StatelessWidget {
  const _FiltersHeader({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Filters',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
              ),
            ),
            Icon(
              open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: OneUITheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text('$count found', style: style),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: OneUITheme.cardBorderRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
    ),
  );
}

/// Single-choice outlined chips; tapping the selected one clears it.
class _Chips extends StatelessWidget {
  const _Chips({required this.labels, required this.selected, required this.onTap});

  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 10,
      children: [
        for (final (i, label) in labels.indexed)
          Semantics(
            selected: i == selected,
            button: true,
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: i == selected ? OneUITheme.accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(OneUITheme.radiusPill),
                  border: Border.all(color: i == selected ? OneUITheme.accentBlue : OneUITheme.surfacePillActive),
                ),
                child: Text(label, style: const TextStyle(fontSize: 15, color: OneUITheme.textPrimary)),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.label, required this.onTap, required this.onRemove});

  final String label;
  final VoidCallback onTap, onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OneUITheme.surfacePill,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Remove $label',
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: OneUITheme.surfacePillActive, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 18, color: OneUITheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.divider,
    required this.onTap,
  });

  final Widget avatar, title, subtitle;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: divider
                      ? Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10), width: 0.8))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 4), subtitle],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
