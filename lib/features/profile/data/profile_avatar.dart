import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileAvatarKind { suggested, bundled, custom }

@immutable
class ProfileAvatarSelection {
  const ProfileAvatarSelection._({
    required this.kind,
    this.avatarId,
    this.customBytes,
  });

  const ProfileAvatarSelection.suggested()
    : this._(kind: ProfileAvatarKind.suggested);

  const ProfileAvatarSelection.bundled(String avatarId)
    : this._(kind: ProfileAvatarKind.bundled, avatarId: avatarId);

  const ProfileAvatarSelection.custom(Uint8List customBytes)
    : this._(kind: ProfileAvatarKind.custom, customBytes: customBytes);

  final ProfileAvatarKind kind;
  final String? avatarId;
  final Uint8List? customBytes;
}

@immutable
class AvatarCatalogEntry {
  const AvatarCatalogEntry({
    required this.id,
    required this.assetPath,
    required this.semanticLabel,
    required this.frameColor,
  });

  final String id;
  final String assetPath;
  final String semanticLabel;
  final Color frameColor;
}

class ProfileAvatarCatalog {
  ProfileAvatarCatalog._();

  static const entries = <AvatarCatalogEntry>[
    AvatarCatalogEntry(
      id: 'open_peeps_01',
      assetPath: 'assets/images/avatars/open_peeps_01.svg',
      semanticLabel: 'Avatar option 1',
      frameColor: Color(0xFFD9F7F3),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_02',
      assetPath: 'assets/images/avatars/open_peeps_02.svg',
      semanticLabel: 'Avatar option 2',
      frameColor: Color(0xFFDDF4FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_03',
      assetPath: 'assets/images/avatars/open_peeps_03.svg',
      semanticLabel: 'Avatar option 3',
      frameColor: Color(0xFFE6E8FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_04',
      assetPath: 'assets/images/avatars/open_peeps_04.svg',
      semanticLabel: 'Avatar option 4',
      frameColor: Color(0xFFEAF7E8),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_05',
      assetPath: 'assets/images/avatars/open_peeps_05.svg',
      semanticLabel: 'Avatar option 5',
      frameColor: Color(0xFFFFF1D6),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_06',
      assetPath: 'assets/images/avatars/open_peeps_06.svg',
      semanticLabel: 'Avatar option 6',
      frameColor: Color(0xFFF3E7FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_07',
      assetPath: 'assets/images/avatars/open_peeps_07.svg',
      semanticLabel: 'Avatar option 7',
      frameColor: Color(0xFFD9F7F3),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_08',
      assetPath: 'assets/images/avatars/open_peeps_08.svg',
      semanticLabel: 'Avatar option 8',
      frameColor: Color(0xFFDDF4FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_09',
      assetPath: 'assets/images/avatars/open_peeps_09.svg',
      semanticLabel: 'Avatar option 9',
      frameColor: Color(0xFFE6E8FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_10',
      assetPath: 'assets/images/avatars/open_peeps_10.svg',
      semanticLabel: 'Avatar option 10',
      frameColor: Color(0xFFEAF7E8),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_11',
      assetPath: 'assets/images/avatars/open_peeps_11.svg',
      semanticLabel: 'Avatar option 11',
      frameColor: Color(0xFFFFF1D6),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_12',
      assetPath: 'assets/images/avatars/open_peeps_12.svg',
      semanticLabel: 'Avatar option 12',
      frameColor: Color(0xFFF3E7FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_13',
      assetPath: 'assets/images/avatars/open_peeps_13.svg',
      semanticLabel: 'Avatar option 13',
      frameColor: Color(0xFFD9F7F3),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_14',
      assetPath: 'assets/images/avatars/open_peeps_14.svg',
      semanticLabel: 'Avatar option 14',
      frameColor: Color(0xFFDDF4FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_15',
      assetPath: 'assets/images/avatars/open_peeps_15.svg',
      semanticLabel: 'Avatar option 15',
      frameColor: Color(0xFFE6E8FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_16',
      assetPath: 'assets/images/avatars/open_peeps_16.svg',
      semanticLabel: 'Avatar option 16',
      frameColor: Color(0xFFEAF7E8),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_17',
      assetPath: 'assets/images/avatars/open_peeps_17.svg',
      semanticLabel: 'Avatar option 17',
      frameColor: Color(0xFFFFF1D6),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_18',
      assetPath: 'assets/images/avatars/open_peeps_18.svg',
      semanticLabel: 'Avatar option 18',
      frameColor: Color(0xFFF3E7FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_19',
      assetPath: 'assets/images/avatars/open_peeps_19.svg',
      semanticLabel: 'Avatar option 19',
      frameColor: Color(0xFFD9F7F3),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_20',
      assetPath: 'assets/images/avatars/open_peeps_20.svg',
      semanticLabel: 'Avatar option 20',
      frameColor: Color(0xFFDDF4FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_21',
      assetPath: 'assets/images/avatars/open_peeps_21.svg',
      semanticLabel: 'Avatar option 21',
      frameColor: Color(0xFFE6E8FF),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_22',
      assetPath: 'assets/images/avatars/open_peeps_22.svg',
      semanticLabel: 'Avatar option 22',
      frameColor: Color(0xFFEAF7E8),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_23',
      assetPath: 'assets/images/avatars/open_peeps_23.svg',
      semanticLabel: 'Avatar option 23',
      frameColor: Color(0xFFFFF1D6),
    ),
    AvatarCatalogEntry(
      id: 'open_peeps_24',
      assetPath: 'assets/images/avatars/open_peeps_24.svg',
      semanticLabel: 'Avatar option 24',
      frameColor: Color(0xFFF3E7FF),
    ),
  ];

  static AvatarCatalogEntry? findById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}

String suggestedProfileAvatarAsset(String? gender, String? userType) {
  if (gender == null || userType == null) return 'assets/images/user.png';

  if (gender.toLowerCase() == 'male') {
    return userType == 'Student'
        ? 'assets/images/male Student.png'
        : 'assets/images/business-man.png';
  }
  if (gender.toLowerCase() == 'female') {
    return userType == 'Student'
        ? 'assets/images/female Student.png'
        : 'assets/images/businesswoman.png';
  }
  return 'assets/images/user.png';
}

abstract interface class ProfileAvatarStorage {
  Future<String?> read(String key);
  Future<bool> write(String key, String value);
  Future<bool> remove(String key);
}

class SharedPreferencesProfileAvatarStorage implements ProfileAvatarStorage {
  @override
  Future<String?> read(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<bool> write(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.remove(key);
  }
}

class ProfileAvatarStore {
  ProfileAvatarStore({ProfileAvatarStorage? storage})
    : _storage = storage ?? SharedPreferencesProfileAvatarStorage();

  static final shared = ProfileAvatarStore();
  static const storageKeyPrefix = 'persistent_avatar_v1_';
  static const _version = 1;

  final ProfileAvatarStorage _storage;

  String _keyForUser(int userId) => '$storageKeyPrefix$userId';

  Future<ProfileAvatarSelection> load(int userId) async {
    if (userId <= 0) return const ProfileAvatarSelection.suggested();

    final key = _keyForUser(userId);
    final rawValue = await _storage.read(key);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const ProfileAvatarSelection.suggested();
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map || decoded['version'] != _version) {
        throw const FormatException('Unsupported avatar record');
      }

      switch (decoded['kind']) {
        case 'bundled':
          final avatarId = decoded['avatar_id']?.toString();
          if (ProfileAvatarCatalog.findById(avatarId) == null) {
            throw const FormatException('Unknown avatar ID');
          }
          return ProfileAvatarSelection.bundled(avatarId!);
        case 'custom':
          final encodedPhoto = decoded['photo_base64']?.toString() ?? '';
          final bytes = base64Decode(encodedPhoto);
          if (bytes.isEmpty ||
              bytes.length > ProfileAvatarImageProcessor.maxOutputBytes ||
              !ProfileAvatarImageProcessor.isJpeg(bytes) ||
              !ProfileAvatarImageProcessor.isDecodableImage(bytes)) {
            throw const FormatException('Invalid custom avatar bytes');
          }
          return ProfileAvatarSelection.custom(bytes);
        default:
          throw const FormatException('Unknown avatar kind');
      }
    } catch (_) {
      await _storage.remove(key);
      return const ProfileAvatarSelection.suggested();
    }
  }

  Future<void> saveBundled(int userId, String avatarId) async {
    if (userId <= 0 || ProfileAvatarCatalog.findById(avatarId) == null) {
      throw const ProfileAvatarException('That avatar is not available.');
    }

    await _write(userId, <String, dynamic>{
      'version': _version,
      'kind': 'bundled',
      'avatar_id': avatarId,
    });
  }

  Future<void> saveCustom(int userId, Uint8List jpegBytes) async {
    if (userId <= 0 ||
        jpegBytes.isEmpty ||
        jpegBytes.length > ProfileAvatarImageProcessor.maxOutputBytes ||
        !ProfileAvatarImageProcessor.isJpeg(jpegBytes) ||
        !ProfileAvatarImageProcessor.isDecodableImage(jpegBytes)) {
      throw const ProfileAvatarException(
        'The processed profile photo is not valid.',
      );
    }

    await _write(userId, <String, dynamic>{
      'version': _version,
      'kind': 'custom',
      'photo_base64': base64Encode(jpegBytes),
    });
  }

  Future<void> resetToSuggested(int userId) => clearForUser(userId);

  Future<void> clearForUser(int userId) async {
    if (userId <= 0) return;
    final didRemove = await _storage.remove(_keyForUser(userId));
    if (!didRemove) {
      throw const ProfileAvatarException(
        'Unable to remove the saved profile avatar.',
      );
    }
  }

  Future<void> _write(int userId, Map<String, dynamic> record) async {
    final didWrite = await _storage.write(
      _keyForUser(userId),
      jsonEncode(record),
    );
    if (!didWrite) {
      throw const ProfileAvatarException(
        'Unable to save the profile avatar on this device.',
      );
    }
  }
}

@immutable
class ProfileAvatarState {
  const ProfileAvatarState({
    required this.userId,
    required this.selection,
    required this.isLoaded,
  });

  const ProfileAvatarState.empty()
    : userId = null,
      selection = const ProfileAvatarSelection.suggested(),
      isLoaded = false;

  final int? userId;
  final ProfileAvatarSelection selection;
  final bool isLoaded;
}

class ProfileAvatarController {
  ProfileAvatarController({ProfileAvatarStore? store})
    : _store = store ?? ProfileAvatarStore.shared;

  static final instance = ProfileAvatarController();

  final ProfileAvatarStore _store;
  final ValueNotifier<ProfileAvatarState> notifier = ValueNotifier(
    const ProfileAvatarState.empty(),
  );
  int _loadGeneration = 0;

  Future<ProfileAvatarSelection> loadForUser(
    int userId, {
    bool force = false,
  }) async {
    final current = notifier.value;
    if (!force && current.userId == userId && current.isLoaded) {
      return current.selection;
    }

    final generation = ++_loadGeneration;
    final selection = await _store.load(userId);
    if (generation == _loadGeneration) {
      notifier.value = ProfileAvatarState(
        userId: userId,
        selection: selection,
        isLoaded: true,
      );
    }
    return selection;
  }

  Future<void> saveBundled(int userId, String avatarId) async {
    await _store.saveBundled(userId, avatarId);
    _loadGeneration++;
    notifier.value = ProfileAvatarState(
      userId: userId,
      selection: ProfileAvatarSelection.bundled(avatarId),
      isLoaded: true,
    );
  }

  Future<void> saveCustom(int userId, Uint8List jpegBytes) async {
    await _store.saveCustom(userId, jpegBytes);
    _loadGeneration++;
    notifier.value = ProfileAvatarState(
      userId: userId,
      selection: ProfileAvatarSelection.custom(jpegBytes),
      isLoaded: true,
    );
  }

  Future<void> resetToSuggested(int userId) async {
    await _store.resetToSuggested(userId);
    _loadGeneration++;
    notifier.value = ProfileAvatarState(
      userId: userId,
      selection: const ProfileAvatarSelection.suggested(),
      isLoaded: true,
    );
  }

  Future<void> clearForUser(int userId) async {
    await _store.clearForUser(userId);
    _loadGeneration++;
    if (notifier.value.userId == userId) {
      notifier.value = ProfileAvatarState(
        userId: userId,
        selection: const ProfileAvatarSelection.suggested(),
        isLoaded: true,
      );
    }
  }
}

class ProfileAvatarImageProcessor {
  ProfileAvatarImageProcessor._();

  static const maxInputBytes = 10 * 1024 * 1024;
  static const maxOutputBytes = 500 * 1024;
  static const outputDimension = 512;
  static const jpegQuality = 80;

  static bool isSupportedInput(Uint8List bytes) {
    if (bytes.length < 12) return false;
    final isPng =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isWebp =
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return isJpeg(bytes) || isPng || isWebp;
  }

  static bool isJpeg(Uint8List bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }

  static bool isDecodableImage(Uint8List bytes) {
    try {
      return image_lib.decodeImage(bytes) != null;
    } catch (_) {
      return false;
    }
  }

  static void validateInput(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxInputBytes) {
      throw const ProfileAvatarException('Choose an image smaller than 10 MB.');
    }
    if (!isSupportedInput(bytes) || !isDecodableImage(bytes)) {
      throw const ProfileAvatarException(
        'Choose a valid JPEG, PNG, or WebP image.',
      );
    }
  }

  static Uint8List prepareCroppedPhoto(Uint8List croppedBytes) {
    image_lib.Image? decoded;
    try {
      decoded = image_lib.decodeImage(croppedBytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      throw const ProfileAvatarException(
        'The cropped photo could not be processed.',
      );
    }

    final resized = image_lib.copyResize(
      decoded,
      width: outputDimension,
      height: outputDimension,
      interpolation: image_lib.Interpolation.average,
    );
    resized.exif.clear();
    resized.iccProfile = null;
    resized.textData = null;
    final encoded = image_lib.encodeJpg(resized, quality: jpegQuality);
    if (encoded.length > maxOutputBytes) {
      throw const ProfileAvatarException(
        'The cropped photo is still too large. Try another image.',
      );
    }
    return encoded;
  }
}

class ProfileAvatarException implements Exception {
  const ProfileAvatarException(this.message);

  final String message;

  @override
  String toString() => message;
}
