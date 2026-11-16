import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_switch.dart';
import '../../widgets/one_ui_toast.dart';

/// Settings › Back up & restore: one backup file (settings, speed dial, call notes, call
/// backgrounds and their photos) in a folder picked once, `One Dialer/One Dialer backup.zip`,
/// overwritten on every backup; Back up now, Restore, and Auto backup every day to every month.
/// The backup itself is native (`AutoBackup.kt`, `SettingsBackup.kt`).
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  /// Auto backup's choices, in hours.
  static const intervals = [24, 72, 168, 720];

  /// "Last backup: …" or "Not backed up yet", for this page and the Settings row.
  static String lastLabel(BuildContext context, int last) {
    final l10n = context.l10n;
    if (last <= 0) return l10n.backupNever;
    final at = DateTime.fromMillisecondsSinceEpoch(last);
    final locale = Localizations.localeOf(context).toString();
    return l10n.lastBackup('${DateFormat.yMMMd(locale).format(at)} ${DateFormat.jm(locale).format(at)}');
  }

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _telecom = TelecomBridge.instance;
  final _frequencyKey = GlobalKey();
  final _frequency = ValueNotifier<String?>('24');
  Map<String, Object?> _status = const {};
  bool _busy = false;

  int get _interval => (_status['interval'] as int?) ?? 0;
  String? get _path => _status['path'] as String?;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _frequency.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      _show(await _telecom.getBackupStatus());
    } on PlatformException {
      // No bridge: the page shows its defaults.
    }
  }

  void _show(Map<String, Object?>? status) {
    if (status == null || !mounted) return;
    setState(() => _status = status);
    if (_interval > 0) _frequency.value = '$_interval';
  }

  Future<void> _backUpNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await _telecom.exportSettings();
      if (saved != null && mounted) {
        OneUIToast.show(context, saved ? context.l10n.backedUp : context.l10n.couldNotBackUp);
      }
    } on PlatformException {
      if (mounted) OneUIToast.show(context, context.l10n.couldNotBackUp);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    final ok = await showCosConfirm(
      context,
      title: l10n.importSettingsTitle,
      message: l10n.importSettingsMessage,
      confirmLabel: l10n.restoreBackup,
    );
    if (!ok || !mounted) return;
    try {
      // On success the app restarts with the restored settings and this never returns.
      final read = await _telecom.importSettings();
      if (read == false && mounted) OneUIToast.show(context, l10n.notASettingsFile);
    } on PlatformException catch (e) {
      if (mounted) OneUIToast.show(context, e.code == 'IN_CALL' ? l10n.importSettingsInCall : l10n.couldNotOpenFile);
    }
  }

  /// Picks the folder; false when cancelled.
  Future<bool> _chooseFolder() async {
    try {
      final status = await _telecom.chooseBackupFolder();
      _show(status);
      return status != null;
    } on PlatformException {
      if (mounted) OneUIToast.show(context, context.l10n.couldNotBackUp);
      return false;
    }
  }

  Future<void> _setAuto(bool on) async {
    // On needs a folder first; cancelling the picker leaves it off.
    if (on && _path == null && !await _chooseFolder()) return;
    _show(await _telecom.setAutoBackup(on ? int.parse(_frequency.value ?? '24') : 0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = _interval > 0;
    final failed = _status['failed'] == true;
    final labels = {
      '24': l10n.backupEveryDay,
      '72': l10n.backupEvery3Days,
      '168': l10n.backupEveryWeek,
      '720': l10n.backupEveryMonth,
    };
    final secondary = TextStyle(fontSize: 13.5, color: context.palette.textSecondary);
    return CosSubpage(
      title: l10n.backUpRestore,
      children: [
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: l10n.backUpNow,
              subtitle: BackupScreen.lastLabel(context, (_status['last'] as int?) ?? 0),
              trailing: _busy
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _backUpNow,
            ),
            OneUIGroupItem(title: l10n.restoreBackup, subtitle: l10n.restoreBackupSubtitle, onTap: _restore),
          ],
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: l10n.autoBackup,
              trailing: OneUISwitch(value: on, onChanged: _setAuto),
              onTap: () => _setAuto(!on),
            ),
            if (on)
              choiceRow(
                context,
                title: l10n.backupFrequency,
                anchor: _frequencyKey,
                value: _frequency,
                labels: labels,
                onPick: (v) async {
                  _frequency.value = v;
                  _show(await _telecom.setAutoBackup(int.parse(v)));
                },
              ),
            OneUIGroupItem(
              title: l10n.backupLocation,
              // The full path, so the file is easy to find in the Files app.
              subtitle: _path ?? l10n.backupLocationNone,
              onTap: _chooseFolder,
            ),
          ],
        ),
        if (failed)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Text(l10n.backupFailed, style: secondary.copyWith(color: OneUITheme.accentRed)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          child: Text(l10n.backupFootnote, style: secondary),
        ),
      ],
    );
  }
}
