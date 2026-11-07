import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

import '../core/prefs/dialer_prefs.dart';

/// Height of the floating nav bar and its round action (OneSpend's was 60), before
/// Settings › Display size's nav bar size ([navBarScale]).
const double kFloatingNavBarHeight = 58;

/// Height of a tab's top bar (under the status bar), where its round header buttons sit, before
/// Settings › Display size's top buttons size; read it through [headerBarHeight].
const double kHeaderBarHeight = 60;

/// Settings › Display size › Navigation bar: how much bigger the nav bar and its round buttons draw.
/// Divided by the App size, which scales everything under `DesignWidth`: the App slider is for the
/// pages, so the bar keeps its own size.
double navBarScale(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<_ComponentSizes>();
  return DialerPrefs.instance.navBarSize.value / DialerPrefs.instance.displaySize.value;
}

/// Settings › Display size › Top buttons: how much bigger the Calls and Contacts header pills draw,
/// apart from the App size like [navBarScale].
double headerScale(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<_ComponentSizes>();
  return DialerPrefs.instance.headerSize.value / DialerPrefs.instance.displaySize.value;
}

double headerBarHeight(BuildContext context) => kHeaderBarHeight * headerScale(context);

/// Draws [child] [scale] times bigger, keeping it centred and as wide as its parent: it's laid out
/// that much narrower, then scaled up. Its height is the child's (an app bar title has no bound).
Widget scaledToWidth(double scale, Widget child) => scale == 1
    ? child
    : LayoutBuilder(
        builder: (context, box) => SizedBox(
          width: box.maxWidth,
          child: OverflowBox(
            fit: OverflowBoxFit.deferToChild,
            minWidth: box.maxWidth / scale,
            maxWidth: box.maxWidth / scale,
            child: Transform.scale(scale: scale, child: child),
          ),
        ),
      );

/// Rebuilds whoever reads [navBarScale] or [headerScale] when the user changes them.
class _ComponentSizes extends InheritedNotifier<Listenable> {
  const _ComponentSizes({required super.notifier, required super.child});
}

final _componentSizes = Listenable.merge([
  DialerPrefs.instance.navBarSize,
  DialerPrefs.instance.headerSize,
  DialerPrefs.instance.displaySize,
]);

/// Gap between the bottom floating bars and the safe area, shared so they line up.
const double kNavBarVerticalPadding = 8;

/// Bottom padding that keeps list content clear of the floating nav bar.
double navBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + kFloatingNavBarHeight * navBarScale(context) + kNavBarVerticalPadding + 16;

/// Lays both engines out at the width the app is designed on (a vivo at 420 dp) and scales them
/// to the screen, so every phone shows the same proportions: a 360 dp phone smaller, a 448 dp one
/// larger. Scaling up stops at [maxScale], so tablets and open foldables get sensible sizes and
/// more room instead of giant buttons; landscape never scales. Settings › Display size
/// ([DialerPrefs.displaySize]) multiplies the result.
class DesignWidth extends StatelessWidget {
  const DesignWidth({super.key, required this.child});

  static const width = 420.0;
  static const maxScale = 1.15;

  final Widget child;

  @override
  Widget build(BuildContext context) => _ComponentSizes(
    notifier: _componentSizes,
    child: ValueListenableBuilder(valueListenable: DialerPrefs.instance.displaySize, builder: _scaled),
  );

  Widget _scaled(BuildContext context, double size, Widget? _) {
    final media = MediaQuery.of(context);
    // A window not sized yet (0×0, seen on vivo in the background) would scale by 0/0 = NaN.
    if (media.size.isEmpty || media.size.width > media.size.height) return child;
    final scale = (media.size.width / width).clamp(0.0, maxScale) * size;
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
