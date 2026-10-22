import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_info.dart';
import '../../core/config/app_version.dart';
import '../../core/config/changelog.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../core/haptics/haptics.dart';

/// Settings › What's new (also Software update › Changelog): the installed version's notes in a card,
/// then earlier versions collapsed to one row each.
class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  static Future<void> open(BuildContext context) {
    Haptics.tap();
    return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChangelogScreen()));
  }

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  static final DateFormat _installedFormat = DateFormat('MMM d, y');

  final Set<String> _expanded = {};
  late final Future<({AppVersion? version, DateTime? installed})> _installed = _loadInstalled();

  static Future<({AppVersion? version, DateTime? installed})> _loadInstalled() async {
    final version = await AppVersion.current();
    DateTime? installed;
    try {
      installed = (await PackageInfo.fromPlatform()).updateTime;
    } catch (_) {
      installed = null;
    }
    return (version: version, installed: installed);
  }

  void _toggle(String version) {
    Haptics.select();
    setState(() => _expanded.contains(version) ? _expanded.remove(version) : _expanded.add(version));
  }

  @override
  Widget build(BuildContext context) {
    final latest = Changelog.entries.first;
    final earlier = Changelog.entries.skip(1).toList();
    return OneUISubpage(
      title: "What's new",
      builder: (context) => [
        // ColorOS's artwork as the page's banner.
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 170,
            child: Stack(
              children: [
                const Positioned.fill(child: CosArtwork()),
                Center(
                  child: Text(
                    "What's new in\n${AppInfo.name}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder(
          future: _installed,
          builder: (context, snapshot) => _InstalledCard(
            entry: latest,
            // The notes ship with the app, so the newest entry is the running version
            // (app_version_test checks it). Unknown versions (tests, odd platforms) count too.
            installed: snapshot.data?.version == null || snapshot.data!.version!.name == latest.version,
            installedOn: snapshot.data?.installed == null ? null : _installedFormat.format(snapshot.data!.installed!),
          ),
        ),
        if (earlier.isNotEmpty)
          OneUISection(
            title: 'Earlier versions',
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, entry) in earlier.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    _EarlierVersion(
                      entry: entry,
                      expanded: _expanded.contains(entry.version),
                      onTap: () => _toggle(entry.version),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The installed version: title, "Installed" chip, dates and every change.
class _InstalledCard extends StatelessWidget {
  final ChangelogEntry entry;
  final bool installed;
  final String? installedOn;

  const _InstalledCard({required this.entry, required this.installed, required this.installedOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppVersion.describe(entry.version),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ),
              if (installed) ...[const SizedBox(width: 10), const _InstalledChip()],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [entry.date, if (installed && installedOn != null) 'Installed $installedOn'].join(' · '),
            style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
          ),
          const SizedBox(height: 10),
          _ChangeList(entry.changes),
        ],
      ),
    );
  }
}

/// Blue capsule marking the version that's running.
class _InstalledChip extends StatelessWidget {
  const _InstalledChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: OneUITheme.accentBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
      ),
      child: const Text(
        'Installed',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OneUITheme.accentBlue),
      ),
    );
  }
}

/// One collapsed row ("1.0.0 Alpha 2", "Oct 2026 · 4 changes") that expands into its notes.
class _EarlierVersion extends StatelessWidget {
  final ChangelogEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  const _EarlierVersion({required this.entry, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = entry.changes.length;
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppVersion.describe(entry.version),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, height: 1.25, color: OneUITheme.textPrimary),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${entry.date} · $count ${count == 1 ? 'change' : 'changes'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, height: 1.25, color: OneUITheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: const Icon(Icons.expand_more_rounded, color: OneUITheme.textSecondary),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: expanded
                    ? Padding(
                        key: const ValueKey('open'),
                        padding: const EdgeInsets.only(top: 10),
                        child: _ChangeList(entry.changes),
                      )
                    : const SizedBox(key: ValueKey('closed'), width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Release notes as blue-dot bullet rows.
class _ChangeList extends StatelessWidget {
  final List<String> changes;

  const _ChangeList(this.changes);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final change in changes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 12),
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: OneUITheme.accentBlue, shape: BoxShape.circle),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(change, style: const TextStyle(fontSize: 15, height: 1.4, color: OneUITheme.textPrimary)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
