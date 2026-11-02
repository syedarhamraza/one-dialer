import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../theme/one_ui_theme.dart';
import '../../theme/one_ui_scroll.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../../widgets/search_bar_row.dart';
import '../contacts/contact_details_screen.dart';
import 'search.dart';
import '../../l10n/l10n.dart';

Future<void> openSearch(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));

/// The Phone app's contact search: Recent searches, then matching contacts by name or
/// number, under ColorOS's glass search field and Cancel.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  List<String> _recent = const [];

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
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([_query, contactsRepo.contacts]),
            builder: (context, _) => CustomScrollView(
              physics: const OneUIScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, padding.top + 8 + _bar + 16, 16, padding.bottom + 32),
                  sliver: SliverMainAxisGroup(slivers: _results(context)),
                ),
              ],
            ),
          ),
          const Positioned(left: 0, right: 0, top: 0, child: OneUIStatusBarScrim()),
          // ColorOS: the search field across the top, Cancel beside it.
          Positioned(
            left: 16,
            right: 16,
            top: padding.top + 8,
            child: SearchBarRow(
              controller: _query,
              onSubmitted: (_) => _remember(),
              onCancel: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  static const double _bar = 48;

  List<Widget> _results(BuildContext context) {
    final contactsRepo = ContactsRepository.instance;
    final query = _query.text.trim();
    final hits = searchContacts(contactsRepo.contacts.value, query);
    return [
      if (query.isEmpty && _recent.isNotEmpty)
        SliverToBoxAdapter(
          child: _Card(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
            children: [
              Row(
                children: [
                  Expanded(child: _Label(context.l10n.recentSearches)),
                  TextButton(
                    onPressed: () async {
                      await DialerPrefs.instance.clearRecentSearches();
                      await _loadRecent();
                    },
                    child: Text(
                      context.l10n.clearAll,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: OneUITheme.accentBlue),
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
        ),
      if (query.isNotEmpty && hits.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 200),
            child: Center(
              child: Text(
                context.l10n.noResultsFound,
                style: TextStyle(fontSize: 22, color: context.palette.textSecondary),
              ),
            ),
          ),
        ),
      // Lazy card: a short query can match hundreds of contacts.
      if (hits.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(title: context.l10n.navContacts, count: hits.length),
        ),
        _CardSliver(
          itemCount: hits.length,
          itemBuilder: (context, i) {
            final h = hits[i];
            return _ResultRow(
              avatar: ContactAvatar(id: h.contact.id, name: h.contact.name, size: 36),
              title: _highlighted(h.contact.name, h.nameRange, 19, color: context.palette.textPrimary),
              subtitle: _highlighted(h.number, h.numberRange, 15, color: context.palette.textSecondary),
              divider: i > 0,
              onTap: () => _open(ContactDetailsScreen(contactId: h.contact.id)),
            );
          },
        ),
      ],
    ];
  }

  static Widget _highlighted(String text, (int, int)? range, double size, {required Color color}) {
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.palette.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(context.l10n.foundCount(count), style: style),
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
      decoration: BoxDecoration(color: context.palette.card, borderRadius: OneUITheme.cardBorderRadius),
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
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.palette.textSecondary),
    ),
  );
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.label, required this.onTap, required this.onRemove});

  final String label;
  final VoidCallback onTap, onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.pill,
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
                label: context.l10n.removeItem(label),
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: OneUITheme.surfacePillActive, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: context.palette.textSecondary),
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

/// [_Card] as a sliver: result rows build as they scroll in.
class _CardSliver extends StatelessWidget {
  const _CardSliver({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 12),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(color: context.palette.card, borderRadius: OneUITheme.cardBorderRadius),
        sliver: SliverList.builder(itemCount: itemCount, itemBuilder: itemBuilder),
      ),
    );
  }
}
