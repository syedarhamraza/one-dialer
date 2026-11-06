import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_radio.dart';
import 'call_glyph.dart';

/// One choice of a [ShowcasePicker]: what the phone shows with it, under a label.
class ShowcaseOption {
  const ShowcaseOption({required this.value, required this.label, required this.preview});

  final String value;
  final String label;

  /// What the phone shows with it, usually a [PhonePreview].
  final Widget preview;
}

/// ColorOS 17's illustrated settings choice ("Incoming call reminders"): a flat grey card with
/// the options side by side, each a little phone showing it over its label and a radio. Tapping
/// anywhere on an option picks it. [footnote] is the grey note under the card.
class ShowcasePicker extends StatelessWidget {
  const ShowcasePicker({super.key, required this.value, required this.options, required this.onPick, this.footnote});

  final ValueListenable<String> value;
  final List<ShowcaseOption> options;
  final ValueChanged<String> onPick;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final accent = OneUITheme.accentBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 20),
            decoration: ShapeDecoration(color: context.palette.card, shape: OneUITheme.cardShape),
            child: ValueListenableBuilder(
              valueListenable: value,
              builder: (context, picked, _) => Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: Semantics(
                        selected: o.value == picked,
                        button: true,
                        label: o.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (o.value == picked) return;
                            Haptics.tap();
                            onPick(o.value);
                          },
                          child: Column(
                            children: [
                              o.preview,
                              const SizedBox(height: 16),
                              Text(
                                o.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: o.value == picked ? accent : context.palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OneUIRadio(isSelected: o.value == picked, selectedColor: accent),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (footnote case final note?)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(note, style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary)),
            ),
        ],
      ),
    );
  }
}

/// A small phone with a blue-to-teal screen and a caller's name and number as grey bars;
/// [child] draws the choice on top (a banner, the call buttons).
class PhonePreview extends StatelessWidget {
  const PhonePreview({super.key, required this.child, this.showCaller = true});

  final Widget child;
  final bool showCaller;

  static const width = 112.0, height = 232.0;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: const ShapeDecoration(
          color: Color(0xFF3A3A3C),
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(17),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B6FB0), Color(0xFF2E8A94)],
              ),
            ),
            child: Stack(
              children: [
                if (showCaller)
                  const Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        _Bar(46, 9, .55),
                        SizedBox(height: 8),
                        _Bar(70, 3, .4),
                        SizedBox(height: 8),
                        _Bar(18, 4, .4),
                      ],
                    ),
                  ),
                Positioned.fill(child: child),
                // The gesture bar.
                const Positioned(left: 0, right: 0, bottom: 6, child: Center(child: _Bar(36, 2, .4))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.width, this.height, this.opacity);

  final double width, height, opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(height),
    ),
  );
}

/// A round call button in a [PhonePreview].
class PreviewCallButton extends StatelessWidget {
  const PreviewCallButton({super.key, required this.color, required this.icon, this.size = 20});

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    // A light button gets a dark glyph, as ColorOS's white 1-button ball.
    child: CallGlyph(icon, size: size * .55, color: color.computeLuminance() > .5 ? const Color(0xFF2C2C2E) : Colors.white),
  );
}
