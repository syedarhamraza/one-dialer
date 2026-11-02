import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../l10n/l10n.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import 'call_settings_pages.dart' show edgeGlowLabels, effectsLabels;

/// Settings › Display & effects: the app's theme and how much glass it draws.
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
  final _glassDarkKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return CosSubpage(
      title: context.l10n.displayAndEffects,
      children: [
        ValueListenableBuilder(
          valueListenable: prefs.visualEffects,
          builder: (context, effects, _) => OneUIGroupCard(
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
              // The edge glow only styles the full-effects glass; below it the row goes away.
              if (effects == 'full')
                choiceRow(
                  context,
                  title: context.l10n.darkModeEdgeGlow,
                  anchor: _glassDarkKey,
                  value: prefs.glassDark,
                  labels: edgeGlowLabels(context.l10n),
                  onPick: prefs.setGlassDark,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
