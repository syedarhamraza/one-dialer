import 'package:flutter/material.dart';

import '../features/in_call/call_controls.dart';

/// The keypad sheet's motion, shared by pages that rise like it: up on a soft spring that
/// settles without a bounce, down quickly, speeding up as it goes (Material's emphasized
/// accelerate).
final kSheetRise = GlassSpringCurve(
  SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: .85),
  const Duration(milliseconds: 450),
);
const kSheetDrop = Cubic(0.3, 0, 0.8, 0.15);

/// A page that slides up from the bottom like the keypad sheet, and back down when closed.
class RisePageRoute<T> extends PageRoute<T> {
  RisePageRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  // See-through, so the page below shows above it while it slides. Kept see-through once
  // open too: an opaque page stops the page below painting, and bringing it back cost a
  // ~200 ms frame as the page started down.
  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return FadeTransition(opacity: animation, child: child);
    return SlideTransition(
      position: CurvedAnimation(
        parent: animation,
        curve: kSheetRise,
        reverseCurve: kSheetDrop.flipped,
      ).drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
      child: child,
    );
  }
}
