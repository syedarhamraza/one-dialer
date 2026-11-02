import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_version.dart';
import '../../core/config/changelog.dart';
import '../../core/haptics/haptics.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/version_mark.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../l10n/l10n.dart';

/// Software update › Changelog, written like a release note:
/// the running version over the artwork, its notes as short paragraphs, then earlier versions,
/// each opening its own page.
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

  @override
  Widget build(BuildContext context) {
    final latest = Changelog.entries.first;
    final earlier = Changelog.entries.skip(1).toList();
    return OneUISubpage(
      title: context.l10n.changelog,
      builder: (context) => [
        FutureBuilder(
          future: _installed,
          builder: (context, snapshot) {
            final installed = snapshot.data?.installed;
            return _ReleaseHero(
              entry: latest,
              // The notes ship with the app, so the newest entry is the running version
              // (app_version_test checks it).
              note: installed == null
                  ? latest.date
                  : context.l10n.installedOn(DateFormat.yMMMd(context.l10n.localeName).format(installed)),
            );
          },
        ),
        const SizedBox(height: 20),
        _ReleaseNotes(latest),
        if (earlier.isNotEmpty)
          OneUIGroupCard(
            headerTitle: context.l10n.earlierVersions,
            items: [
              for (final entry in earlier)
                OneUIGroupItem(
                  title: AppVersion.describe(entry.version),
                  value: entry.date,
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _ReleasePage(entry: entry))),
                ),
            ],
          ),
      ],
    );
  }
}

/// An earlier version's note on its own page.
class _ReleasePage extends StatelessWidget {
  const _ReleasePage({required this.entry});

  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: AppVersion.describe(entry.version),
      builder: (context) => [
        _ReleaseHero(entry: entry, note: entry.date),
        const SizedBox(height: 20),
        _ReleaseNotes(entry),
      ],
    );
  }
}

/// The artwork with the version written over it, as ColorOS heads its update notes.
class _ReleaseHero extends StatelessWidget {
  const _ReleaseHero({required this.entry, required this.note});

  final ChangelogEntry entry;
  final String note;

  @override
  Widget build(BuildContext context) {
    final v = AppVersion.tryParse(entry.version);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 290,
        child: Stack(
          children: [
            // Softly blurred, so the mark reads as the subject.
            const Positioned.fill(child: CosArtwork(waveShift: .3, blur: 3, dim: .35)),
            // The version mark centred, and when this release came.
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VersionMark(
                    version: v == null ? entry.version : '${v.major}.${v.minor}',
                    channel: v != null && v.isPreRelease ? v.channelLabel : null,
                    size: 84,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.isLight ? context.palette.textSecondary : const Color(0xCCFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The notes as short paragraphs. A note written "Topic: detail" leads with the topic in
/// bold, the way release notes read, instead of a bulleted list.
class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes(this.entry);

  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(fontSize: 16, height: 1.55, color: context.palette.textPrimary.withValues(alpha: .88));
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
      decoration: BoxDecoration(color: context.palette.card, borderRadius: OneUITheme.cardBorderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.aboutThisUpdate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (final change in entry.changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: switch (change.indexOf(': ')) {
                final i when i > 0 && i < 40 => Text.rich(
                  TextSpan(
                    style: body,
                    children: [
                      TextSpan(
                        text: '${change.substring(0, i)}. ',
                        style: TextStyle(fontWeight: FontWeight.w600, color: context.palette.textPrimary),
                      ),
                      TextSpan(text: _capitalised(change.substring(i + 2))),
                    ],
                  ),
                ),
                _ => Text(change, style: body),
              },
            ),
        ],
      ),
    );
  }

  static String _capitalised(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
