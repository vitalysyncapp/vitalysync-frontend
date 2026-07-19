import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/shared/config/api_config.dart';
import 'package:vitalysync/shared/preferences/auth_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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
