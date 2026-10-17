import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The contact's photo, or Samsung's soft gradient circle with up to two initials
/// ("Aamir Zaman" → "AZ"). Unsaved numbers and hidden callers get a person icon.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({super.key, required this.name, this.size = 42, this.photo});

  final String name;
  final Uint8List? photo;
  final double size;

  /// Samsung-like pastel tones (each avatar is a light-to-base gradient of one).
  static const palette = [
    Color(0xFF8E8CF0), // periwinkle
    Color(0xFFC5D86D), // lime
    Color(0xFF6CC7F0), // sky
    Color(0xFF6EDBA8), // mint
    Color(0xFFE779B4), // pink
    Color(0xFFF7A14E), // orange
    Color(0xFF66C2B0), // teal
    Color(0xFFB98AF0), // lavender
  ];

  /// Stable colour for a name, shared with favourite tiles.
  static Color colorFor(String name) => palette[name.trim().toLowerCase().hashCode.abs() % palette.length];

  /// Up to two initials: the first letter of each of the first two words (symbols skipped).
  static String initials(String name) {
    final letter = RegExp(r'\p{L}', unicode: true);
    final letters = [
      for (final w in name.trim().split(RegExp(r'\s+')))
        if (letter.firstMatch(w) case final m?) m[0]!.toUpperCase(),
    ];
    return letters.take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    if (photo case final bytes?) {
      return ClipOval(
        child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }
    final text = initials(name);
    if (text.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xFF2C2C2E), shape: BoxShape.circle),
        child: Icon(Icons.person_rounded, size: size * 0.6, color: const Color(0xFF9E9EA4)),
      );
    }
    final color = colorFor(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size * (text.length > 1 ? 0.36 : 0.44),
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }
}
