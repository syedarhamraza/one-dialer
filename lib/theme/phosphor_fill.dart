import 'package:flutter/widgets.dart';

/// The Phosphor icons (fill weight, MIT, `assets/fonts/Phosphor-Fill.ttf`) the call screen uses.
/// The font is bundled directly: the `phosphor_flutter` package extends [IconData], which is
/// final in current Flutter. Code points are from Phosphor's own font map.
abstract final class PhosphorFill {
  static const _family = 'PhosphorFill';

  static const arrowsDownUp = IconData(0xe098, fontFamily: _family);
  static const bluetooth = IconData(0xe0da, fontFamily: _family);
  static const chatCircleText = IconData(0xe16e, fontFamily: _family);
  static const dotsThree = IconData(0xe1fe, fontFamily: _family);
  static const gitMerge = IconData(0xe280, fontFamily: _family);
  static const headphones = IconData(0xe2a6, fontFamily: _family);
  static const microphoneSlash = IconData(0xe328, fontFamily: _family);
  static const notePencil = IconData(0xe34c, fontFamily: _family);
  static const pause = IconData(0xe39e, fontFamily: _family);
  static const phone = IconData(0xe3b8, fontFamily: _family);
  static const phonePlus = IconData(0xec56, fontFamily: _family);
  static const speakerHigh = IconData(0xe44a, fontFamily: _family);
  static const videoCamera = IconData(0xe4da, fontFamily: _family);
}
