import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import '../core/haptics/haptics.dart';

/// Samsung One UI segmented control: a capsule in the card surface colour (matching the
/// cards around it) with an animated `surfacePillActive` thumb behind the selected segment
/// (e.g. 7 days · 30 days · 3 months).
class OneUISegmentedPills<T> extends StatelessWidget {
  final List<({T value, String label})> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Compact variant for use inside a card: 34dp tall on a `surfacePill` capsule.
  final bool dense;

  const OneUISegmentedPills({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = segments.indexWhere((s) => s.value == selected).clamp(0, segments.length - 1);
    return Container(
      height: dense ? 34 : 44,
      padding: EdgeInsets.all(dense ? 3 : 4),
      decoration: dense
          ? BoxDecoration(color: context.palette.pill, borderRadius: OneUITheme.pillBorderRadius)
          : BoxDecoration(
              color: OneUITheme.cardColor,
              borderRadius: OneUITheme.pillBorderRadius,
              border: OneUITheme.cardBorder,
              boxShadow: OneUITheme.cardShadow,
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: segmentWidth * selectedIndex,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.palette.pillActive,
                    borderRadius: OneUITheme.pillBorderRadius,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == selectedIndex,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i == selectedIndex) return;
                            Haptics.select();
                            onChanged(segments[i].value);
                          },
                          child: Center(
                            child: Text(
                              segments[i].label,
                              style: TextStyle(
                                fontSize: dense ? 12.5 : 13.5,
                                fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500,
                                color: i == selectedIndex ? context.palette.textPrimary : context.palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
