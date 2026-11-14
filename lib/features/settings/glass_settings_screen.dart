import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import 'call_settings_pages.dart' show edgeGlowLabels;

/// Settings › Display & effects › Glass & blur, at full visual effects: the glass style and, for liquid
/// glass, where it's drawn and how much of the package's effect it uses.
class GlassSettingsScreen extends StatefulWidget {
  const GlassSettingsScreen({super.key});

  static Map<String, String> styleLabels(AppLocalizations l10n) => {
    'frosted': l10n.navBarFrosted,
    'liquid': l10n.navBarLiquid,
  };

  @override
  State<GlassSettingsScreen> createState() => _GlassSettingsScreenState();
}

class _GlassSettingsScreenState extends State<GlassSettingsScreen> {
  final _styleKey = GlobalKey();
  final _glassDarkKey = GlobalKey();
  final _scopeKey = GlobalKey();
  final _effectKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final l10n = context.l10n;
    return CosSubpage(
      title: l10n.glassSettings,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([prefs.navStyle, prefs.liquidScope]),
          builder: (context, _) {
            final liquid = prefs.navStyle.value == 'liquid';
            // The glow strength styles dark mode's edge glow glass (light mode has one look, see
            // mainGlass), so it goes away in light mode and once liquid glass covers everything.
            final edgeGlow = !context.palette.isLight && (!liquid || prefs.liquidScope.value != 'all');
            return OneUIGroupCard(
              items: [
                choiceRow(
                  context,
                  title: l10n.glassStyle,
                  subtitle: l10n.glassStyleSubtitle,
                  anchor: _styleKey,
                  value: prefs.navStyle,
                  labels: GlassSettingsScreen.styleLabels(l10n),
                  onPick: prefs.setNavStyle,
                ),
                if (edgeGlow)
                  choiceRow(
                    context,
                    title: l10n.darkModeEdgeGlow,
                    subtitle: l10n.darkModeEdgeGlowSubtitle,
                    anchor: _glassDarkKey,
                    value: prefs.glassDark,
                    labels: edgeGlowLabels(l10n),
                    onPick: prefs.setGlassDark,
                  ),
                if (liquid)
                  choiceRow(
                    context,
                    title: l10n.liquidGlassOn,
                    subtitle: l10n.liquidGlassOnSubtitle,
                    anchor: _scopeKey,
                    value: prefs.liquidScope,
                    labels: {
                      'all': l10n.liquidScopeAll,
                      'controls': l10n.liquidScopeControls,
                      'navbar': l10n.liquidScopeNavbar,
                    },
                    onPick: prefs.setLiquidScope,
                  ),
                // The liquid glass material: the package's GlassQuality, or Automatic (LiquidQualityScope).
                if (liquid)
                  choiceRow(
                    context,
                    title: l10n.navBarGlass,
                    subtitle: l10n.navBarGlassSubtitle,
                    anchor: _effectKey,
                    value: prefs.navGlass,
                    labels: {
                      'premium': l10n.navGlassPremium,
                      'standard': l10n.navGlassStandard,
                      'auto': l10n.navGlassAuto,
                    },
                    onPick: prefs.setNavGlass,
                  ),
              ],
            );
          },
        ),
        // Styled like ShowcasePicker's footnote.
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Text(
            l10n.glassExperimentalNote,
            style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary),
          ),
        ),
      ],
    );
  }
}
