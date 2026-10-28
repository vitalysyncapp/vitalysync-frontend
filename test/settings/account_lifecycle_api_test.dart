import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/settings/data/account_lifecycle_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_access_token': 'test-access-token',
    });
  });

  test('login challenge requires the stable reactivation code and dates', () {
    final challenge = AccountReactivationChallenge.fromLoginResponse(423, {
      'code': 'ACCOUNT_REACTIVATION_REQUIRED',
      'reactivation_token': 'grant',
      'reactivation_deadline': '2026-09-08T00:00:00.000Z',
      'retention_expires_at': '2031-07-30T00:00:00.000Z',
    });

    expect(challenge, isNotNull);
    expect(challenge!.reactivationToken, 'grant');
    expect(
      AccountReactivationChallenge.fromLoginResponse(423, {
        'code': 'ACCOUNT_REACTIVATION_EXPIRED',
      }),
      isNull,
    );
  });

  test(
    'deactivate and clear-data requests send passwords to backend routes',
    () async {
      final requests = <http.Request>[];
      final api = AccountLifecycleApi(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }),
      );

      await api.deactivate(
        currentPassword: 'last-password',
        confirmation: 'CONFIRM',
      );
      await api.clearData(currentPassword: 'last-password');

      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/api/account/deactivate');
      expect(jsonDecode(requests[0].body), {
        'current_password': 'last-password',
        'confirmation': 'CONFIRM',
      });
      expect(requests[1].method, 'DELETE');
      expect(requests[1].url.path, '/api/account/data');
      expect(jsonDecode(requests[1].body), {
        'current_password': 'last-password',
      });
    },
  );

  test(
    'reactivation uses only its grant and returns the session payload',
    () async {
      late http.Request captured;
      final api = AccountLifecycleApi(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'access_token': 'access',
              'user': {'user_id': 7},
            }),
            200,
          );
        }),
      );
      final challenge = AccountReactivationChallenge(
        reactivationToken: 'reactivation-grant',
        reactivationDeadline: DateTime.utc(2026, 9, 8),
        retentionExpiresAt: DateTime.utc(2031, 7, 30),
      );

      final result = await api.reactivate(challenge);

      expect(captured.url.path, '/api/account/reactivate');
      expect(jsonDecode(captured.body), {
        'reactivation_token': 'reactivation-grant',
      });
      expect(result['access_token'], 'access');
    },
  );

  test('backend lifecycle errors preserve stable codes', () async {
    final api = AccountLifecycleApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The reactivation period has ended.',
            'code': 'ACCOUNT_REACTIVATION_EXPIRED',
          }),
          423,
        ),
      ),
    );

    await expectLater(
      api.reactivate(
        AccountReactivationChallenge(
          reactivationToken: 'expired',
          reactivationDeadline: DateTime.utc(2026, 1, 1),
          retentionExpiresAt: DateTime.utc(2031, 1, 1),
        ),
      ),
      throwsA(
        isA<AccountLifecycleException>()
            .having(
              (error) => error.code,
              'code',
              'ACCOUNT_REACTIVATION_EXPIRED',
            )
            .having(
              (error) => error.message,
              'message',
              'The reactivation period has ended.',
            ),
      ),
    );
  });
}
