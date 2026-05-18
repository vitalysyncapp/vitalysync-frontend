import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Uint8List transparentImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn8q3sAAAAASUVORK5CYII=',
);

final ByteData assetManifestBytes = const StandardMessageCodec().encodeMessage(
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

ByteData byteDataFromString(String value) {
  return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
}

String decodeAssetKey(ByteData? message) {
  if (message == null) return '';

  final bytes = message.buffer.asUint8List(
    message.offsetInBytes,
    message.lengthInBytes,
  );
  return Uri.decodeFull(utf8.decode(bytes));
}

Future<void> configureTestAssets() async {
  await initializeDateFormatting('en_US');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = decodeAssetKey(message);

        if (key == 'AssetManifest.bin') {
          return assetManifestBytes;
        }

        if (key == 'AssetManifest.json') {
          return byteDataFromString('{}');
        }

        if (key == 'FontManifest.json') {
          return byteDataFromString('[]');
        }

        return ByteData.sublistView(transparentImageBytes);
      });
}

void clearTestAssets() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
}

void configureLoggedInSession({
  int userId = 1,
  bool onboardingCompleted = true,
}) {
  SharedPreferences.setMockInitialValues({
    'email': 'tester@example.com',
    'user_id': userId,
    'username': 'Tester',
    'auth_access_token': 'test-token',
    'onboarding_completed': onboardingCompleted,
  });
}

Future<void> pumpTestApp(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}
