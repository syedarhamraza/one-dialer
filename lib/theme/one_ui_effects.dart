import 'package:flutter/material.dart';

/// Elevation of a [OneUIGlassSurface]; picks its shadow.
enum OneUIGlassElevation {
  /// Pills, circular buttons, search capsules, action bars, menus.
  floating,

  /// The bottom tab bar (its shadow also lifts it over content scrolling under it).
  navbar,

  /// Bottom sheets and modals.
  modal,
}

/// Stand-in for OneSpend's appearance controller so its widgets can be copied verbatim.
/// Always OneSpend's default **flat** look (the values are copied from its flat branch);
/// the 3D option and the other appearance settings don't exist in the dialer.
class OneUIEffectsController extends ChangeNotifier {
  OneUIEffectsController._();

  static final OneUIEffectsController instance = OneUIEffectsController._();

  bool get floating3dEffect => false;

  Color get cardColor => const Color(0xFF1C1C1E);
  Border? get cardBorder => null;
  List<BoxShadow> get cardShadow => const [];

  Color get floatingColor => const Color(0xB3222226); // ~70% flat translucent
  Gradient? get floatingGradient => null;
  Border? get floatingBorder => null;
  Gradient? get floatingRimGradient => null;

  static final List<BoxShadow> _floatingShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 2)),
  ];
  static final List<BoxShadow> _navbarShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, -1)),
  ];

  List<BoxShadow> get floatingShadow => _floatingShadow;
  List<BoxShadow> get navbarShadow => _navbarShadow;
  List<BoxShadow> get fabShadow => const [];
  List<BoxShadow> get modalShadow => const [];

  List<BoxShadow> glassShadow(OneUIGlassElevation elevation) => switch (elevation) {
    OneUIGlassElevation.floating => floatingShadow,
    OneUIGlassElevation.navbar => navbarShadow,
    OneUIGlassElevation.modal => modalShadow,
  };

  /// Flat fill for sheets and modals (denser than pills so long content stays legible).
  Color get modalColor => const Color(0xC4202024);
  Gradient? get modalGradient => null;

  double get blurSigma => 20.0;

  Color get activePillColor => const Color(0xFF3E3E42);
  Gradient? get activePillGradient => null;
  Gradient? get activePillRimGradient => null;

  Color resolveCardBackground() => cardColor;
}
