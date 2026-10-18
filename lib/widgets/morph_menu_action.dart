import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_floating_menu.dart';

/// A header ⋮ action whose menu grows out of the button and shrinks back into it (the glass
/// package's [GlassMenu] morph), with the glass optics off: a flat dark menu like the app's other
/// floating menus.
class MorphMenuAction extends StatelessWidget {
  const MorphMenuAction({super.key, required this.items, this.iconSize = 21, this.tooltip = 'More options'});

  final List<OneUIFloatingMenuItem> items;
  final double iconSize;
  final String tooltip;

  static const _flat = LiquidGlassSettings(
    glassColor: Color(0xF2232327),
    thickness: 0,
    blur: 20,
    chromaticAberration: 0,
    lightIntensity: 0,
    glowIntensity: 0,
    refractiveIndex: 1,
    saturation: 1,
  );

  @override
  Widget build(BuildContext context) => GlassMenu(
    semanticLabel: tooltip,
    menuWidth: 250,
    menuBorderRadius: 26,
    menuAlignment: GlassMenuAlignment.topRight,
    autoAdjustToScreen: true,
    settings: _flat,
    quality: GlassQuality.minimal,
    selectionColor: const Color(0x1FFFFFFF),
    trigger: SizedBox.square(
      dimension: 36,
      child: Icon(Icons.more_vert_rounded, size: iconSize, color: OneUITheme.textPrimary),
    ),
    items: [
      for (final item in items)
        GlassMenuItem(
          title: item.label,
          icon: item.icon == null ? null : Icon(item.icon, color: OneUITheme.textPrimary),
          titleStyle: const TextStyle(fontSize: 16, color: OneUITheme.textPrimary),
          onTap: item.onTap,
        ),
    ],
  );
}
