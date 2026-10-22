import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';
import '../../theme/one_ui_theme.dart';
import '../../theme/one_ui_scroll.dart';
import '../../widgets/call_glass.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_status_bar_scrim.dart';
import '../contacts/contact_details_screen.dart';
import 'search.dart';

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
            child: Row(
              children: [
                Expanded(
                  child: _SearchField(controller: _query, onSubmitted: (_) => _remember()),
                ),
                const SizedBox(width: 10),
                CallGlass(
                  radius: _bar / 2,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: TextButton.styleFrom(
                      foregroundColor: OneUITheme.textPrimary,
                      minimumSize: const Size(0, _bar),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
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
        ),
      if (query.isNotEmpty && hits.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 200),
            child: Center(
              child: Text('No results found', style: TextStyle(fontSize: 22, color: OneUITheme.textSecondary)),
            ),
          ),
        ),
      // Lazy card: a short query can match hundreds of contacts.
      if (hits.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(title: 'Contacts', count: hits.length),
        ),
        _CardSliver(
          itemCount: hits.length,
          itemBuilder: (context, i) {
            final h = hits[i];
            return _ResultRow(
              avatar: ContactAvatar(id: h.contact.id, name: h.contact.name, size: 36),
              title: _highlighted(h.contact.name, h.nameRange, 19),
              subtitle: _highlighted(h.number, h.numberRange, 15, color: OneUITheme.textSecondary),
              divider: i > 0,
              onTap: () => _open(ContactDetailsScreen(contactId: h.contact.id)),
            );
          },
        ),
      ],
    ];
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

/// ColorOS's search field: a glass stadium with the magnifier, the query and a clear button.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return CallGlass(
      radius: 24,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 24, color: OneUITheme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(fontSize: 17),
                  cursorColor: OneUITheme.accentBlue,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Search contacts',
                    hintStyle: TextStyle(fontSize: 17, color: OneUITheme.textSecondary),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox(width: 12)
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: controller.clear,
                        icon: const Icon(Icons.cancel_rounded, size: 20, color: OneUITheme.textSecondary),
                      ),
              ),
            ],
          ),
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
        decoration: BoxDecoration(color: OneUITheme.surfaceCard, borderRadius: OneUITheme.cardBorderRadius),
        sliver: SliverList.builder(itemCount: itemCount, itemBuilder: itemBuilder),
      ),
    );
  }
}
