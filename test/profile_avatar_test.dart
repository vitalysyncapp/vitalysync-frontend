import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/profile/data/profile_avatar.dart';
import 'package:vitalysync/shared/preferences/session_reset_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog exposes 45 distinct bundled avatar choices', () {
    expect(ProfileAvatarCatalog.entries, hasLength(45));
    expect(
      ProfileAvatarCatalog.entries.map((entry) => entry.id).toSet(),
      hasLength(45),
    );
    expect(
      ProfileAvatarCatalog.entriesFor(ProfileAvatarCategory.personas),
      hasLength(25),
    );
    for (final category in const [
      ProfileAvatarCategory.youngProfessional,
      ProfileAvatarCategory.freelancer,
    ]) {
      expect(ProfileAvatarCatalog.entriesFor(category), hasLength(4));
    }
    expect(
      ProfileAvatarCatalog.entriesFor(ProfileAvatarCategory.student),
      hasLength(6),
    );
    expect(
      ProfileAvatarCatalog.entriesFor(
        ProfileAvatarCategory.workingProfessional,
      ),
      hasLength(6),
    );
    expect(
      ProfileAvatarCatalog.entries.map((entry) => entry.assetPath),
      containsAll(const [
        ProfileAvatarAssets.generic,
        ProfileAvatarAssets.maleStudent,
        ProfileAvatarAssets.femaleStudent,
        ProfileAvatarAssets.businessMan,
        ProfileAvatarAssets.businessWoman,
      ]),
    );
  });

  test('suggested avatar normalizes role and gender values', () {
    expect(
      suggestedProfileAvatarAsset(' female ', ' student '),
      ProfileAvatarAssets.femaleStudent,
    );
    expect(
      suggestedProfileAvatarAsset('MALE', 'Working Professional'),
      ProfileAvatarAssets.businessMan,
    );
    expect(
      suggestedProfileAvatarAsset('Other', 'Student'),
      ProfileAvatarAssets.generic,
    );
  });

  test('bundled selection round-trips and remains isolated per user', () async {
    final storage = _MemoryAvatarStorage();
    final store = ProfileAvatarStore(storage: storage);

    await store.saveBundled(7, 'personas_03');

    final saved = await store.load(7);
    final otherUser = await store.load(8);
    expect(saved.kind, ProfileAvatarKind.bundled);
    expect(saved.avatarId, 'personas_03');
    expect(otherUser.kind, ProfileAvatarKind.suggested);
  });

  test('custom photo round-trips and reset removes its record', () async {
    final storage = _MemoryAvatarStorage();
    final store = ProfileAvatarStore(storage: storage);
    final jpeg = ProfileAvatarImageProcessor.prepareCroppedPhoto(_validPng());

    await store.saveCustom(11, jpeg);
    final saved = await store.load(11);
    expect(saved.kind, ProfileAvatarKind.custom);
    expect(saved.customBytes, orderedEquals(jpeg));

    await store.resetToSuggested(11);
    expect((await store.load(11)).kind, ProfileAvatarKind.suggested);
  });

  test('corrupt records are removed and fall back to suggested', () async {
    final storage = _MemoryAvatarStorage();
    storage.values['${ProfileAvatarStore.storageKeyPrefix}4'] = jsonEncode({
      'version': 1,
      'kind': 'bundled',
      'avatar_id': 'missing-avatar',
    });
    final store = ProfileAvatarStore(storage: storage);

    final selection = await store.load(4);

    expect(selection.kind, ProfileAvatarKind.suggested);
    expect(
      storage.values.containsKey('${ProfileAvatarStore.storageKeyPrefix}4'),
      isFalse,
    );
  });

  test('failed local writes leave the avatar unsaved', () async {
    final storage = _MemoryAvatarStorage()..failWrites = true;
    final store = ProfileAvatarStore(storage: storage);

    await expectLater(
      store.saveBundled(3, 'personas_01'),
      throwsA(isA<ProfileAvatarException>()),
    );
    expect(storage.values, isEmpty);
  });

  test('image processor creates a bounded 512-square JPEG', () {
    final source = _validPng();
    ProfileAvatarImageProcessor.validateInput(source);

    final prepared = ProfileAvatarImageProcessor.prepareCroppedPhoto(source);
    final decoded = image_lib.decodeJpg(prepared);

    expect(ProfileAvatarImageProcessor.isJpeg(prepared), isTrue);
    expect(prepared.length, lessThanOrEqualTo(500 * 1024));
    expect(decoded, isNotNull);
    expect(decoded!.width, 512);
    expect(decoded.height, 512);
    expect(decoded.exif.isEmpty, isTrue);
    expect(decoded.iccProfile, isNull);
    expect(decoded.textData, isNull);
  });

  test('image processor rejects unsupported and oversized input', () {
    expect(
      () => ProfileAvatarImageProcessor.validateInput(
        Uint8List.fromList(List<int>.filled(32, 1)),
      ),
      throwsA(isA<ProfileAvatarException>()),
    );
    expect(
      () => ProfileAvatarImageProcessor.validateInput(
        Uint8List(ProfileAvatarImageProcessor.maxInputBytes + 1),
      ),
      throwsA(isA<ProfileAvatarException>()),
    );
  });

  test('normal logout retains persistent avatar storage', () async {
    SharedPreferences.setMockInitialValues({
      'user_id': 19,
      'email': 'avatar@example.com',
      'auth_access_token': 'token',
      '${ProfileAvatarStore.storageKeyPrefix}19': jsonEncode({
        'version': 1,
        'kind': 'bundled',
        'avatar_id': 'personas_05',
      }),
      'profile_temporary_value': 'remove-me',
    });

    await SessionResetService.instance.resetForLogout();
    final preferences = await SharedPreferences.getInstance();

    expect(
      preferences.getString('${ProfileAvatarStore.storageKeyPrefix}19'),
      isNotNull,
    );
    expect(preferences.getString('profile_temporary_value'), isNull);
  });

  test('legacy Open Peeps selections migrate to Personas', () async {
    final storage = _MemoryAvatarStorage();
    storage.values['${ProfileAvatarStore.storageKeyPrefix}12'] = jsonEncode({
      'version': 1,
      'kind': 'bundled',
      'avatar_id': 'open_peeps_08',
    });
    final store = ProfileAvatarStore(storage: storage);

    final selection = await store.load(12);

    expect(selection.kind, ProfileAvatarKind.bundled);
    expect(selection.avatarId, 'personas_08');
  });
}

Uint8List _validPng() {
  return image_lib.encodePng(image_lib.Image(width: 24, height: 24));
}

class _MemoryAvatarStorage implements ProfileAvatarStorage {
  final Map<String, String> values = {};
  bool failWrites = false;
  bool failRemovals = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<bool> remove(String key) async {
    if (failRemovals) return false;
    values.remove(key);
    return true;
  }

  @override
  Future<bool> write(String key, String value) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }
}
