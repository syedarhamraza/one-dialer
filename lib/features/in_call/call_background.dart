import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/contacts/contacts_repository.dart';
import '../../core/prefs/dialer_prefs.dart';

/// What fills the call screen behind its black fades: the aurora at [colour]'s hue, [image], the
/// caller's own [contactPhoto], or (`auto`) the aurora in the caller's own colours.
@immutable
class CallBackground {
  const CallBackground.colour(Color this.colour) : image = null, contactPhoto = false, soft = false;
  const CallBackground.image(ImageProvider this.image, {this.soft = false}) : colour = null, contactPhoto = false;
  const CallBackground.contactPhoto({this.soft = false}) : colour = null, image = null, contactPhoto = true;

  /// The default aurora chosen on purpose: a contact's own choice that doesn't follow all calls.
  const CallBackground.auto() : colour = null, image = null, contactPhoto = false, soft = false;

  final Color? colour;
  final ImageProvider? image;

  /// The [image] (or the caller's [contactPhoto]) blurred and dimmed all over, ringing or not
  /// ("Blur & dim").
  final bool soft;

  /// Whoever calls: their contact photo (see [resolveCallBackground]).
  final bool contactPhoto;

  /// A stored value (`color:<argb hex>`, `photo:<file name>` or `soft:<file name>` in [dir], `contact:` / `contact:soft`, or `auto:`); null for
  /// the default or anything unreadable.
  static CallBackground? parse(String? value, String dir) {
    final split = value?.indexOf(':') ?? -1;
    if (split < 0) return null;
    final (kind, data) = (value!.substring(0, split), value.substring(split + 1));
    if (kind == 'contact') return CallBackground.contactPhoto(soft: data == 'soft');
    if (kind == 'auto') return const CallBackground.auto();
    if (kind == 'color') {
      final argb = int.tryParse(data, radix: 16);
      return argb == null ? null : CallBackground.colour(Color(argb));
    }
    // A bare file name only: the value must never point outside the backgrounds folder.
    if ((kind == 'photo' || kind == 'soft') && data.isNotEmpty && !data.contains('/') && !data.contains('..')) {
      return CallBackground.image(FileImage(File('$dir/$data')), soft: kind == 'soft');
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CallBackground &&
      other.colour == colour &&
      other.image == image &&
      other.contactPhoto == contactPhoto &&
      other.soft == soft;

  @override
  int get hashCode => Object.hash(colour, image, contactPhoto, soft);
}

/// The aurora's colours from a photo's [rgba] pixels ([width] x [height]): its main colours, not
/// an average (orange petals on green leaves would average to brown). Pixels are grouped by hue,
/// each group weighted by how many and how vivid; groups with at least a sixth of the leader's
/// weight share the aurora, the leader first: the base, then the four blobs in turn. Only hue and
/// saturation count (the aurora sets its own lightness, so white text reads); a grey photo stays grey.
List<Color> photoTones(Uint8List rgba, int width, int height) {
  const groups = 12;
  final weight = List.filled(groups, 0.0);
  final sums = List.generate(groups, (_) => [0.0, 0.0, 0.0]);
  var (r, g, b) = (0, 0, 0);
  for (var i = 0; i + 3 < rgba.length && i < width * height * 4; i += 4) {
    r += rgba[i];
    g += rgba[i + 1];
    b += rgba[i + 2];
    final hsl = HSLColor.fromColor(Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]));
    // Near grey, near black or near white: no hue worth taking.
    if (hsl.saturation < .15 || hsl.lightness < .08 || hsl.lightness > .95) continue;
    final group = (hsl.hue / 360 * groups).floor() % groups;
    final w = hsl.saturation;
    weight[group] += w;
    sums[group][0] += rgba[i] * w;
    sums[group][1] += rgba[i + 1] * w;
    sums[group][2] += rgba[i + 2] * w;
  }
  final order = [
    for (var i = 0; i < groups; i++)
      if (weight[i] > 0) i,
  ]..sort((a, b) => weight[b].compareTo(weight[a]));
  final picked = [
    for (final i in order.where((i) => weight[i] >= weight[order.first] / 6).take(4))
      _tone(
        Color.fromARGB(255, sums[i][0] ~/ weight[i], sums[i][1] ~/ weight[i], sums[i][2] ~/ weight[i]),
        vivid: true,
      ),
  ];
  if (picked.isEmpty) {
    final n = math.max(1, width * height);
    return List.filled(5, _tone(Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n), vivid: false));
  }
  return [picked.first, for (var i = 0; i < 4; i++) picked[i % picked.length]];
}

