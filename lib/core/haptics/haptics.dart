import 'package:flutter/services.dart';

/// Same API as OneSpend's `Haptics` (so its widgets copy verbatim), on Flutter's
/// platform haptics, which follow the system "Touch feedback" setting.
abstract final class Haptics {
  static void select() => HapticFeedback.selectionClick();
  static void tap() => HapticFeedback.lightImpact();
  static void confirm() => HapticFeedback.mediumImpact();
  static void longPress() => HapticFeedback.heavyImpact();
  static void warn() => HapticFeedback.vibrate();
}
