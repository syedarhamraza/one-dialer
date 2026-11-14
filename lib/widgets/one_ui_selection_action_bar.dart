import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import '../core/haptics/haptics.dart';
import '../l10n/l10n.dart';

/// Bottom multi-selection floating action bar.
/// Streamlined according to user instructions:
/// - Primary bar actions: Share, Delete, More (...)
/// - Secondary options (Move, Lock/Pause) are accessible via the three-dots More menu.
class OneUISelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onMove;
  final VoidCallback? onToggleLock;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMore;
  final GlobalKey? moreButtonKey;

  /// Anchors the Share menu (Share as PDF / Share as text).
  final GlobalKey? shareButtonKey;

  /// Render only the action row, for hosting inside the tab shell's nav bar so the
  /// bar morphs into these actions instead of being replaced (see HomeShellScope).
  final bool docked;

  const OneUISelectionActionBar({
    super.key,
    required this.selectedCount,
    this.onMove,
    this.onToggleLock,
    required this.onShare,
    required this.onDelete,
    required this.onMore,
    this.moreButtonKey,
    this.shareButtonKey,
    this.docked = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        if (docked) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: _buildRow(context));
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: OneUIGlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(34)),
                elevation: OneUIGlassElevation.navbar,
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: _buildRow(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context) {
    final hasSelection = selectedCount > 0;
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Share
          _buildActionItem(
            context,
            key: shareButtonKey,
            icon: Icons.share_outlined,
            label: context.l10n.share,
            isEnabled: hasSelection,
            onTap: onShare,
          ),

          // 2. Delete
          _buildActionItem(
            context,
            icon: Icons.delete_outline_rounded,
            label: context.l10n.delete,
            isEnabled: hasSelection,
            color: hasSelection ? OneUITheme.accentRed : null,
            onTap: onDelete,
          ),

          // 3. More (...)
          _buildActionItem(
            context,
            key: moreButtonKey,
            icon: Icons.more_vert_rounded,
            label: context.l10n.more,
            isEnabled: hasSelection,
            onTap: onMore,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = isEnabled
        ? (color ?? context.palette.textPrimary)
        : context.palette.textSecondary.withValues(alpha: 0.4);

    return InkWell(
      key: key,
      onTap: isEnabled
          ? () {
              Haptics.tap();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: itemColor),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: itemColor),
            ),
          ],
        ),
      ),
    );
  }
}
