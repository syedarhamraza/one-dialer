import 'package:flutter/widgets.dart';

/// Height of the liquid glass nav bar pill (`GlassTabBar.bottom` in `MainShell`).
const double kFloatingNavBarHeight = 64;

/// Space the glass nav bar keeps above and below its pill.
const double kNavBarVerticalPadding = 8;

/// Bottom padding that keeps list content clear of the floating nav bar.
double navBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + kFloatingNavBarHeight + 2 * kNavBarVerticalPadding + 8;
