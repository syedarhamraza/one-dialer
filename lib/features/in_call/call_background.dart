import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';

/// What fills the call screen behind its black fades: the aurora at [colour]'s hue, [image], or
/// the caller's own [contactPhoto].
@immutable
class CallBackground {
  const CallBackground.colour(Color this.colour) : image = null, contactPhoto = false;
  const CallBackground.image(ImageProvider this.image) : colour = null, contactPhoto = false;
  const CallBackground.contactPhoto() : colour = null, image = null, contactPhoto = true;

  final Color? colour;
  final ImageProvider? image;

  /// Whoever calls: their contact photo (see [resolveCallBackground]).
  final bool contactPhoto;

  /// A stored value (`color:<argb hex>`, `photo:<file name>` in [dir], or `contact:`); null for
  /// the default or anything unreadable.
  static CallBackground? parse(String? value, String dir) {
    final split = value?.indexOf(':') ?? -1;
    if (split < 0) return null;
    final (kind, data) = (value!.substring(0, split), value.substring(split + 1));
    if (kind == 'contact') return const CallBackground.contactPhoto();
    if (kind == 'color') {
      final argb = int.tryParse(data, radix: 16);
      return argb == null ? null : CallBackground.colour(Color(argb));
    }
    // A bare file name only: the value must never point outside the backgrounds folder.
    if (kind == 'photo' && data.isNotEmpty && !data.contains('/') && !data.contains('..')) {
      return CallBackground.image(FileImage(File('$dir/$data')));
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CallBackground && other.colour == colour && other.image == image && other.contactPhoto == contactPhoto;

  @override
  int get hashCode => Object.hash(colour, image, contactPhoto);
}

/// One rule: the contact's [own] choice, else the one for [all] calls. "Contact's photo" is the
/// [callerPhoto], or the default tint for a caller without one.
CallBackground? resolveCallBackground({CallBackground? own, CallBackground? all, ImageProvider? callerPhoto}) {
  final pick = own ?? all;
  if (pick == null || !pick.contactPhoto) return pick;
  return callerPhoto == null ? null : CallBackground.image(callerPhoto);
}

/// The saved call backgrounds, per contact id or `all`, read once and kept so the call screen
/// draws them without waiting; [refresh] picks up changes made in the main app.
class CallBackgrounds extends ChangeNotifier {
  CallBackgrounds._();

  static final instance = CallBackgrounds._();

  /// The colour choices: the aurora at each one's hue.
  static const swatches = [
    Color(0xFF2F80ED),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];

  final _stored = <String, CallBackground?>{};
  final _photos = <String, Uint8List?>{};
  String? _dir;

  Future<String> _folder() async => _dir ??= '${(await getApplicationSupportDirectory()).path}/call_bg';

  /// The saved background for [scope], once [load]ed.
  CallBackground? stored(String scope) => _stored[scope];

  /// The contact's full photo, once [loadPhoto]ed.
  Uint8List? photo(String contactId) => _photos[contactId];

  /// What the call screen shows for a call from [contactId] (null: not a contact).
  CallBackground? forCall(String? contactId) {
    final photo = contactId == null ? null : _photos[contactId];
    return resolveCallBackground(
      own: contactId == null ? null : _stored[contactId],
      all: _stored['all'],
      callerPhoto: photo == null ? null : MemoryImage(photo),
    );
  }

  /// Whether the caller's own photo fills the screen (the header then drops its small one).
  bool callerPhotoFills(String contactId) =>
      (_stored[contactId] ?? _stored['all'])?.contactPhoto == true && _photos[contactId] != null;

  Future<void> load(String scope) async {
    if (_stored.containsKey(scope)) return;
    // Marked at once: the call screen asks again on every call update while this reads.
    _stored[scope] = null;
    try {
      await _read(scope);
    } catch (_) {
      _stored.remove(scope); // the next ask reads again
      rethrow;
    }
    notifyListeners();
  }

  Future<void> loadPhoto(String contactId) async {
    if (_photos.containsKey(contactId)) return;
    _photos[contactId] = null;
    final photo = await ContactsRepository.instance.fullPhoto(contactId);
    // Forgotten meanwhile (the call ended): the next call loads it again.
    if (!_photos.containsKey(contactId)) return;
    _photos[contactId] = photo;
    notifyListeners();
  }

  /// Drops the callers' full photos once no call is left; see [ContactsRepository.forgetPhotos].
  void forgetPhotos() => _photos.clear();

  /// Reads every loaded background again (the main app may have changed them).
  Future<void> refresh() async {
    await Future.wait(_stored.keys.toList().map(_read));
    notifyListeners();
  }

  Future<void> _read(String scope) async =>
      _stored[scope] = CallBackground.parse(await DialerPrefs.instance.callBackground(scope), await _folder());

  /// Saves [scope]'s background: a [colour], a [photo] (JPEG bytes), the caller's [contactPhoto],
  /// or none of them for the default. The old photo file goes.
  Future<void> save(String scope, {Color? colour, Uint8List? photo, bool contactPhoto = false}) async {
    final dir = await _folder();
    final old = await DialerPrefs.instance.callBackground(scope);
    String? value;
    if (photo != null) {
      // A new name each time: FileImage caches by path, so reusing one would show the old photo.
      final name = '$scope-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Directory(dir).create(recursive: true);
      await File('$dir/$name').writeAsBytes(photo);
      value = 'photo:$name';
    } else if (colour != null) {
      value = 'color:${colour.toARGB32().toRadixString(16)}';
    } else if (contactPhoto) {
      value = 'contact:';
    }
    await DialerPrefs.instance.setCallBackground(scope, value);
    if (old != null && old.startsWith('photo:') && !old.contains('/')) {
      try {
        await File('$dir/${old.substring(6)}').delete();
      } on FileSystemException {
        // Already gone.
      }
    }
    _stored[scope] = CallBackground.parse(value, dir);
    notifyListeners();
  }
}
