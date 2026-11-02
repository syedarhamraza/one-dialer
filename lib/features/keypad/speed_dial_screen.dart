import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../contacts/contact_picker_screen.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../core/haptics/haptics.dart';
import '../../widgets/letter_avatar.dart';
import '../../widgets/one_ui_toast.dart';
import '../../l10n/l10n.dart';

/// Keypad keys 2–9: long-press calls the number assigned here.
class SpeedDialScreen extends StatelessWidget {
  const SpeedDialScreen({super.key});

  Future<void> _assign(BuildContext context, String digit) async {
    final picked = await pickContactNumber(context, title: context.l10n.speedDialKey(digit));
    if (picked == null) return;
    await DialerPrefs.instance.setSpeedDial(digit, (picked.$1.name, picked.$2));
  }

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return ValueListenableBuilder<int>(
      valueListenable: prefs.changes,
      builder: (context, _, _) => FutureBuilder<List<(String, String)?>>(
        future: Future.wait([for (final d in DialerPrefs.speedDialDigits) prefs.speedDial(d)]),
        builder: (context, snap) {
          final entries = snap.data;
          return OneUISubpage(
            title: context.l10n.speedDial,
            builder: (context) => [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 8, 14, 28),
                child: Text(
                  context.l10n.speedDialAssignContacts,
                  style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
                ),
              ),
              if (entries != null)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.78,
                  children: [
                    _Cell(digit: '1', label: context.l10n.voicemail, icon: Icons.voicemail_rounded),
                    for (var i = 0; i < entries.length; i++) _cell(context, DialerPrefs.speedDialDigits[i], entries[i]),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(BuildContext context, String digit, (String, String)? entry) => _Cell(
    digit: digit,
    label: entry?.$1 ?? context.l10n.add,
    icon: entry == null ? Icons.add_rounded : null,
    name: entry?.$1,
    onTap: () => _assign(context, digit),
    onLongPress: entry == null
        ? null
        : () {
            Haptics.longPress();
            DialerPrefs.instance.setSpeedDial(digit, null);
            OneUIToast.show(context, context.l10n.speedDialRemoved(entry.$1, digit));
          },
  );
}

/// One key of the ColorOS speed-dial grid: its digit, a grey circle and a label.
class _Cell extends StatelessWidget {
  const _Cell({required this.digit, required this.label, this.icon, this.name, this.onTap, this.onLongPress});

  final String digit;
  final String label;
  final IconData? icon;

  /// The assigned contact, drawn as their avatar instead of [icon].
  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const double _circle = 76;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 4,
          top: 0,
          child: Text(digit, style: TextStyle(fontSize: 20, color: context.palette.textSecondary)),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: name != null
                      ? LetterAvatar(name: name!, size: _circle)
                      : Container(
                          width: _circle,
                          height: _circle,
                          decoration: BoxDecoration(
                            color: context.palette.isLight ? const Color(0xFFE4E4E9) : const Color(0xFF333335),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 36),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: context.palette.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
