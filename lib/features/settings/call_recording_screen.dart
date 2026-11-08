import 'package:flutter/material.dart';

import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';

/// Settings › Call recording: shown only with One Dialer Recorder (the sideloaded companion)
/// installed. Its setup, the consent notice, auto-record and the saved recordings.
class CallRecordingScreen extends StatefulWidget {
  const CallRecordingScreen({super.key});

  @override
  State<CallRecordingScreen> createState() => _CallRecordingScreenState();
}

class _CallRecordingScreenState extends State<CallRecordingScreen> with WidgetsBindingObserver {
  final _telecom = TelecomBridge.instance;
  RecorderInfo? _recorder;
  List<CallRecording> _recordings = const [];
  final _auto = ValueNotifier(false);
  final _menuKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(); // back from the companion's setup
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auto.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final recorder = await _telecom.getRecorder();
    final recordings = recorder?.trusted == true ? await _telecom.listRecordings() : const <CallRecording>[];
    if (!mounted) return;
    setState(() {
      _recorder = recorder;
      _recordings = recordings;
    });
    _auto.value = recorder?.autoRecord ?? false;
  }

  Future<void> _accept() async {
    await _telecom.setCallSetting('recordingConsent', true);
    _refresh();
  }

  String _statusText(AppLocalizations l10n, RecorderInfo r) {
    if (!r.trusted) return l10n.recorderUntrusted;
    if (!r.micGranted) return l10n.recorderNeedsMic;
    if (!r.accessibilityOn) return l10n.recorderNeedsAccessibility;
    return l10n.recorderReady;
  }

  void _more(CallRecording r) => OneUIFloatingMenu.show(
    context: context,
    anchorKey: _menuKeys[r.name]!,
    items: [
      OneUIFloatingMenuItem(
        label: context.l10n.share,
        icon: Icons.share_outlined,
        onTap: () => _telecom.shareRecording(r.name),
      ),
      OneUIFloatingMenuItem(
        label: context.l10n.delete,
        icon: Icons.delete_outline_rounded,
        onTap: () async {
          await _telecom.deleteRecording(r.name);
          _refresh();
        },
      ),
    ],
  );

  Future<void> _deleteAll() async {
    final l10n = context.l10n;
    final ok = await OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: l10n.deleteAllRecordingsTitle,
      message: l10n.deleteAllRecordingsMessage,
      confirmLabel: l10n.delete,
      confirmTextColor: OneUITheme.accentRed,
    );
    if (ok != true) return;
    await _telecom.deleteAllRecordings();
    _refresh();
  }

  String _subtitle(CallRecording r) {
    final m = MaterialLocalizations.of(context);
    final seconds = r.duration.inSeconds;
    final length = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return '${m.formatShortDate(r.start)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(r.start))} · $length';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = _recorder;
    return CosSubpage(
      title: l10n.callRecording,
      children: [
        if (r != null) ...[
          OneUIGroupCard(
            items: [
              OneUIGroupItem(
                title: l10n.recorderApp,
                subtitle: _statusText(l10n, r),
                subtitleColor: r.trusted && r.micGranted && r.accessibilityOn ? null : OneUITheme.accentRed,
                value: r.trusted && r.micGranted && r.accessibilityOn ? null : l10n.fix,
                onTap: () => _telecom.openRecorderSetup(),
              ),
            ],
          ),
          // Nothing records until the user has read this once.
          if (!r.consented)
            OneUIGroupCard(
              headerTitle: l10n.recordingConsentTitle,
              items: [
                OneUIGroupItem(title: l10n.recordingConsentAccept, subtitle: l10n.recordingConsentBody, onTap: _accept),
              ],
            )
          else ...[
            OneUIGroupCard(
              items: [
                switchRow(l10n.recordAllCalls, _auto, (v) {
                  _auto.value = v;
                  _telecom.setCallSetting('autoRecord', v);
                }, subtitle: l10n.recordAllCallsSubtitle),
              ],
            ),
            OneUIGroupCard(
              headerTitle: l10n.recordings,
              items: [
                if (_recordings.isEmpty) OneUIGroupItem(title: l10n.noRecordings, subtitle: l10n.noRecordingsSubtitle),
                for (final rec in _recordings)
                  OneUIGroupItem(
                    title: rec.number ?? l10n.unknown,
                    subtitle: _subtitle(rec),
                    onTap: () => _telecom.openRecording(rec.name),
                    trailing: IconButton(
                      key: _menuKeys.putIfAbsent(rec.name, GlobalKey.new),
                      tooltip: l10n.moreOptions,
                      icon: Icon(Icons.more_vert_rounded, color: context.palette.textSecondary),
                      onPressed: () => _more(rec),
                    ),
                  ),
              ],
            ),
            if (_recordings.isNotEmpty)
              OneUIGroupCard(
                items: [
                  OneUIGroupItem(
                    title: l10n.deleteAllRecordings,
                    subtitleColor: OneUITheme.accentRed,
                    onTap: _deleteAll,
                  ),
                ],
              ),
          ],
        ],
      ],
    );
  }
}
