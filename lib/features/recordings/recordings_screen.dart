import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/haptics/haptics.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_segmented_pills.dart';
import '../../widgets/one_ui_selection_header_pills.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../../widgets/round_header_controls.dart';
import '../../widgets/search_bar_row.dart';
import '../../widgets/select_mark.dart';
import '../recents/call_log.dart' show dayLabel, timeLabel;

enum RecordingFilter { all, starred, contacts, unknown }

/// Who a recording is with: the contact's name, else the number, else Unknown.
String recordingName(AppLocalizations l10n, CallRecording r) =>
    (r.number == null ? null : ContactsRepository.instance.nameFor(r.number!)) ?? r.number ?? l10n.unknown;

/// What the search and filter keep, newest first as the companion lists them.
List<CallRecording> filterRecordings(
  List<CallRecording> all,
  RecordingFilter filter,
  String query, {
  required String? Function(String number) nameFor,
}) {
  final q = query.trim().toLowerCase();
  final digits = q.replaceAll(RegExp(r'[^0-9+]'), '');
  return all.where((r) {
    final name = r.number == null ? null : nameFor(r.number!);
    final keep = switch (filter) {
      RecordingFilter.all => true,
      RecordingFilter.starred => r.starred,
      RecordingFilter.contacts => name != null,
      RecordingFilter.unknown => name == null,
    };
    if (!keep || q.isEmpty) return keep;
    return (name ?? '').toLowerCase().contains(q) ||
        (r.title ?? '').toLowerCase().contains(q) ||
        (digits.isNotEmpty && (r.number ?? '').contains(digits));
  }).toList();
}

