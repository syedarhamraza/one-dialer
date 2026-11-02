import 'package:flutter/material.dart';

import '../core/prefs/dialer_prefs.dart';
import 'one_ui_theme.dart' show OneUIPalette;

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
///
/// Also the one place the dialer's Settings › "Reduce visual effects" is read: glass
/// widgets ask [isFull] / [isOff] and listen here to switch live.
class OneUIEffectsController extends ChangeNotifier {
  OneUIEffectsController._() {
    DialerPrefs.instance.visualEffects.addListener(notifyListeners);
    DialerPrefs.instance.callEffects.addListener(notifyListeners);
    DialerPrefs.instance.glassDark.addListener(notifyListeners);
    DialerPrefs.instance.callGlass.addListener(notifyListeners);
  }

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

  /// `full`, `reduced` or `off` (see [DialerPrefs.visualEffects]).
  String get level => DialerPrefs.instance.visualEffects.value;

  /// The call screen's own level (Settings › "Call screen effects"): `full`, `reduced` or `off`.
  String get callLevel => DialerPrefs.instance.callEffects.value;

  /// Full effects: the call glass (cached glow artwork over the blur), the header's
  /// progressive blur, and separate backdrop reads where one glass must blur another.
  bool get isFull => level == 'full';

  /// The main app's dark call glass style at full effects (Settings › "Dark mode edge glow"):
  /// `classic`, `soft` or `bold`. Light mode has one look (see `mainGlass`).
  String get glassStyle => DialerPrefs.instance.glassDark.value;

  /// The call screen's edge glow style (Settings › "Call screen edge glow").
  String get callGlassStyle => DialerPrefs.instance.callGlass.value;

  /// Effects off: solid One UI fills, no blur anywhere.
  bool get isOff => level == 'off';

  /// Below full effects, glass is OneSpend's flat One UI fill (light mode: flat grey, with no
  /// shadows): translucent over a blur when reduced (every blur on a page sharing one backdrop
  /// read), solid when off.
  Color oneUIFill({required bool light}) {
    final fill = light ? OneUIPalette.lightFlat.pill.withValues(alpha: .8) : floatingColor;
    return isOff ? fill.withValues(alpha: 1) : fill;
  }

  Color get activePillColor => const Color(0xFF3E3E42);
  Gradient? get activePillGradient => null;
  Gradient? get activePillRimGradient => null;

  Color resolveCardBackground() => cardColor;
}
