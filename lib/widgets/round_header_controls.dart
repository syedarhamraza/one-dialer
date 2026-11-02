import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../features/in_call/call_controls.dart';
import '../theme/one_ui_theme.dart';
import 'call_glass.dart';
import '../l10n/l10n.dart';

/// A header icon on its own round grey background (search, menu, cancel).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CallGlass(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        // Exactly 48: Material would pad a smaller one to a 48 dp tap target anyway.
        style: IconButton.styleFrom(
          foregroundColor: context.palette.textPrimary,
          fixedSize: const Size.square(48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 24),
      ),
    );
  }
}

/// Segmented tabs in a grey pill (All | Missed), the selected one on a lighter thumb
/// that slides between them.
class FilterTabs extends StatefulWidget {
  const FilterTabs({super.key, required this.labels, required this.index, required this.onChanged, this.bare = false});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Without its own glass body, for a parent that draws one (the Calls header morph).
  final bool bare;

  /// The thumb's spring; the floating menu's highlight moves on it too.
  static Curve get thumbSpring => _FilterTabsState.thumbSpring;

  /// The pill's size for [count] tabs.
  static Size sizeFor(int count) =>
      Size(count * _FilterTabsState._tabWidth + 2 * _FilterTabsState._inset, _FilterTabsState._height);

  @override
  State<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<FilterTabs> {
  late int _index = widget.index;

  @override
  void didUpdateWidget(FilterTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) _index = widget.index;
  }

  /// Moves the highlight this frame and hands the (heavier) list change to the next,
  /// so the slide starts without waiting on the rebuild.
  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(i));
  }

  static const double _tabWidth = 74;
  static const double _height = 48; // as tall as the round buttons
  static const double _inset = 4;

  /// Springier than the call screen's toggle: it swings past the tab and settles back.
  static final thumbSpring = GlassSpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 260, ratio: .6),
    const Duration(milliseconds: 600),
  );

  static const _thumb = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(_height / 2 - _inset)),
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      child: SizedBox(
        width: _tabWidth * widget.labels.length,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Slid by a paint-only transform on its own layer, so the move doesn't
            // re-lay out the pill or repaint the blur behind it each frame.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _tabWidth,
              child: RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _index * _tabWidth),
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                  curve: thumbSpring,
                  builder: (context, x, child) => Transform.translate(offset: Offset(x, 0), child: child),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: context.palette.isLight ? const Color(0x14000000) : const Color(0x3DFFFFFF),
                      shape: _thumb,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < widget.labels.length; i++)
                  Semantics(
                    button: true,
                    selected: i == _index,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _select(i),
                      child: SizedBox(
                        width: _tabWidth,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: i == _index ? context.palette.textPrimary : context.palette.textSecondary,
                            ),
                            child: Text(widget.labels[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return widget.bare ? content : CallGlass(radius: _height / 2, child: content);
  }
}

/// Select all, inside the lead pill: a check circle (filled blue when every row is
/// selected) and "All". The count itself is the big "N selected" title.
class SelectAllCount extends StatelessWidget {
  const SelectAllCount({super.key, required this.allSelected, required this.onTap});

  final bool allSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: allSelected ? context.l10n.deselectAll : context.l10n.selectAll,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allSelected ? const Color(0xFF2C69FF) : Colors.transparent,
                border: Border.all(
                  color: allSelected ? const Color(0xFF2C69FF) : context.palette.textPrimary.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
              child: allSelected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.all,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: context.palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far a tab's big title has gone under its header bar (0 to 1), fed from the list's
/// scroll offset; [titleTop] is where the title's text starts below the bar.
class TitleCollapse extends ValueNotifier<double> {
  TitleCollapse({required this.titleTop}) : super(0);

  final double titleTop;

  /// The title's travel under the bar: the big one fades over the first half, the small one
  /// over the second, so the two never show at once.
  static const double _span = 44;

  /// For a `NotificationListener<ScrollUpdateNotification>` around the tab's list.
  bool track(ScrollUpdateNotification n) {
    if (n.depth == 0) value = ((n.metrics.pixels - titleTop) / _span).clamp(0.0, 1.0);
    return false;
  }
}

/// The small title that takes the big one's place at the left of the header bar
/// (ColorOS), fading and rising in as [collapse] goes from 0 to 1.
class HeaderTitle extends StatelessWidget {
  const HeaderTitle({super.key, required this.collapse, required this.text, this.hidden = false});

  final TitleCollapse collapse;
  final String text;

  /// While the header uses its left side (selecting, typing).
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: ValueListenableBuilder(
            valueListenable: collapse,
            builder: (context, t, _) {
              final shown = hidden ? 0.0 : (t * 2 - 1).clamp(0.0, 1.0);
              // Not there at all while hidden, so screen readers don't read it twice.
              if (shown == 0) return const SizedBox.shrink();
              return Transform.translate(
                offset: Offset(0, (1 - shown) * 10),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: context.palette.textPrimary.withValues(alpha: shown),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The big title fading out as [collapse] rises, by its colour (no Opacity layer).
class BigTitle extends StatelessWidget {
  const BigTitle({super.key, required this.collapse, required this.text});

  final TitleCollapse collapse;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: collapse,
      builder: (context, t, _) => Text(
        text,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: context.palette.textPrimary.withValues(alpha: (1 - t * 2).clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}
