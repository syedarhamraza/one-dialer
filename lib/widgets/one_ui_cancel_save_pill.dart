import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import '../core/haptics/haptics.dart';

/// Standardized Samsung One UI 9 Floating Stadium "Cancel | Save" Pill
/// Matches reference screenshots with translucent smoked glass backdrop,
/// optional 3D specular highlight & shadows, and tactile haptic response.
class OneUIFloatingCancelSavePill extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final bool canSave;
  final String cancelLabel;
  final String saveLabel;

  /// Render only the Cancel | Save row, for hosting inside a bar that morphs
  /// between it and other content (see OneUIMorphSwitcher).
  final bool docked;

  const OneUIFloatingCancelSavePill({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.canSave = true,
    this.cancelLabel = 'Cancel',
    this.saveLabel = 'Save',
    this.docked = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        if (docked) return _buildRow(context);

        return Center(
          child: OneUIGlassSurface(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            elevation: OneUIGlassElevation.navbar,
            height: 52,
            child: _buildRow(context),
          ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cancel Button
          InkWell(
            onTap: () {
              Haptics.tap();
              onCancel();
            },
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
          ),

          // 1px Subtle Vertical Divider
          Container(width: 1, height: 20, color: context.palette.divider),

          // Save Button
          InkWell(
            onTap: canSave
                ? () {
                    Haptics.confirm();
                    onSave?.call();
                  }
                : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                saveLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: canSave ? context.palette.textPrimary : const Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
