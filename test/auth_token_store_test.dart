import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/shared/config/api_config.dart';
import 'package:vitalysync/shared/preferences/auth_token_store.dart';

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
        'Authorization': 'Bearer header-token',
      });
    },
  );
}
