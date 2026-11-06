import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import '../l10n/l10n.dart';

class OneUIFloatingSearchPill extends StatelessWidget {
  final String? hintText;
  final VoidCallback? onTap;

  const OneUIFloatingSearchPill({super.key, this.hintText, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        return RepaintBoundary(
          child: GestureDetector(
            onTap: onTap,
            child: OneUIGlassSurface(
              borderRadius: const BorderRadius.all(Radius.circular(26)),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: context.palette.textSecondary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hintText ?? context.l10n.search,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: context.palette.textSecondary),
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
