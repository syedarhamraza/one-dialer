import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../l10n/l10n.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/showcase_picker.dart';
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
  final _glassDarkKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final themes = DisplaySettingsScreen.themeLabels(context.l10n);
    final effects = effectsLabels(context.l10n);
    return CosSubpage(
      title: context.l10n.displayAndEffects,
      children: [
        ShowcaseTitle(context.l10n.appearance),
        ShowcasePicker(
          value: prefs.themeMode,
          onPick: prefs.setThemeMode,
          options: [
            ShowcaseOption(value: 'system', label: themes['system']!, preview: const _SystemPreview()),
            ShowcaseOption(
              value: 'light',
              label: themes['light']!,
              preview: const PhonePreview(
                showCaller: false,
                screen: _MiniApp.lightScreen,
                child: _MiniApp(light: true),
              ),
            ),
            ShowcaseOption(
              value: 'dark',
              label: themes['dark']!,
              preview: const PhonePreview(
                showCaller: false,
                screen: _MiniApp.darkScreen,
                child: _MiniApp(light: false),
              ),
            ),
          ],
        ),
        ShowcaseTitle(context.l10n.visualEffects),
        ShowcasePicker(
          value: prefs.visualEffects,
          onPick: prefs.setVisualEffects,
          footnote: context.l10n.reduceVisualEffectsSubtitle,
          options: [
            for (final level in ['full', 'reduced', 'off'])
              ShowcaseOption(value: level, label: effects[level]!, preview: _EffectsPreview(level)),
          ],
        ),
        // The edge glow only styles the full-effects glass; below it the row goes away.
        ValueListenableBuilder(
          valueListenable: prefs.visualEffects,
          builder: (context, level, _) => level != 'full'
              ? const SizedBox.shrink()
              : OneUIGroupCard(
                  items: [
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

/// The Calls tab in miniature: a big title, a card of rows, and the nav bar pill.
class _MiniApp extends StatelessWidget {
  const _MiniApp({required this.light, this.pill});

  final bool light;

  /// The nav bar pill's look; the theme's plain pill when null.
  final Decoration? pill;

  static const lightScreen = BoxDecoration(color: Color(0xFFF2F2F7));
  static const darkScreen = BoxDecoration(color: Colors.black);

  @override
  Widget build(BuildContext context) {
    final ink = light ? Colors.black : Colors.white;
    final card = light ? Colors.white : const Color(0xFF1C1C1E);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 30, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PreviewBar(40, 8, .8, color: ink),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                for (final (i, color) in _avatars.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PreviewBar(i.isEven ? 34 : 26, 3, .55, color: ink),
                            const SizedBox(height: 3),
                            PreviewBar(20, 2, .3, color: ink),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 64,
              height: 16,
              margin: const EdgeInsets.only(bottom: 14),
              decoration:
                  pill ??
                  BoxDecoration(
                    color: light ? const Color(0xFFE5E5EA) : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static const _avatars = [
    Color(0xFF5390F5),
    Color(0xFF48B5A0),
    Color(0xFFF4A261),
    Color(0xFF7E57C2),
    Color(0xFFF07167),
  ];
}

/// Same as phone: the light app with its lower right half dark.
class _SystemPreview extends StatelessWidget {
  const _SystemPreview();

  @override
  Widget build(BuildContext context) => PhonePreview(
    showCaller: false,
    screen: _MiniApp.lightScreen,
    child: Stack(
      children: [
        const Positioned.fill(child: _MiniApp(light: true)),
        Positioned.fill(
          child: ClipPath(
            clipper: _Diagonal(),
            child: const DecoratedBox(decoration: _MiniApp.darkScreen, child: _MiniApp(light: false)),
          ),
        ),
      ],
    ),
  );
}

class _Diagonal extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_Diagonal oldClipper) => false;
}

/// The dark app over a colourful page, its nav bar pill drawn the way [level] draws glass:
/// frosted with a lit rim, a flat translucent fill, or solid. Drawn, never a real blur.
class _EffectsPreview extends StatelessWidget {
  const _EffectsPreview(this.level);

  final String level;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final pill = switch (level) {
      'full' => BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: .45), width: .8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: .32), Colors.white.withValues(alpha: .08)],
        ),
      ),
      'reduced' => BoxDecoration(borderRadius: radius, color: const Color(0xCC2C2C2E)),
      _ => BoxDecoration(borderRadius: radius, color: const Color(0xFF2C2C2E)),
    };
    return PhonePreview(
      showCaller: false,
      screen: _MiniApp.darkScreen,
      child: Stack(
        children: [
          // Colour under the nav bar pill (bottom 14, 64 × 16): it shows through the glass,
          // dimly through the reduced fill, and not at all through the solid one.
          const Positioned(
            left: 28,
            right: 28,
            bottom: 18,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                gradient: LinearGradient(colors: [Color(0xFF5390F5), Color(0xFF48B5A0), Color(0xFFF4A261)]),
                boxShadow: [BoxShadow(color: Color(0x8848B5A0), blurRadius: 6)],
              ),
            ),
          ),
          Positioned.fill(child: _MiniApp(light: false, pill: pill)),
        ],
      ),
    );
  }
}
