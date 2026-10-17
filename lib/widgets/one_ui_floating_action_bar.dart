import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import 'one_ui_morph_switcher.dart';
import '../core/haptics/haptics.dart';

class OneUIFloatingActionBarItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isEnabled;

  /// Anchors a menu opened from this action (see OneUIFloatingMenu.show).
  final GlobalKey? key;

  const OneUIFloatingActionBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isEnabled = true,
    this.key,
  });
}

class OneUIFloatingActionBar extends StatelessWidget {
  final List<OneUIFloatingActionBarItem> items;

  /// Render only the action row, for hosting inside the tab shell's nav bar so the
  /// bar morphs into these actions instead of being replaced (see HomeShellScope).
  final bool docked;

  const OneUIFloatingActionBar({super.key, required this.items, this.docked = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        if (docked) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: _buildRow());
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RepaintBoundary(
              child: OneUIGlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(34)),
                elevation: OneUIGlassElevation.navbar,
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: _buildRow(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow() {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((item) {
          final itemColor = item.isEnabled
              ? (item.color ?? OneUITheme.textPrimary)
              : OneUITheme.textSecondary.withValues(alpha: 0.35);

          return InkWell(
            key: item.key,
            onTap: item.isEnabled
                ? () {
                    Haptics.tap();
                    item.onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(26),
            splashColor: item.isEnabled ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            highlightColor: item.isEnabled ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
            child: SizedBox(
              width: 68,
              // Cross-fades when an action changes in place (e.g. Renew → Undo).
              child: OneUIMorphSwitcher(
                animateSize: false,
                child: Column(
                  key: ValueKey(item.label),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 21, color: itemColor),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: itemColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
