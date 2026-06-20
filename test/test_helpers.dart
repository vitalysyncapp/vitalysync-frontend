import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Uint8List transparentImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn8q3sAAAAASUVORK5CYII=',
);

const minimalSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="80" viewBox="0 0 120 80"><rect width="120" height="80" fill="#DDF7EF"/><circle cx="60" cy="40" r="24" fill="#1EAD83"/></svg>';

const minimalLottie =
    '{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":120,"h":120,"nm":"test","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"circle","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[60,60,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":0,"k":[100,100,100]}},"ao":0,"shapes":[{"ty":"el","p":{"a":0,"k":[0,0]},"s":{"a":0,"k":[60,60]},"nm":"ellipse"},{"ty":"fl","c":{"a":0,"k":[0.12,0.68,0.51,1]},"o":{"a":0,"k":100},"r":1,"bm":0,"nm":"fill"}],"ip":0,"op":60,"st":0,"bm":0}]}';

final ByteData assetManifestBytes = const StandardMessageCodec().encodeMessage(
  <Object?, Object?>{
    'assets/images/logo.png': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/logo.png'},
    ],
    'assets/images/auth_healthy_lifestyle.svg': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/auth_healthy_lifestyle.svg'},
    ],
    'assets/images/auth_workout.svg': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/auth_workout.svg'},
    ],
    'assets/images/auth_work_stress.svg': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/auth_work_stress.svg'},
    ],
    'assets/images/auth_dashboard.svg': <Object?>[
      <Object?, Object?>{'asset': 'assets/images/auth_dashboard.svg'},
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

        if (key.endsWith('.svg')) {
          return byteDataFromString(minimalSvg);
        }

        if (key.endsWith('.json')) {
          return byteDataFromString(minimalLottie);
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