/// All recordings from One Dialer Recorder: searchable, filtered, grouped by day, with
/// play, star, rename, share, save to phone and delete (one at a time or selected).
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final _telecom = TelecomBridge.instance;
  final _query = TextEditingController();
  final _all = ValueNotifier<List<CallRecording>>(const []);
  final _filter = ValueNotifier(RecordingFilter.all);

  /// Null while not selecting.
  final _selected = ValueNotifier<Set<String>?>(null);
  final _menuKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _query.dispose();
    _all.dispose();
    _filter.dispose();
    _selected.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final list = await _telecom.listRecordings();
    if (mounted) _all.value = list;
  }

  List<CallRecording> get _shown => filterRecordings(
    _all.value,
    _filter.value,
    _query.text,
    nameFor: ContactsRepository.instance.nameFor,
  );

  void _toggle(CallRecording r) {
    final set = {...?_selected.value};
    set.contains(r.name) ? set.remove(r.name) : set.add(r.name);
    _selected.value = set.isEmpty ? null : set;
  }

  Future<void> _rename(CallRecording r) async {
    final l10n = context.l10n;
    final title = await OneUIFloatingModal.showTextInputDialog(
      context: context,
      title: l10n.renameRecording,
      initialValue: r.title ?? '',
      confirmLabel: l10n.save,
    );
    if (title == null) return;
    await _telecom.renameRecording(r.name, title);
    _refresh();
  }

  Future<void> _save(List<CallRecording> list) async {
    final l10n = context.l10n;
    var ok = true;
    for (final r in list) {
      ok &= await _telecom.exportRecording(r.name, r.title ?? recordingName(l10n, r));
    }
    if (mounted) OneUIToast.show(context, ok ? l10n.recordingsSaved(list.length) : l10n.recordingSaveFailed);
  }

  Future<void> _delete(List<CallRecording> list) async {
    final l10n = context.l10n;
    final ok = await OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: l10n.deleteRecordings(list.length),
      message: l10n.deleteAllRecordingsMessage,
      confirmLabel: l10n.delete,
      confirmTextColor: OneUITheme.accentRed,
    );
    if (ok != true) return;
    for (final r in list) {
      await _telecom.deleteRecording(r.name);
    }
    _selected.value = null;
    _refresh();
  }

  void _more(CallRecording r) {
    final l10n = context.l10n;
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _menuKeys[r.name]!,
      items: [
        OneUIFloatingMenuItem(
          label: r.starred ? l10n.unstar : l10n.star,
          icon: r.starred ? Icons.star_rounded : Icons.star_outline_rounded,
          onTap: () => _telecom.starRecording(r.name, !r.starred).then((_) => _refresh()),
        ),
        OneUIFloatingMenuItem(label: l10n.rename, icon: Icons.edit_outlined, onTap: () => _rename(r)),
        OneUIFloatingMenuItem(label: l10n.share, icon: Icons.share_outlined, onTap: () => _telecom.shareRecordings([r.name])),
        OneUIFloatingMenuItem(label: l10n.saveToPhone, icon: Icons.download_rounded, onTap: () => _save([r])),
        OneUIFloatingMenuItem(label: l10n.delete, icon: Icons.delete_outline_rounded, onTap: () => _delete([r])),
      ],
    );
  }

  OneUIGroupItem _row(CallRecording r, Set<String>? selected) {
    final l10n = context.l10n;
    final name = recordingName(l10n, r);
    final contact = r.number == null ? null : ContactsRepository.instance.contactFor(r.number!);
    final minutes = r.duration.inSeconds ~/ 60;
    final length = '$minutes:${(r.duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final line = [if (r.title != null) r.title!, timeLabel(l10n, r.start), length].join(' · ');
    return OneUIGroupItem(
      leading: selected != null
          ? SelectMark(selected: selected.contains(r.name), gap: 0)
          : LetterAvatar(name: contact?.name ?? name, size: 40),
      title: name,
      customSubtitle: Row(
        children: [
          if (r.incoming != null) ...[
            Icon(
              r.incoming! ? Icons.call_received_rounded : Icons.call_made_rounded,
              size: 14,
              color: context.palette.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
            ),
          ),
        ],
      ),
      onTap: selected != null ? () => _toggle(r) : () => _telecom.openRecording(r.name),
      onLongPress: selected != null
          ? null
          : () {
              Haptics.longPress();
              _selected.value = {r.name};
            },
      trailing: selected != null
          ? const SizedBox.shrink()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (r.starred) const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB400)),
                IconButton(
                  key: _menuKeys.putIfAbsent(r.name, GlobalKey.new),
                  tooltip: l10n.moreOptions,
                  icon: Icon(Icons.more_vert_rounded, color: context.palette.textSecondary),
                  onPressed: () => _more(r),
                ),
              ],
            ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selected.value;
    if (selected != null) {
      final shown = _shown;
      return SizedBox(
        height: 48,
        child: Row(
          children: [
            RoundIconButton(icon: Icons.close_rounded, tooltip: l10n.cancel, onTap: () => _selected.value = null),
            const SizedBox(width: 12),
            OneUISelectionCountPill(
              selectedCount: selected.length,
              totalCount: shown.length,
              onToggleSelectAll: () => _selected.value = selected.length == shown.length
                  ? null
                  : shown.map((r) => r.name).toSet(),
            ),
          ],
        ),
      );
    }
    return ExpandableSearchHeader(
      controller: _query,
      hint: l10n.searchRecordings,
      leading: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: l10n.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.recordings,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _selected,
      builder: (context, _) {
        final selected = _selected.value;
        final picked = _all.value.where((r) => selected?.contains(r.name) ?? false).toList();
        return PopScope(
          canPop: selected == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _selected.value = null;
          },
          child: OneUISubpage(
            title: l10n.recordings,
            header: _header(context),
            listenable: Listenable.merge([_all, _filter, _query, ContactsRepository.instance.contacts]),
            bottomPill: selected == null
                ? null
                : OneUIFloatingActionBar(
                    items: [
                      OneUIFloatingActionBarItem(
                        icon: Icons.share_outlined,
                        label: l10n.share,
                        onTap: () => _telecom.shareRecordings(picked.map((r) => r.name).toList()),
                      ),
                      OneUIFloatingActionBarItem(
                        icon: Icons.download_rounded,
                        label: l10n.saveToPhone,
                        onTap: () => _save(picked),
                      ),
                      OneUIFloatingActionBarItem(
                        icon: Icons.delete_outline_rounded,
                        label: l10n.delete,
                        color: OneUITheme.accentRed,
                        onTap: () => _delete(picked),
                      ),
                    ],
                  ),
            slivers: (context) {
              final shown = _shown;
              // Day groups, like Recents.
              final days = <(String, List<CallRecording>)>[];
              final now = DateTime.now();
              for (final r in shown) {
                final label = dayLabel(l10n, r.start, now);
                if (days.isEmpty || days.last.$1 != label) days.add((label, []));
                days.last.$2.add(r);
              }
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OneUISegmentedPills<RecordingFilter>(
                      dense: true,
                      segments: [
                        (value: RecordingFilter.all, label: l10n.all),
                        (value: RecordingFilter.starred, label: l10n.filterStarred),
                        (value: RecordingFilter.contacts, label: l10n.navContacts),
                        (value: RecordingFilter.unknown, label: l10n.filterUnknown),
                      ],
                      selected: _filter.value,
                      onChanged: (f) => _filter.value = f,
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverToBoxAdapter(
                    child: OneUIGroupCard(
                      items: [
                        OneUIGroupItem(
                          title: _all.value.isEmpty ? l10n.noRecordings : l10n.noMatchingRecordings,
                          subtitle: _all.value.isEmpty ? l10n.noRecordingsSubtitle : null,
                        ),
                      ],
                    ),
                  ),
                for (final (label, items) in days)
                  OneUIGroupCardSliver(
                    headerTitle: label,
                    itemCount: items.length,
                    itemBuilder: (context, i) => _row(items[i], selected),
                  ),
              ];
            },
          ),
        );
      },
    );
  }
}
