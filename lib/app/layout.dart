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
