import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import 'one_ui_effects.dart';
import 'one_ui_scroll.dart';

export 'one_ui_effects.dart';

/// Samsung One UI design tokens, ported from OneSpend (`D:\one-spend\lib\theme\one_ui_theme.dart`).
/// Uses OneSpend's default flat look; its 3D / appearance settings are not ported.
class OneUITheme {
  // --- Pure OLED Black & Neutral Charcoal Surfaces ---
  static const Color surfacePitch = Color(0xFF000000);
  static const Color surfaceCard = Color(0xFF1C1C1E);
  static const Color surfaceCardHighlight = Color(0xFF262628);
  static const Color surfacePill = Color(0xFF2C2C2E);
  static const Color surfacePillActive = Color(0xFF3E3E42);

  // --- One UI Accent Palette ---
  static const Color accentGreen = Color(0xFF00C05A); // One UI Phone green

  /// The main app's call green: the round dialpad button and the keypad's Call button.
  static const Color dialGreen = Color(0xFF5BB450);
  static const Color accentBlue = Color(0xFF5390F5);
  static const Color accentRed = Color(0xFFF07167);
  static const Color accentTeal = Color(0xFF48B5A0);
  static const Color accentPurple = Color(0xFF7E57C2);
  static const Color accentAmber = Color(0xFFF4A261);
  static const Color accentOrange = Color(0xFFFB8C00);

  // --- Floating navbar (flat) ---
  static const Color navbar3dActivePill = Color(0xFF3E3E42);
  static const Color navbar3dInactiveIcon = Color(0xFFD4D4D8);
  static const Color navbar3dInactiveText = Color(0xFFB4B4B8);
  static const Color surfaceInset = Color(0x0AFFFFFF);

  // --- Text ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EA4);
  static const Color textTertiary = Color(0xFF6A6A70);
  static const Color sectionHeader = Color(0xFFD4D4D8);

  // --- Radii ---
  static const double radiusPill = 34.0;
  static const double radiusCard = 26.0;
  static const double radiusInner = 20.0;
  static const double radiusBadge = 16.0;

  static BorderRadius get pillBorderRadius => BorderRadius.circular(radiusPill);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get innerBorderRadius => BorderRadius.circular(radiusInner);
  static BorderRadius get fieldBorderRadius => pillBorderRadius;

  // --- Card and floating surfaces (OneSpend's flat look, see one_ui_effects.dart) ---
  static Color get cardColor => OneUIEffectsController.instance.cardColor;
  static Border? get cardBorder => OneUIEffectsController.instance.cardBorder;
  static List<BoxShadow> get cardShadow => OneUIEffectsController.instance.cardShadow;
  static Color get floatingColor => OneUIEffectsController.instance.floatingColor;
  static Gradient? get floatingGradient => OneUIEffectsController.instance.floatingGradient;
  static Border? get floatingBorder => OneUIEffectsController.instance.floatingBorder;
  static List<BoxShadow> get floatingShadow => OneUIEffectsController.instance.floatingShadow;
  static List<BoxShadow> get navbarShadow => OneUIEffectsController.instance.navbarShadow;
  static List<BoxShadow> get fabShadow => OneUIEffectsController.instance.fabShadow;
  static double get blurSigma => OneUIEffectsController.instance.blurSigma;
  static Border? get subtleBorder => null;

  static final ThemeData darkTheme = _theme(Brightness.dark);
  static final ThemeData lightTheme = _theme(Brightness.light);

  static ThemeData _theme(Brightness brightness) {
    final p = brightness == Brightness.light ? OneUIPalette.light : OneUIPalette.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: p.page,
      primaryColor: accentBlue,
      canvasColor: p.page,
      cardColor: p.card,
      fontFamily: 'Roboto',
      colorScheme: (brightness == Brightness.light ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
        surface: p.page,
        primary: accentBlue,
        secondary: accentGreen,
        error: accentRed,
        onSurface: p.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        // A transparent bar would otherwise pick white status icons on the light page.
        systemOverlayStyle: brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 0.8),
      // Slide, like One UI. Android's default zoom transition fades whole pages, which
      // costs a full-screen save layer every frame of every push and pop.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()},
      ),
    );
  }

  /// Pass to `MaterialApp.scrollBehavior`.
  static const ScrollBehavior scrollBehavior = OneUIScrollBehavior();
}

/// Page colours (backgrounds, cards, rows, text) for the current brightness. Floating glass
/// keeps [OneUITheme]'s dark constants in both modes; read these with `context.palette`.
class OneUIPalette {
  const OneUIPalette._({
    required this.page,
    required this.card,
    required this.cardHighlight,
    required this.pill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.sectionHeader,
    required this.divider,
    required this.pillActive,
  });

  final Color page;
  final Color card;
  final Color cardHighlight;
  final Color pill;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color sectionHeader;
  final Color divider;
  final Color pillActive;

  /// Light mode's flat glass fills (dark mode keeps [OneUIEffectsController]'s).
  static const lightFloating = Color(0xCCF8F8FA);
  static const lightModal = Color(0xEBF8F8FA);

  bool get isLight => identical(this, light);

  /// [g], a black page fade, redrawn in the light page colour (same alphas).
  LinearGradient tint(LinearGradient g) => isLight
      ? LinearGradient(
          begin: g.begin,
          end: g.end,
          stops: g.stops,
          colors: [for (final c in g.colors) page.withValues(alpha: c.a)],
        )
      : g;

  static const dark = OneUIPalette._(
    page: OneUITheme.surfacePitch,
    card: OneUITheme.surfaceCard,
    cardHighlight: OneUITheme.surfaceCardHighlight,
    pill: OneUITheme.surfacePill,
    textPrimary: OneUITheme.textPrimary,
    textSecondary: OneUITheme.textSecondary,
    textTertiary: OneUITheme.textTertiary,
    sectionHeader: OneUITheme.sectionHeader,
    divider: Color(0x1AFFFFFF),
    pillActive: OneUITheme.surfacePillActive,
  );

  /// ColorOS 17 light: grey page, white cards, black text.
  static const light = OneUIPalette._(
    page: Color(0xFFF2F2F6),
    card: Color(0xFFFFFFFF),
    cardHighlight: Color(0xFFE8E8EC),
    pill: Color(0xFFE6E6EA),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF6E6E73),
    textTertiary: Color(0xFFA1A1A6),
    sectionHeader: Color(0xFF3C3C43),
    divider: Color(0x1A000000),
    pillActive: Color(0xFFFFFFFF),
  );
}

extension OneUIPaletteContext on BuildContext {
  OneUIPalette get palette => Theme.of(this).brightness == Brightness.light ? OneUIPalette.light : OneUIPalette.dark;
}
