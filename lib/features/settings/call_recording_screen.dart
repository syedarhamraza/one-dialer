import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/telecom/call_info.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_group_card.dart';
import '../contacts/contact_picker_screen.dart';
import '../recordings/recordings_screen.dart';

/// Settings › Call recording: shown only with One Recorder (the sideloaded companion)
/// installed. Its setup, the consent notice, auto-record rules, sound and storage.
class CallRecordingScreen extends StatefulWidget {
  const CallRecordingScreen({super.key});

  @override
  State<CallRecordingScreen> createState() => _CallRecordingScreenState();
}

class _CallRecordingScreenState extends State<CallRecordingScreen> with WidgetsBindingObserver {
  final _telecom = TelecomBridge.instance;
  RecorderInfo? _recorder;
  int _count = 0;
  final _mode = ValueNotifier<String?>('off');
  final _boost = ValueNotifier<String?>('off');
  final _source = ValueNotifier<String?>('auto');
  final _retention = ValueNotifier<String?>('0');
  List<String> _selectedIds = const [];
  List<String> _neverIds = const [];
  final _modeKey = GlobalKey();
  final _boostKey = GlobalKey();
  final _sourceKey = GlobalKey();
  final _retentionKey = GlobalKey();

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
    for (final n in [_mode, _boost, _source, _retention]) {
      n.dispose();
    }
    super.dispose();
  }

  static List<String> _ids(Object? json) {
    try {
      return (jsonDecode(json! as String) as List<Object?>).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refresh() async {
    final recorder = await _telecom.getRecorder();
    final trusted = recorder?.trusted == true;
    final count = trusted ? (await _telecom.listRecordings()).length : 0;
    final prefs = await _telecom.getCallSettings();
    final settings = trusted ? await _telecom.getRecorderSettings() : const <Object?, Object?>{};
    if (!mounted) return;
    setState(() {
      _recorder = recorder;
      _count = count;
      _selectedIds = _ids(prefs['recordContacts']);
      _neverIds = _ids(prefs['neverRecord']);
    });
    _mode.value = recorder?.autoRecordMode ?? 'off';
    _boost.value = settings['boost'] as String? ?? 'off';
    _source.value = settings['sourceMode'] as String? ?? 'auto';
    _retention.value = '${settings['retentionDays'] ?? 0}';
  }

  Future<void> _accept() async {
    await _telecom.setCallSetting('recordingConsent', true);
    _refresh();
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)).then((_) => _refresh());

  String _statusText(AppLocalizations l10n, RecorderInfo r) {
    if (!r.trusted) return l10n.recorderUntrusted;
    if (r.method == 'shell') return l10n.recorderBothSides;
    // Paired for both sides, but its helper has stopped (a reboot away from Wi-Fi, say).
    if (r.helperPaired && !r.helperRunning) return l10n.recorderHelperStopped;
    if (r.method == 'mic') return l10n.recorderMicrophone;
    if (!r.micGranted) return l10n.recorderNeedsMic;
    if (!r.accessibilityOn) return l10n.recorderNeedsAccessibility;
    return l10n.recorderReady;
  }

  static String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  Future<void> _deleteAll() async {
    final l10n = context.l10n;
    final ok = await showCosConfirm(
      context,
      title: l10n.deleteAllRecordingsTitle,
      message: l10n.deleteAllRecordingsMessage,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return;
    await _telecom.deleteAllRecordings();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = _recorder;
    final set = r != null && r.trusted && r.canRecord;
    return CosSubpage(
      title: l10n.callRecording,
      children: [
        if (r != null) ...[
          OneUIGroupCard(
            items: [
              OneUIGroupItem(
                title: l10n.recorderApp,
                subtitle: _statusText(l10n, r),
                subtitleColor: set ? null : OneUITheme.accentRed,
                value: set ? null : l10n.fix,
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
                OneUIGroupItem(title: l10n.recordings, value: '$_count', onTap: () => _push(const RecordingsScreen())),
              ],
            ),
            OneUIGroupCard(
              headerTitle: l10n.autoRecord,
              items: [
                choiceRow(
                  context,
                  title: l10n.autoRecord,
                  anchor: _modeKey,
                  value: _mode,
                  labels: {
                    'off': l10n.autoRecordOff,
                    'all': l10n.autoRecordAll,
                    'unknown': l10n.autoRecordUnknown,
                    'contacts': l10n.autoRecordContacts,
                  },
                  onPick: (v) {
                    _mode.value = v;
                    _telecom.setCallSetting('autoRecordMode', v);
                    setState(() {});
                  },
                ),
                if (_mode.value == 'contacts')
                  OneUIGroupItem(
                    title: l10n.recordTheseContacts,
                    value: '${_selectedIds.length}',
                    onTap: () =>
                        _push(RecordContactsScreen(prefKey: 'recordContacts', title: l10n.recordTheseContacts)),
                  ),
                OneUIGroupItem(
                  title: l10n.neverRecord,
                  subtitle: l10n.neverRecordSubtitle,
                  value: '${_neverIds.length}',
                  onTap: () => _push(RecordContactsScreen(prefKey: 'neverRecord', title: l10n.neverRecord)),
                ),
              ],
            ),
            OneUIGroupCard(
              headerTitle: l10n.recordingSound,
              items: [
                choiceRow(
                  context,
                  title: l10n.volumeBoost,
                  subtitle: l10n.volumeBoostSubtitle,
                  anchor: _boostKey,
                  value: _boost,
                  labels: {'off': l10n.boostOff, 'normal': l10n.boostNormal, 'strong': l10n.boostStrong},
                  onPick: (v) {
                    _boost.value = v;
                    _telecom.setRecorderSetting('boost', v);
                  },
                ),
                // Both sides records the call itself, not the microphone.
                if (r.method != 'shell')
                  choiceRow(
                    context,
                    title: l10n.micSource,
                    subtitle: l10n.micSourceSubtitle,
                    anchor: _sourceKey,
                    value: _source,
                    labels: {
                      'auto': l10n.micSourceAuto,
                      'recognition': l10n.micSourceRecognition,
                      'communication': l10n.micSourceCommunication,
                      'mic': l10n.micSourceMic,
                    },
                    onPick: (v) {
                      _source.value = v;
                      _telecom.setRecorderSetting('sourceMode', v);
                    },
                  ),
              ],
            ),
            OneUIGroupCard(
              headerTitle: l10n.storage,
              items: [
                OneUIGroupItem(title: l10n.storageUsed, value: _size(r.bytes), trailing: const SizedBox.shrink()),
                choiceRow(
                  context,
                  title: l10n.autoDelete,
                  subtitle: l10n.autoDeleteSubtitle,
                  anchor: _retentionKey,
                  value: _retention,
                  labels: {'0': l10n.autoDeleteNever, '30': l10n.autoDeleteDays(30), '90': l10n.autoDeleteDays(90)},
                  onPick: (v) {
                    _retention.value = v;
                    _telecom.setRecorderSetting('retentionDays', int.parse(v));
                  },
                ),
                if (_count > 0)
                  OneUIGroupItem(title: l10n.deleteAllRecordings, trailing: const SizedBox.shrink(), onTap: _deleteAll),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// The contacts auto-record picks out: "Record these contacts" or "Never record" (contact ids
/// in `CallPrefs`, read by `RecordRules.kt`).
class RecordContactsScreen extends StatefulWidget {
  const RecordContactsScreen({super.key, required this.prefKey, required this.title});

  final String prefKey;
  final String title;

  @override
  State<RecordContactsScreen> createState() => _RecordContactsScreenState();
}

class _RecordContactsScreenState extends State<RecordContactsScreen> {
  List<String> _ids = const [];

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getCallSettings().then((s) {
      if (mounted) setState(() => _ids = _CallRecordingScreenState._ids(s[widget.prefKey]));
    });
  }

  void _save(List<String> ids) {
    setState(() => _ids = ids);
    TelecomBridge.instance.setCallSetting(widget.prefKey, jsonEncode(ids));
  }

  Future<void> _add() async {
    final contact = await pickContact(context, title: widget.title);
    if (contact != null && !_ids.contains(contact.id)) _save([..._ids, contact.id]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final contacts = ContactsRepository.instance.allContacts.value;
    return CosSubpage(
      title: widget.title,
      children: [
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              leading: Icon(Icons.add_rounded, color: context.palette.textPrimary),
              title: l10n.addContact,
              trailing: const SizedBox.shrink(),
              onTap: _add,
            ),
            for (final id in _ids)
              () {
                final c = contacts.where((c) => c.id == id).firstOrNull;
                final name = c?.name ?? l10n.unknown;
                return OneUIGroupItem(
                  leading: LetterAvatar(name: name, size: 40),
                  title: name,
                  trailing: IconButton(
                    tooltip: l10n.remove,
                    icon: Icon(Icons.remove_circle_outline_rounded, color: context.palette.textSecondary),
                    onPressed: () => _save([..._ids]..remove(id)),
                  ),
                );
              }(),
          ],
        ),
      ],
    );
  }
}
