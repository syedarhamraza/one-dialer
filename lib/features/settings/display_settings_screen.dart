import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../l10n/l10n.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import 'call_settings_pages.dart' show effectsLabels;
import 'glass_settings_screen.dart';

/// Settings › Display & effects: the app's theme and how much glass it draws (the glass's own
/// options are on [GlassSettingsScreen]).
class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  static Map<String, String> themeLabels(AppLocalizations l10n) => {
    'system': l10n.settingsLanguageSystem,
    'light': l10n.themeLight,
    'dark': l10n.themeDark,
  };

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  final _themeKey = GlobalKey();
  final _effectsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return CosSubpage(
      title: context.l10n.displayAndEffects,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([prefs.visualEffects, prefs.navStyle]),
          builder: (context, _) {
            final full = prefs.visualEffects.value == 'full';
            return OneUIGroupCard(
              items: [
                choiceRow(
                  context,
                  title: context.l10n.appearance,
                  anchor: _themeKey,
                  value: prefs.themeMode,
                  labels: DisplaySettingsScreen.themeLabels(context.l10n),
                  onPick: prefs.setThemeMode,
                ),
                choiceRow(
                  context,
                  title: context.l10n.reduceVisualEffects,
                  subtitle: context.l10n.reduceVisualEffectsSubtitle,
                  anchor: _effectsKey,
                  value: prefs.visualEffects,
                  labels: effectsLabels(context.l10n),
                  onPick: prefs.setVisualEffects,
                ),
                // The glass only styles the full-effects look; below it the row goes away.
                if (full)
                  OneUIGroupItem(
                    title: context.l10n.glassSettings,
                    value: GlassSettingsScreen.styleLabels(context.l10n)[prefs.navStyle.value],
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => const GlassSettingsScreen())),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
