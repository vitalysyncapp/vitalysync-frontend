import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/profile/data/profile_avatar.dart';
import 'package:vitalysync/features/profile/presentation/pages/avatar_crop_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/edit_avatar_page.dart';
import 'package:vitalysync/shared/widgets/app_bar.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('editor renders 40 choices and saves a bundled avatar', (
    tester,
  ) async {
    final storage = _MemoryAvatarStorage();
    final store = ProfileAvatarStore(storage: storage);
    final controller = ProfileAvatarController(store: store);

    await _openEditor(tester, controller: controller);

    expect(find.byKey(const ValueKey('avatar-catalog-grid')), findsOneWidget);
    for (final entry in ProfileAvatarCatalog.entries) {
      expect(find.byKey(ValueKey('avatar-option-${entry.id}')), findsOneWidget);
    }
    expect(find.text('Students'), findsNothing);
    expect(find.text('Working professionals'), findsNothing);
    expect(find.text('Young professionals'), findsNothing);
    expect(find.text('Freelancers'), findsNothing);
    expect(find.text('Personas collection'), findsNothing);

    final option = find.byKey(
      const ValueKey('avatar-option-avataaars_working_professional_03'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.ensureVisible(
      find.byKey(const ValueKey('avatar-save-button')),
    );
    await tester.tap(find.byKey(const ValueKey('avatar-save-button')));
    await tester.pumpAndSettle();

    final saved = await store.load(42);
    expect(saved.kind, ProfileAvatarKind.bundled);
    expect(saved.avatarId, 'avataaars_working_professional_03');
  });

  testWidgets('backing out discards the avatar draft', (tester) async {
    final storage = _MemoryAvatarStorage();
    final store = ProfileAvatarStore(storage: storage);
    await store.saveBundled(42, 'personas_02');
    final controller = ProfileAvatarController(store: store);

    await _openEditor(tester, controller: controller);
    final option = find.byKey(const ValueKey('avatar-option-personas_03'));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    final saved = await store.load(42);
    expect(saved.kind, ProfileAvatarKind.bundled);
    expect(saved.avatarId, 'personas_02');
  });

  testWidgets('uploaded photo uses injected picker and crop result', (
    tester,
  ) async {
    final storage = _MemoryAvatarStorage();
    final store = ProfileAvatarStore(storage: storage);
    final controller = ProfileAvatarController(store: store);
    final source = _validPng();
    final prepared = ProfileAvatarImageProcessor.prepareCroppedPhoto(source);

    await _openEditor(
      tester,
      controller: controller,
      pickImage: () async =>
          XFile.fromData(source, name: 'avatar.png', mimeType: 'image/png'),
      cropImage: (_, _) async => prepared,
    );

    await tester.tap(find.byKey(const ValueKey('avatar-upload-photo-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('avatar-save-button')),
    );
    await tester.tap(find.byKey(const ValueKey('avatar-save-button')));
    await tester.pumpAndSettle();

    final saved = await store.load(42);
    expect(saved.kind, ProfileAvatarKind.custom);
    expect(saved.customBytes, orderedEquals(prepared));
  });

  testWidgets('invalid uploaded bytes show a helpful error', (tester) async {
    final storage = _MemoryAvatarStorage();
    final controller = ProfileAvatarController(
      store: ProfileAvatarStore(storage: storage),
    );

    await _openEditor(
      tester,
      controller: controller,
      pickImage: () async => XFile.fromData(
        Uint8List.fromList(List<int>.filled(40, 3)),
        name: 'avatar.txt',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('avatar-upload-photo-button')));
    await tester.pump();

    expect(
      find.text('Choose a valid JPEG, PNG, or WebP image.'),
      findsOneWidget,
    );
  });

  testWidgets('crop page exposes fixed avatar crop controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AvatarCropPage(imageBytes: _validPng())),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('avatar-crop-editor')), findsWidgets);
    expect(
      find.byKey(const ValueKey('avatar-use-cropped-photo')),
      findsOneWidget,
    );
    expect(
      find.text('Drag to reposition and pinch or scroll to zoom.'),
      findsOneWidget,
    );
  });

  testWidgets('app bar switches to a saved SVG avatar immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_id': 77,
      'username': 'Avatar Tester',
      'gender': 'Other',
      'user_type': 'Student',
    });
    await ProfileAvatarController.instance.loadForUser(77, force: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              appBar: buildAppBar(context),
              body: const SizedBox(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNothing);

    await ProfileAvatarController.instance.saveBundled(77, 'personas_12');
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byKey(const ValueKey('main-app-bar-avatar')), findsOneWidget);
  });
}

Uint8List _validPng() {
  return image_lib.encodePng(image_lib.Image(width: 24, height: 24));
}

Future<void> _openEditor(
  WidgetTester tester, {
  required ProfileAvatarController controller,
  ProfileAvatarImagePicker? pickImage,
  ProfileAvatarCropper? cropImage,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open-avatar-editor'),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => EditAvatarPage(
                        userId: 42,
                        gender: 'Other',
                        userType: 'Student',
                        controller: controller,
                        pickImage: pickImage,
                        cropImage: cropImage,
                      ),
                    ),
                  );
                },
                child: const Text('Open editor'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-avatar-editor')));
  await tester.pumpAndSettle();
}

class _MemoryAvatarStorage implements ProfileAvatarStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> write(String key, String value) async {
    values[key] = value;
    return true;
  }
}
