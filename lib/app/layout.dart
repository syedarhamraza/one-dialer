import 'package:flutter/widgets.dart';

/// Height of the floating nav bar and its round action (OneSpend's was 60).
const double kFloatingNavBarHeight = 58;

/// Height of a tab's top bar (under the status bar), where its round header buttons sit.
const double kHeaderBarHeight = 60;

/// Gap between the bottom floating bars and the safe area, shared so they line up.
const double kNavBarVerticalPadding = 8;

/// Bottom padding that keeps list content clear of the floating nav bar.
double navBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + kFloatingNavBarHeight + kNavBarVerticalPadding + 16;

/// Lays both engines out at the width the app is designed on (a vivo at 420 dp) and scales them
/// to the screen, so every phone shows the same proportions: a 360 dp phone smaller, a 448 dp one
/// larger. Scaling up stops at [maxScale], so tablets and open foldables get sensible sizes and
/// more room instead of giant buttons; landscape never scales.
class DesignWidth extends StatelessWidget {
  const DesignWidth({super.key, required this.child});

  static const width = 420.0;
  static const maxScale = 1.15;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width > media.size.height) return child;
    final scale = (media.size.width / width).clamp(0.0, maxScale);
    if (scale == 1) return child;
    return FittedBox(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: media.size.width / scale,
        height: media.size.height / scale,
        child: MediaQuery(
          data: media.copyWith(
            size: media.size / scale,
            // One layout dp covers this many real pixels, so images rasterize sharp.
            devicePixelRatio: media.devicePixelRatio * scale,
            padding: media.padding / scale,
            viewPadding: media.viewPadding / scale,
            viewInsets: media.viewInsets / scale,
            systemGestureInsets: media.systemGestureInsets / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}
