import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/quick_check_in_preset_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 7});
  });

  test('successful fetch persists an account-scoped cache', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/api/logs/check-in-presets'));
      return http.Response(
        jsonEncode({
          'presets': [_presetJson],
        }),
        200,
      );
    });
    final api = QuickCheckInPresetApi(client: client);

    final fetched = await api.fetch();
    final cached = await api.readCache();

    expect(fetched.single.name, 'Productive');
    expect(cached.single.presetId, 4);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey('${QuickCheckInPresetApi.cacheKeyPrefix}7'),
      isTrue,
    );
  });

  test(
    'offline mutation is rejected without changing cached presets',
    () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 7,
        '${QuickCheckInPresetApi.cacheKeyPrefix}7': jsonEncode([_presetJson]),
      });
      final api = QuickCheckInPresetApi(
        client: MockClient((_) async => throw Exception('offline')),
      );
      final preset = (await api.readCache()).single;

      await expectLater(
        api.update(preset),
        throwsA(
          isA<QuickCheckInPresetException>().having(
            (error) => error.message,
            'message',
            contains('Connect to the internet'),
          ),
        ),
      );
      expect((await api.readCache()).single.name, 'Productive');
    },
  );
}

const _presetJson = {
  'preset_id': 4,
  'name': 'Productive',
  'check_in_type': 'daily',
  'avatar_id': 'focused',
  'daily': {
    'questionnaire_version': 'daily_14_v2',
    'sleep_hours': 7.5,
    'sleep_quality': 3,
    'mood_index': 4,
    'energy_level': 4,
    'hydration_liters': 2,
    'workload_hours_band': '5-6 hours',
    'exercise_names': ['Walking'],
    'symptom_names': ['None'],
    'habit_names': ['Quiet break'],
    'perceived_stress_level': 3,
    'break_quality_level': 4,
    'daily_detachment_level': 2,
    'daily_focus_level': 4,
    'daily_accomplishment_level': 5,
  },
  'weekly_answers': null,
  'created_at': '2026-10-27T00:00:00.000Z',
  'updated_at': '2026-10-27T00:00:00.000Z',
};
