import 'package:flutter/material.dart';

import 'one_ui_scroll.dart';

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

  // --- Text ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EA4);
  static const Color textTertiary = Color(0xFF6A6A70);
  static const Color sectionHeader = Color(0xFFD4D4D8);

  // --- Radii ---
  static const double radiusPill = 34.0;
  static const double radiusCard = 26.0;

  static BorderRadius get pillBorderRadius => BorderRadius.circular(radiusPill);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);

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
