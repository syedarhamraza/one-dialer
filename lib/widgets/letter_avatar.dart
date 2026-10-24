import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/prefs/dialer_prefs.dart';

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
    final letters = [
      for (final w in name.trim().split(_space))
        if (_letter.firstMatch(w) case final m?) m[0]!.toUpperCase(),
    ];
    return letters.take(2).join();
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _space = RegExp(r'\s+');

  @override
  Widget build(BuildContext context) {
    if (photo case final bytes?) {
      // A circular decoration rather than a ClipOval: no clip layer per avatar while lists scroll.
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            // Decode at display size, not the thumbnail's full resolution.
            image: ResizeImage(MemoryImage(bytes), width: (size * MediaQuery.devicePixelRatioOf(context)).round()),
            fit: BoxFit.cover,
          ),
        ),
        child: SizedBox.square(dimension: size),
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

/// A saved contact's [LetterAvatar]: initials until the photo loads, which happens the first
/// time the row shows (contacts load without photos, so startup reads names and numbers only).
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({super.key, required this.id, required this.name, this.size = 42});

  final String id;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final repo = ContactsRepository.instance;
    // Manage contacts › Show contact's profile picture.
    return ValueListenableBuilder(
      valueListenable: DialerPrefs.instance.showPhotos,
      builder: (context, show, _) => !show
          ? LetterAvatar(name: name, size: size)
          : FutureBuilder(
              future: repo.thumbnail(id),
              initialData: repo.cachedThumbnail(id),
              builder: (context, photo) => LetterAvatar(name: name, photo: photo.data, size: size),
            ),
    );
  }
}

/// A call's avatar: the saved contact's (with their photo) when the number is one, else
/// initials from [name] (a person icon for hidden callers).
class CallerAvatar extends StatelessWidget {
  const CallerAvatar({super.key, required this.number, required this.name, this.isPrivate = false, this.size = 42});

  final String number;
  final String name;
  final bool isPrivate;
  final double size;

  @override
  Widget build(BuildContext context) {
    final contact = isPrivate ? null : ContactsRepository.instance.contactFor(number);
    return contact == null
        ? LetterAvatar(name: isPrivate ? '' : name, size: size)
        : ContactAvatar(id: contact.id, name: contact.name, size: size);
  }
}
