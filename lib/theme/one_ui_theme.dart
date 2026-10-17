import 'package:flutter/material.dart';

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

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: surfacePitch,
    primaryColor: accentBlue,
    canvasColor: surfacePitch,
    cardColor: surfaceCard,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      surface: surfacePitch,
      primary: accentBlue,
      secondary: accentGreen,
      error: accentRed,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(color: Color(0x1AFFFFFF), thickness: 0.8),
  );

  /// Pass to `MaterialApp.scrollBehavior`.
  static const ScrollBehavior scrollBehavior = OneUIScrollBehavior();
}
