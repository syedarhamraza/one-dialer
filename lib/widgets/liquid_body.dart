import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/prefs/dialer_prefs.dart';
import '../theme/one_ui_theme.dart';

/// Floating chrome's body at Settings › "Glass style" › Liquid glass
/// (`OneUIEffectsController.isLiquid`): the glass package's container in the
/// Glass effect quality picked in Settings, squircle-ended with [radius].
Widget liquidBody(
  BuildContext context, {
  required double radius,
  double? width,
  double? height,
  EdgeInsetsGeometry? padding,
  AlignmentGeometry? alignment,
  Widget child = const SizedBox.expand(),
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return glassPixelRatio(
    context,
    GlassContainer(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: dark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light,
      quality: liquidQuality(),
      useOwnLayer: true,
      // The content keeps DesignWidth's ratio, which images rasterize at.
      child: MediaQuery(data: MediaQuery.of(context), child: child),
    ),
  );
}

/// The screen's real pixel ratio for the glass package under `DesignWidth`: the package places its
/// shader with the full transform to the screen (which already holds DesignWidth's scale) times the
/// MediaQuery ratio, so DesignWidth's scaled ratio applied the scale twice and pulled every glass
/// shape toward the top-left on phones not 420 dp wide (the Galaxy S25).
Widget glassPixelRatio(BuildContext context, Widget child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(devicePixelRatio: View.of(context).devicePixelRatio),
  child: child,
);

/// Settings › "Glass effect": `premium`, `standard`, or `auto`, which asks for premium and lets
/// [LiquidQualityScope] cap it to what the phone keeps up with.
GlassQuality liquidQuality() => switch (DialerPrefs.instance.navGlass.value) {
  'standard' => GlassQuality.standard,
  _ => GlassQuality.premium,
};

/// Glass effect › Automatic: the glass package times the first frames and keeps watching (heat
/// throttling), capping every liquid surface between full refraction and Light. It first drops only
/// the iOS 27 frost (`frostStep`), and never below Light: minimal glass is a plain frosted tint,
/// which Glass style › Frosted already is. Present only while it's picked; the [GlobalKey] keeps the
/// app's state when it comes and goes.
class LiquidQualityScope extends StatefulWidget {
  const LiquidQualityScope({super.key, required this.child});

  final Widget child;

  @override
  State<LiquidQualityScope> createState() => _LiquidQualityScopeState();
}

class _LiquidQualityScopeState extends State<LiquidQualityScope> {
  final _app = GlobalKey();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: OneUIEffectsController.instance,
    builder: (context, _) {
      final app = KeyedSubtree(key: _app, child: widget.child);
      if (!OneUIEffectsController.instance.isLiquid || DialerPrefs.instance.navGlass.value != 'auto') return app;
      return GlassAdaptiveScope(minQuality: GlassQuality.standard, frostStep: true, child: app);
    },
  );
}
