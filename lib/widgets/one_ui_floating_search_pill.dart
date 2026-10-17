import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';

class OneUIFloatingSearchPill extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;

  const OneUIFloatingSearchPill({super.key, this.hintText = 'Search', this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        return RepaintBoundary(
          child: GestureDetector(
            onTap: onTap,
            child: OneUIGlassSurface(
              borderRadius: const BorderRadius.all(Radius.circular(26)),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: is3d ? OneUITheme.navbar3dInactiveIcon : OneUITheme.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hintText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: is3d ? OneUITheme.navbar3dInactiveText : OneUITheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
