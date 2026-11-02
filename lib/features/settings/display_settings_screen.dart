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
  final _navStyleKey = GlobalKey();
  final _navGlassKey = GlobalKey();

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
                // The edge glow and the nav bar's glass only style the full-effects look; below
                // it these rows go away.
                if (full)
                  choiceRow(
                    context,
                    title: context.l10n.darkModeEdgeGlow,
                    anchor: _glassDarkKey,
                    value: prefs.glassDark,
                    labels: edgeGlowLabels(context.l10n),
                    onPick: prefs.setGlassDark,
                  ),
                if (full)
                  choiceRow(
                    context,
                    title: context.l10n.navBarStyle,
                    anchor: _navStyleKey,
                    value: prefs.navStyle,
                    labels: {'frosted': context.l10n.navBarFrosted, 'liquid': context.l10n.navBarLiquid},
                    onPick: prefs.setNavStyle,
                  ),
                // The liquid bar's material: the glass package's GlassQuality.
                if (full && prefs.navStyle.value == 'liquid')
                  choiceRow(
                    context,
                    title: context.l10n.navBarGlass,
                    anchor: _navGlassKey,
                    value: prefs.navGlass,
                    labels: {
                      'premium': context.l10n.navGlassPremium,
                      'standard': context.l10n.navGlassStandard,
                    },
                    onPick: prefs.setNavGlass,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
