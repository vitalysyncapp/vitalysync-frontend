import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/shared/config/api_config.dart';
import 'package:vitalysync/shared/preferences/auth_token_store.dart';
import 'package:vitalysync/shared/preferences/user_session.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'token store saves, reads, and clears tokens through its abstraction',
    () async {
      final store = AuthTokenStore(useSecureStorage: false);

      await store.saveToken('  test-token  ');
      expect(await store.readToken(), 'test-token');

      await store.clearToken();
      expect(await store.readToken(), isNull);
    },
  );

  test('token store reads legacy shared preference tokens', () async {
    SharedPreferences.setMockInitialValues({
      AuthTokenStore.tokenKey: 'legacy-token',
    });
    final store = AuthTokenStore(useSecureStorage: false);

    expect(await store.readToken(), 'legacy-token');
  });

  test(
    'token inspection distinguishes valid, expired, and malformed tokens',
    () {
      final store = AuthTokenStore(useSecureStorage: false);
      final now = DateTime.utc(2026, 8, 21, 12);

      final valid = store.inspectToken(
        testAuthToken(expiresAt: now.add(const Duration(minutes: 5))),
        now: now,
      );
      final expired = store.inspectToken(
        testAuthToken(expiresAt: now),
        now: now,
      );

      expect(valid.validity, AuthTokenValidity.valid);
      expect(valid.expiresAt, now.add(const Duration(minutes: 5)));
      expect(expired.validity, AuthTokenValidity.expired);
      expect(
        store.inspectToken('not-a-token').validity,
        AuthTokenValidity.malformed,
      );
      expect(store.inspectToken(null).validity, AuthTokenValidity.missing);
    },
  );

  test(
    'token store keeps a shared fallback when secure storage is available',
    () async {
      final secureValues = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(secureValues);
      final store = AuthTokenStore(useSecureStorage: true);

      await store.saveToken('  secure-token  ');

      final prefs = await SharedPreferences.getInstance();
      expect(secureValues[AuthTokenStore.tokenKey], 'secure-token');
      expect(prefs.getString(AuthTokenStore.tokenKey), 'secure-token');

      secureValues.remove(AuthTokenStore.tokenKey);
      expect(await store.readToken(), 'secure-token');

      await store.clearToken();
      expect(prefs.getString(AuthTokenStore.tokenKey), isNull);
      expect(await store.readToken(), isNull);
    },
  );

  test('token store migrates secure-only tokens into the fallback', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthTokenStore.tokenKey: 'secure-existing-token',
    });
    final store = AuthTokenStore(useSecureStorage: true);

    expect(await store.readToken(), 'secure-existing-token');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AuthTokenStore.tokenKey), 'secure-existing-token');
  });

  test(
    'api config builds authorization headers from the token store path',
    () async {
      SharedPreferences.setMockInitialValues({
        AuthTokenStore.tokenKey: 'header-token',
      });

      expect(await ApiConfig.authHeaders(), {
        'Accept-Language': 'en',
        'Authorization': 'Bearer header-token',
      });
    },
  );

  test('user session saves and loads email verification state', () async {
    await UserSessionController.instance.saveUser({
      'user_id': 7,
      'email': 'student@example.com',
      'username': 'Student',
      'onboarding_completed': false,
      'email_verified': true,
    });

    final session = await UserSessionController.instance.load();

    expect(session.emailVerified, isTrue);
    expect(session.email, 'student@example.com');
  });

  test(
    'session cleanup can retain only the last successful login email',
    () async {
      await UserSessionController.instance.saveUser({
        'user_id': 7,
        'email': 'student@example.com',
        'username': 'Student',
        'onboarding_completed': true,
      }, authToken: testAuthToken());

      await UserSessionController.instance.clearSession(
        keepLastLoginEmail: true,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        await UserSessionController.instance.loadLastLoginEmail(),
        'student@example.com',
      );
      expect(prefs.getString('email'), isNull);
      expect(prefs.getInt('user_id'), isNull);
      expect(await AuthTokenStore.instance.readToken(), isNull);
    },
  );
}