/// A photo colour at the aurora's lightness; a [vivid] one at least half saturated, so it shows.
Color _tone(Color colour, {required bool vivid}) {
  final hsl = HSLColor.fromColor(colour);
  return hsl.withSaturation(hsl.saturation.clamp(vivid ? .5 : 0.0, .62)).withLightness(.4).toColor();
}

/// One rule: the contact's [own] choice, else the one for [all] calls. "Contact's photo" is the
/// [callerPhoto], or the default tint for a caller without one.
CallBackground? resolveCallBackground({CallBackground? own, CallBackground? all, ImageProvider? callerPhoto}) {
  final pick = own ?? all;
  if (pick == null || !pick.contactPhoto) return pick;
  return callerPhoto == null ? null : CallBackground.image(callerPhoto, soft: pick.soft);
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

  /// Each scope's picked photo, kept while another background is in use.
  final _kept = <String, CallBackground?>{};
  final _photos = <String, Uint8List?>{};
  final _tones = <String, List<Color>?>{};
  String? _dir;

  Future<String> _folder() async => _dir ??= '${(await getApplicationSupportDirectory()).path}/call_bg';

  /// The saved background for [scope], once [load]ed.
  CallBackground? stored(String scope) => _stored[scope];

  /// The contact's full photo, once [loadPhoto]ed.
  Uint8List? photo(String contactId) => _photos[contactId];

  /// The aurora's colours from the contact's photo, once [loadTones]ed (null: no photo).
  List<Color>? tones(String contactId) => _tones[contactId];

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
  bool callerPhotoFills(String contactId) {
    final pick = _stored[contactId] ?? _stored['all'];
    // Blurred, the small photo stays in the header: the backdrop no longer shows the face.
    return pick != null && pick.contactPhoto && !pick.soft && _photos[contactId] != null;
  }

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

  /// Reads the contact's photo colours from its thumbnail, shrunk to 16 px.
  Future<void> loadTones(String contactId) async {
    if (_tones.containsKey(contactId)) return;
    _tones[contactId] = null;
    List<Color>? tones;
    try {
      final thumbnail = await ContactsRepository.instance.thumbnail(contactId);
      if (thumbnail != null) {
        final codec = await ui.instantiateImageCodec(thumbnail, targetWidth: 16, targetHeight: 16);
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        final pixels = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
        if (pixels != null) tones = photoTones(pixels.buffer.asUint8List(), image.width, image.height);
        image.dispose();
      }
    } on Exception {
      // Unreadable photo: the name's tint stays.
    }
    // Forgotten meanwhile (the call ended), or no photo: the name's tint stays.
    if (!_tones.containsKey(contactId) || tones == null) return;
    _tones[contactId] = tones;
    notifyListeners();
  }

  /// Drops the callers' full photos once no call is left; see [ContactsRepository.forgetPhotos].
  void forgetPhotos() {
    _photos.clear();
    _tones.clear();
  }

  /// Reads every loaded background again (the main app may have changed them).
  Future<void> refresh() async {
    await Future.wait(_stored.keys.toList().map(_read));
    notifyListeners();
  }

  Future<void> _read(String scope) async {
    final dir = await _folder();
    final current = await DialerPrefs.instance.callBackground(scope);
    _stored[scope] = CallBackground.parse(current, dir);
    // Saved before photos were kept: the current one is the kept one.
    final kept = await DialerPrefs.instance.keptCallPhoto(scope) ?? (_isPhoto(current) ? current : null);
    _kept[scope] = CallBackground.parse(kept, dir);
  }

  static bool _isPhoto(String? value) =>
      value != null && (value.startsWith('photo:') || value.startsWith('soft:')) && !value.contains('/');

  static String _fileOf(String value) => value.substring(value.indexOf(':') + 1);

  /// [scope]'s picked photo, in use or not, once [load]ed: Photo shows and brings it back.
  CallBackground? kept(String scope) => _kept[scope];

  /// Switches [scope] back to its [kept] photo; false when there is none.
  Future<bool> useKeptPhoto(String scope) async {
    final kept = await DialerPrefs.instance.keptCallPhoto(scope);
    if (!_isPhoto(kept) || !await File('${await _folder()}/${_fileOf(kept!)}').exists()) return false;
    await DialerPrefs.instance.setCallBackground(scope, kept);
    _stored[scope] = CallBackground.parse(kept, await _folder());
    notifyListeners();
    return true;
  }

  /// Saves [scope]'s background: a [colour], a [photo] (JPEG bytes), the caller's [contactPhoto],
  /// or none of them for the default. A picked photo is kept (see [kept]) until another replaces it.
  Future<void> save(
    String scope, {
    Color? colour,
    Uint8List? photo,
    bool contactPhoto = false,
    bool auto = false,
    bool? soft,
  }) async {
    final dir = await _folder();
    final old = await DialerPrefs.instance.callBackground(scope);
    var kept = await DialerPrefs.instance.keptCallPhoto(scope);
    // The photo in use is the one to keep (with its Blur & dim); a stray older one goes.
    if (_isPhoto(old)) {
      if (_isPhoto(kept) && _fileOf(kept!) != _fileOf(old!)) await _delete(dir, kept);
      kept = old;
    }
    String? value;
    if (photo != null) {
      // A new name each time: FileImage caches by path, so reusing one would show the old photo.
      final name = '$scope-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Directory(dir).create(recursive: true);
      await File('$dir/$name').writeAsBytes(photo);
      // A new photo keeps Blur & dim as it was.
      value = '${soft ?? (kept != null && kept.startsWith('soft:')) ? 'soft' : 'photo'}:$name';
      // The new photo replaces the kept one.
      if (_isPhoto(kept)) await _delete(dir, kept!);
      kept = value;
    } else if (colour != null) {
      value = 'color:${colour.toARGB32().toRadixString(16)}';
    } else if (contactPhoto) {
      // Blur & dim stays as it was.
      value = soft ?? old == 'contact:soft' ? 'contact:soft' : 'contact:';
    } else if (auto) {
      value = 'auto:';
    }
    await DialerPrefs.instance.setCallBackground(scope, value);
    await DialerPrefs.instance.setKeptCallPhoto(scope, _isPhoto(kept) ? kept : null);
    _stored[scope] = CallBackground.parse(value, dir);
    _kept[scope] = CallBackground.parse(kept, dir);
    notifyListeners();
  }

  static Future<void> _delete(String dir, String value) async {
    try {
      await File('$dir/${_fileOf(value)}').delete();
    } on FileSystemException {
      // Already gone.
    }
  }

  /// Turns Blur & dim on or off for [scope]'s photo or contact photo; a photo's file stays.
  Future<void> setSoft(String scope, bool soft) async {
    final old = await DialerPrefs.instance.callBackground(scope);
    if (old == null) return;
    final String value;
    if (old.startsWith('contact:')) {
      value = soft ? 'contact:soft' : 'contact:';
    } else if (old.startsWith('photo:') || old.startsWith('soft:')) {
      value = '${soft ? 'soft' : 'photo'}:${old.substring(old.indexOf(':') + 1)}';
      await DialerPrefs.instance.setKeptCallPhoto(scope, value);
      _kept[scope] = CallBackground.parse(value, await _folder());
    } else {
      return;
    }
    await DialerPrefs.instance.setCallBackground(scope, value);
    _stored[scope] = CallBackground.parse(value, await _folder());
    notifyListeners();
  }
}
