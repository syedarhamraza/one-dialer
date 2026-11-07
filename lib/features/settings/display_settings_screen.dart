import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../l10n/l10n.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../theme/one_ui_theme.dart';
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
        const _DisplaySizeCard(),
      ],
    );
  }
}

/// ColorOS's Display size: stepped sliders between a small and a big "A", for the whole app,
/// the top buttons and the nav bar. Each applies when the finger lifts, so a slider doesn't
/// move under it while dragging.
class _DisplaySizeCard extends StatefulWidget {
  const _DisplaySizeCard();

  @override
  State<_DisplaySizeCard> createState() => _DisplaySizeCardState();
}

class _DisplaySizeCardState extends State<_DisplaySizeCard> {
  static final _prefs = DialerPrefs.instance;
  late final _steps = {
    for (final n in [_prefs.displaySize, _prefs.headerSize, _prefs.navBarSize])
      n: DialerPrefs.displaySizes.indexOf(n.value),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.displaySizeSmall,
      l10n.displaySizeDefault,
      l10n.displaySizeLarge,
      l10n.displaySizeLarger,
      l10n.displaySizeLargest,
    ];
    final faint = context.palette.textSecondary;
    OneUIGroupItem row(String title, ValueNotifier<double> notifier) => OneUIGroupItem(
      title: title,
      value: labels[_steps[notifier]!],
      customSubtitle: Row(
        children: [
          Text('A', style: TextStyle(fontSize: 13, color: faint)),
          Expanded(
            child: Slider(
              value: _steps[notifier]!.toDouble(),
              max: labels.length - 1.0,
              divisions: labels.length - 1,
              activeColor: OneUITheme.accentGreen,
              onChanged: (v) => setState(() => _steps[notifier] = v.round()),
              onChangeEnd: (v) => _prefs.setSize(notifier, DialerPrefs.displaySizes[v.round()]),
            ),
          ),
          Text('A', style: TextStyle(fontSize: 20, color: faint)),
        ],
      ),
    );
    return OneUIGroupCard(
      headerTitle: l10n.displaySize,
      items: [
        row(l10n.displaySizeApp, _prefs.displaySize),
        row(l10n.displaySizeHeader, _prefs.headerSize),
        row(l10n.displaySizeNavBar, _prefs.navBarSize),
      ],
    );
  }
}
