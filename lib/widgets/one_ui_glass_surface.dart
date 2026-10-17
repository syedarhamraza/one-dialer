import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// Floating "glass" chrome (nav bar, floating buttons), ported from OneSpend's
/// `one_ui_glass_surface.dart` in its default flat style: translucent fill, background
/// blur and a soft ambient shadow. OneSpend's 3D style is not ported.
class OneUIGlassSurface extends StatelessWidget {
  const OneUIGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(OneUITheme.radiusPill)),
    this.navbar = false,
    this.height,
    this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// The bottom nav bar casts its shadow upwards, over content scrolling under it.
  final bool navbar;
  final double? height;
  final EdgeInsetsGeometry? padding;

  static const Color _fill = Color(0xB3222226); // ~70% translucent
  static const double _blurSigma = 20;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          navbar
              ? BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, -1))
              : BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(color: _fill, borderRadius: borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}
