import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's scrolling: every page bounces at its ends, even with nothing to scroll (like
/// ColorOS), but more gently than Flutter's iOS bounce: the pull follows the finger less and
/// a fling's overshoot is shorter.
///
/// With [headerSnap] (the distance a big header collapses, see [bigHeader]), a page never
/// comes to rest with its header half collapsed. When the finger lifts, the fling turns into
/// a spring that carries on, in the same motion:
/// * inside the header, the way it was flicked (or to the nearer end if it wasn't);
/// * coming back up from the list, to the small top bar, never past it: only a pull from
///   the top opens the big header again.
class OneUIScrollPhysics extends BouncingScrollPhysics {
  /// How far a big header collapses: `OneUICollapsibleHeaderDelegate`'s default expanded
  /// height (270) minus its collapsed height (92).
  static const double bigHeaderCollapse = 270.0 - 92.0;

  /// For pages whose `CustomScrollView` starts with a big header.
  static const OneUIScrollPhysics bigHeader = OneUIScrollPhysics(headerSnap: bigHeaderCollapse);

  /// Critically damped, so a snap settles without overshooting.
  static final SpringDescription _snapSpring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 150,
    ratio: 1.0,
  );

  /// Stiffer than Flutter's bounce spring (100), so a fling overshoots less.
  static final SpringDescription _bounceSpring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 150,
    ratio: 1.1,
  );

  /// The scroll range at the top of the page that a header snaps across, if any.
  final double? headerSnap;

  const OneUIScrollPhysics({super.parent, this.headerSnap});

  @override
  OneUIScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      OneUIScrollPhysics(parent: buildParent(ancestor), headerSnap: headerSnap);

  // Short and empty pages bounce too. Sideways scrollers (text fields) don't: a swipe on a
  // field whose text fits would rubber-band the text.
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) =>
      position.axis == Axis.vertical || super.shouldAcceptUserOffset(position);

  // Flutter's default is 0.52 * (1 - f)²: the pull past an end follows the finger less.
  @override
  double frictionFactor(double overscrollFraction) => 0.32 * math.pow(1 - overscrollFraction, 2);

  @override
  SpringDescription get spring => _bounceSpring;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final bounce = super.createBallisticSimulation(position, velocity);
    final snap = headerSnap;
    if (snap == null || position.outOfRange) return bounce;
    final tolerance = toleranceFor(position);
    final pixels = position.pixels;
    final flung = velocity.abs() >= tolerance.velocity;

    // Where the page would come to rest, and how far the header can collapse here.
    final end = (flung && bounce != null ? bounce.x(10) : pixels).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final reach = math.min(snap, position.maxScrollExtent);
    if (reach > 1) {
      final double? target;
      if (pixels >= reach - 0.5) {
        // Coming back up from the list: like One UI, a swipe stops at the small top
        // bar. Only a pull from the top (a drag, not a fling) opens the big header.
        target = velocity < 0 && end < reach - 0.5 ? reach : null;
      } else if (end > 0.5 && end < reach - 0.5 || !flung) {
        // Inside the header: a flick goes the way it was flicked; letting go still
        // settles on the nearer end.
        target = !flung ? (pixels < reach / 2 ? 0.0 : reach) : (velocity < 0 ? 0.0 : reach);
      } else {
        target = null;
      }
      if (target != null && (target - pixels).abs() > 0.5) {
        return ScrollSpringSimulation(_snapSpring, pixels, target, velocity, tolerance: tolerance);
      }
    }
    return bounce;
  }
}

/// For fitted content that must hold still (the keypad sheet, panels inside a page): clamps,
/// and takes drags only when the content overflows. It drops the app-wide
/// [OneUIScrollPhysics] parent, whose always-accept would let a held key drag the sheet.
class HoldStillScrollPhysics extends ClampingScrollPhysics {
  const HoldStillScrollPhysics();

  @override
  HoldStillScrollPhysics applyTo(ScrollPhysics? ancestor) => const HoldStillScrollPhysics();
}

/// Wraps big-header pages (the home tabs, in `HomeScreen`) so pulling down at the top
/// doesn't stretch them.
/// The big header is the top of those pages, and the stretch drew the glass cards in an
/// offscreen layer, which made their glow flare while pulling. The bottom still stretches.
class OneUINoTopStretch extends StatelessWidget {
  final Widget child;

  const OneUINoTopStretch({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        if (notification.leading) notification.disallowIndicator();
        return false;
      },
      child: child,
    );
  }
}

/// The app's scroll behaviour: [OneUIScrollPhysics] everywhere. Set on `MaterialApp`;
/// screens that set `physics` use [OneUIScrollPhysics] too ([OneUIScrollPhysics.bigHeader]
/// under a big header). Fitted content that must not move (the keypad sheet, the call
/// screen) uses [HoldStillScrollPhysics].
class OneUIScrollBehavior extends MaterialScrollBehavior {
  const OneUIScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const OneUIScrollPhysics();
}
