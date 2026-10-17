import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The contact's photo, or a coloured circle with the name's first letter.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({super.key, required this.name, this.size = 42, this.photo});

  final String name;
  final Uint8List? photo;
  final double size;

  static const _colors = [
    Color(0xFFF07167),
    Color(0xFFFB8C00),
    Color(0xFF00C05A),
    Color(0xFF48B5A0),
    Color(0xFF34AADC),
    Color(0xFF5390F5),
    Color(0xFF7E57C2),
    Color(0xFFEF6C9A),
  ];

  @override
  Widget build(BuildContext context) {
    if (photo case final bytes?) {
      return ClipOval(
        child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }
    final first = name.trim().isEmpty ? '' : name.trim()[0].toUpperCase();
    // Unsaved numbers and private callers get a person icon, like Samsung.
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(first)) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xFF2C2C2E), shape: BoxShape.circle),
        child: Icon(Icons.person_rounded, size: size * 0.6, color: const Color(0xFF9E9EA4)),
      );
    }
    final letter = first;
    final color = _colors[name.hashCode.abs() % _colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.22), shape: BoxShape.circle),
      child: Text(
        letter,
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
