import 'package:dialer/core/prefs/dialer_prefs.dart';
import 'package:dialer/theme/one_ui_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final prefs = DialerPrefs.instance;
  final effects = OneUIEffectsController.instance;

  test('repeated severe frames lower an unsaved full default to reduced, saving nothing', () {
    prefs
      ..effectsSaved = false
      ..visualEffects.value = 'full';
    effects.severeFrames(OneUIEffectsController.stepDownAfter - 1);
    expect(prefs.visualEffects.value, 'full');
    effects.severeFrames(1);
    expect(prefs.visualEffects.value, 'reduced');
    expect(prefs.effectsSaved, isFalse);
  });

  test("a level the user picked is never changed", () {
    prefs
      ..effectsSaved = true
      ..visualEffects.value = 'full';
    effects.severeFrames(OneUIEffectsController.stepDownAfter * 2);
    expect(prefs.visualEffects.value, 'full');
  });
}
