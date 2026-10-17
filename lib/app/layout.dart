import 'package:flutter/widgets.dart';

/// Height of every bottom floating bar: both nav bar styles, the selection bar, the
/// contact page action bar and the Cancel | Save pill (OneSpend's 60).
const double kFloatingNavBarHeight = 60;

/// Gap between the bottom floating bars and the safe area, shared so they line up.
const double kNavBarVerticalPadding = 8;

/// Bottom padding that keeps list content clear of the floating nav bar.
double navBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + kFloatingNavBarHeight + kNavBarVerticalPadding + 16;
