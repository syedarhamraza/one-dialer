import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import '../core/haptics/haptics.dart';
import '../l10n/l10n.dart';

/// Frosted floating capsule shared by the selection header pills.
class _SelectionHeaderCapsule extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _SelectionHeaderCapsule({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return OneUIGlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      height: 42,
      padding: padding,
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Selection-mode header pill (leading): a select-all circle plus the selected count.
/// Pass to `OneUICollapsibleHeaderDelegate.selectionLeading`.
class OneUISelectionCountPill extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onToggleSelectAll;

  const OneUISelectionCountPill({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggleSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount > 0 && selectedCount == totalCount;
    return Semantics(
      button: true,
      label: allSelected ? context.l10n.deselectAll : context.l10n.selectAll,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.select();
          onToggleSelectAll();
        },
        child: _SelectionHeaderCapsule(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allSelected ? const Color(0xFF2C69FF) : Colors.transparent,
                  border: Border.all(
                    color: allSelected ? const Color(0xFF2C69FF) : context.palette.textPrimary.withValues(alpha: 0.55),
                    width: 2.0,
                  ),
                ),
                child: allSelected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
              ),
              const SizedBox(width: 8),
              Text(
                '$selectedCount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selection-mode header pill (trailing): "Cancel" exits selection mode.
/// Pass to `OneUICollapsibleHeaderDelegate.selectionTrailing`.
class OneUISelectionCancelPill extends StatelessWidget {
  final VoidCallback onCancel;

  const OneUISelectionCancelPill({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.tap();
        onCancel();
      },
      child: _SelectionHeaderCapsule(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          context.l10n.cancel,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
