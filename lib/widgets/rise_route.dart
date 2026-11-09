import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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

  /// Android's Remove animations: no slide at all.
  bool get _still => navigator != null && MediaQuery.maybeDisableAnimationsOf(navigator!.context) == true;

  @override
  Duration get transitionDuration => _still ? Duration.zero : const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => _still ? Duration.zero : const Duration(milliseconds: 240);

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
      // Its glass pills share one backdrop read, like pages on the theme's slide.
      BackdropGroup(child: GlassBackdropGroup(child: builder(context)));

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    child = _BackGesture(route: this, child: child);
    if (MediaQuery.disableAnimationsOf(context)) return FadeTransition(opacity: animation, child: child);
    return SlideTransition(
      // Linear during Android's back swipe, so the page follows the finger down.
      position:
          (popGestureInProgress
                  ? animation
                  : CurvedAnimation(parent: animation, curve: kSheetRise, reverseCurve: kSheetDrop.flipped))
              .drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
      child: child,
    );
  }
}

/// Hands Android's predictive back swipe to [route], as the theme's page transition does
/// for Material pages; without it the page only drops once the swipe is released.
class _BackGesture extends StatefulWidget {
  const _BackGesture({required this.route, required this.child});
  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_BackGesture> createState() => _BackGestureState();
}

class _BackGestureState extends State<_BackGesture> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = widget.route;
    if (backEvent.isButtonEvent || !route.isCurrent || !route.popGestureEnabled) return false;
    route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) =>
      widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);

  @override
  void handleCancelBackGesture() => widget.route.handleCancelBackGesture();

  @override
  void handleCommitBackGesture() => widget.route.handleCommitBackGesture();

  @override
  Widget build(BuildContext context) => widget.child;
}
