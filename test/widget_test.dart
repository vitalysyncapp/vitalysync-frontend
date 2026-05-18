import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/app/app.dart';

final Uint8List _transparentImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn8q3sAAAAASUVORK5CYII=',
);

final ByteData _assetManifestBytes = const StandardMessageCodec().encodeMessage(
  <Object?, Object?>{
    'assets/images/logo.png': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/logo.png'},
    ],
    'assets/images/user.png': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/user.png'},
    ],
    'assets/images/male Student.png': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/male Student.png'},
    ],
    'assets/images/female Student.png': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/female Student.png'},
    ],
    'assets/images/business-man.png': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/business-man.png'},
    ],
    'assets/images/businesswoman.png': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/businesswoman.png'},
    ],
  },
)!;

ByteData _byteDataFromString(String value) {
  return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
}

String _decodeAssetKey(ByteData? message) {
  if (message == null) return '';

  final bytes = message.buffer.asUint8List(
    message.offsetInBytes,
    message.lengthInBytes,
  );
  return Uri.decodeFull(utf8.decode(bytes));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = _decodeAssetKey(message);

          if (key == 'AssetManifest.bin') {
            return _assetManifestBytes;
          }

          if (key == 'AssetManifest.json') {
            return _byteDataFromString('{}');
          }

          if (key == 'FontManifest.json') {
            return _byteDataFromString('[]');
          }

          return ByteData.sublistView(_transparentImageBytes);
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('shows the login flow when no saved session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('returns to login when a saved session has no token', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'email': 'tester@example.com',
      'user_id': 1,
      'username': 'Tester',
      'onboarding_completed': true,
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
