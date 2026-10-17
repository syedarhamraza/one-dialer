import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../contacts/contact_picker_screen.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_group_card.dart';

/// Keypad keys 2–9: long-press calls the number assigned here.
class SpeedDialScreen extends StatelessWidget {
  const SpeedDialScreen({super.key});

  Future<void> _assign(BuildContext context, String digit) async {
    final picked = await pickContactNumber(context, title: 'Speed dial $digit');
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
            title: 'Speed dial numbers',
            builder: (context) => [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  'Long-press a key on the keypad to call',
                  style: TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                ),
              ),
              if (entries != null)
                OneUIGroupCard(
                  items: [
                    for (var i = 0; i < entries.length; i++) _item(context, DialerPrefs.speedDialDigits[i], entries[i]),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  OneUIGroupItem _item(BuildContext context, String digit, (String, String)? entry) => OneUIGroupItem(
    leading: SizedBox(
      width: 26,
      child: Text(
        digit,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      ),
    ),
    title: entry?.$1 ?? 'Not assigned',
    subtitle: entry?.$2,
    onTap: () => _assign(context, digit),
    trailing: entry == null
        ? const Icon(Icons.add_rounded, color: OneUITheme.accentBlue)
        : IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.remove_circle_outline_rounded, color: OneUITheme.accentRed),
            onPressed: () => DialerPrefs.instance.setSpeedDial(digit, null),
          ),
  );
}
