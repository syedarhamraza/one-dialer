import 'package:flutter/widgets.dart';

/// Height of `OneUIFloatingNavBar` (its own constant is private in the OneSpend copy).
const double kFloatingNavBarHeight = 60;

/// Bottom padding that keeps list content clear of the floating nav bar.
double navBarClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + kFloatingNavBarHeight + 24;
