import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Swaps [child] inside a shape that morphs (pills, bars) with a *fade-through*:
/// the outgoing content is gone within the first ~third of the morph, the shape
/// resizes over the whole morph, and the incoming content fades and settles in
/// once the old one has cleared, so the two never visibly overlap.
///
/// Unlike [AnimatedSwitcher]:
/// - Only the incoming child sizes the switcher, so a shrinking morph starts
///   shrinking immediately (outgoing content keeps the size it last had and is
///   clipped by the surrounding shape).
/// - Switching back to a child that is still fading out revives that same entry
///   instead of mounting a second copy, so content carrying a [GlobalKey] (e.g. a
///   menu anchor) can toggle mid-morph safely.
///
/// Children are told apart by their [Widget.key]; give each state its own key.
class OneUIMorphSwitcher extends StatefulWidget {
  final Widget child;

  /// Where content sits while the shape resizes (e.g. [Alignment.centerRight] for
  /// a pill that grows leftwards).
  final AlignmentGeometry alignment;

  /// Animate this switcher's size to the incoming child's. Turn off when the parent
  /// sizes the shape itself.
  final bool animateSize;

  const OneUIMorphSwitcher({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
    this.animateSize = true,
  });

  /// Total morph time: the shape's resize and the incoming content's settle.
  static const Duration duration = Duration(milliseconds: 340);

  /// Outgoing content fades out within this.
  static const Duration exitDuration = Duration(milliseconds: 110);

  /// Shape resize curve: a quick start that glides into place, which reads as
  /// one surface stretching rather than two crossfading.
  static const Curve sizeCurve = Curves.easeInOutCubicEmphasized;

  /// Incoming content waits for the old content to clear, then eases in.
  static const Curve contentCurve = Interval(0.32, 1.0, curve: Curves.easeOutCubic);

  static Duration durationOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  @override
  State<OneUIMorphSwitcher> createState() => _OneUIMorphSwitcherState();
}

class _MorphEntry {
  _MorphEntry(this.widget, this.controller);

  Widget widget;
  final AnimationController controller;

  /// Keeps the content's element (and its state) when it moves between the
  /// current and outgoing slots.
  final GlobalKey slotKey = GlobalKey();

  /// Size from the last layout as the current child; outgoing content keeps it.
  Size? lastSize;

  /// Content fade and scale (0.9 → 1), applied by the compositor without rebuilding
  /// the content each frame.
  late final Animation<double> opacity = controller.drive(CurveTween(curve: OneUIMorphSwitcher.contentCurve));
  late final Animation<double> scale = opacity.drive(Tween(begin: 0.9, end: 1.0));

  Key? get key => widget.key;
}

class _OneUIMorphSwitcherState extends State<OneUIMorphSwitcher> with TickerProviderStateMixin {
  final List<_MorphEntry> _entries = [];
  late _MorphEntry _current;

  @override
  void initState() {
    super.initState();
    _current = _newEntry(widget.child, value: 1);
    _entries.add(_current);
  }

  _MorphEntry _newEntry(Widget child, {double value = 0}) =>
      _MorphEntry(child, AnimationController(vsync: this, value: value));

  @override
  void didUpdateWidget(OneUIMorphSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.child;
    if (next.key == _current.key) {
      _current.widget = next;
      return;
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final outgoing = _current;
    outgoing.controller
        .animateBack(0, duration: reduceMotion ? Duration.zero : OneUIMorphSwitcher.exitDuration, curve: Curves.easeIn)
        .whenCompleteOrCancel(() => _retire(outgoing));

    // Coming back to something still on its way out: revive it.
    final revived = _entries.where((e) => e != outgoing && e.key == next.key).firstOrNull;
    if (revived != null) {
      revived.widget = next;
      _current = revived;
    } else {
      _current = _newEntry(next);
      _entries.add(_current);
    }
    _current.controller.animateTo(1, duration: OneUIMorphSwitcher.durationOf(context));
  }

  void _retire(_MorphEntry entry) {
    if (!mounted || entry == _current || entry.controller.value > 0) return;
    setState(() => _entries.remove(entry));
    entry.controller.dispose();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  Widget _content(_MorphEntry e) {
    return FadeTransition(
      key: e.slotKey,
      opacity: e.opacity,
      child: ScaleTransition(scale: e.scale, child: e.widget),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      alignment: widget.alignment,
      clipBehavior: Clip.none,
      children: [
        for (final e in _entries)
          if (e == _current)
            _SizeTracker(key: ObjectKey(e), entry: e, child: _content(e))
          else
            // Outgoing: never sizes the switcher, never takes touches.
            Positioned.fill(
              key: ObjectKey(e),
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: OverflowBox(
                    alignment: widget.alignment,
                    minWidth: e.lastSize?.width,
                    maxWidth: e.lastSize?.width,
                    minHeight: e.lastSize?.height,
                    maxHeight: e.lastSize?.height,
                    child: _content(e),
                  ),
                ),
              ),
            ),
      ],
    );
    if (!widget.animateSize) return stack;
    return AnimatedSize(
      duration: OneUIMorphSwitcher.durationOf(context),
      curve: OneUIMorphSwitcher.sizeCurve,
      alignment: widget.alignment,
      child: stack,
    );
  }
}

/// Records its child's laid-out size on [entry].
class _SizeTracker extends SingleChildRenderObjectWidget {
  final _MorphEntry entry;

  const _SizeTracker({super.key, required this.entry, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeTracker(entry);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeTracker renderObject) => renderObject.entry = entry;
}

class _RenderSizeTracker extends RenderProxyBox {
  _RenderSizeTracker(this.entry);

  _MorphEntry entry;

  @override
  void performLayout() {
    super.performLayout();
    entry.lastSize = size;
  }
}
