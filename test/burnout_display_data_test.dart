import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/dashboard/data/burnout_display_data.dart';
import 'package:vitalysync/features/dashboard/data/burnout_score_api.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/onboarding/services/onboarding_service.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'user_id': 7}));

  test(
    'new users show a real baseline; missing baselines do not invent a score',
    () {
      const empty = BurnoutDisplayData();
      expect(empty.score, isNull);
      expect(empty.status, 'No estimate yet');
      const baseline = BurnoutDisplayData(
        baseline: OnboardingDefaults(
          initialBurnoutScore: 35,
          initialBurnoutLevel: 'Moderate',
        ),
      );
      expect(baseline.score, 35);
      expect(baseline.isBaseline, isTrue);
      expect(baseline.sourceLabel, contains('Baseline'));
    },
  );

  for (final version in [
    'burnout_engine_v4_decay_v1',
    'burnout_engine_v5_daily14_v1',
    'burnout_engine_v6_core9_v1',
  ]) {
    test('home and dashboard use the saved estimate for $version', () async {
      var requests = 0;
      final response = Completer<http.Response>();
      await http.runWithClient(
        () async {
          final home = BurnoutDisplayData.load();
          final dashboard = BurnoutDisplayData.load();
          await Future<void>.delayed(Duration.zero);
          expect(requests, 1);
          response.complete(
            http.Response(
              jsonEncode({'latest_score': scoreJson(62, version)}),
              200,
            ),
          );
          final displays = await Future.wait([home, dashboard]);
          for (final display in displays) {
            expect(display.score, 62);
            expect(display.isBaseline, isFalse);
            expect(display.riskLevel, 'high');
            expect(display.sourceLabel, contains('Today'));
          }
        },
        () => MockClient((_) {
          requests++;
          return response.future;
        }),
      );
    });
  }

  test(
    'returning users retain their last dated score outside the trend window',
    () async {
      final oldScore = {
        ...scoreJson(48, 'burnout_engine_v4_decay_v1'),
        'score_date': '2025-01-10',
      };
      await http.runWithClient(
        () async {
          final display = await BurnoutDisplayData.load();
          expect(display.score, 48);
          expect(display.latestScore?.scoreDate, '2025-01-10');
          expect(display.sourceLabel, contains('Jan 10'));
          expect(display.patternSummary?.timeline, isEmpty);
        },
        () => MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.path.endsWith('/latest')
                  ? {'has_score': true, 'score': oldScore}
                  : {'latest_score': null},
            ),
            200,
          ),
        ),
      );
    },
  );

  test(
    'manual refresh bypasses the cache and an empty server score clears stale data',
    () async {
      await OfflineCacheStore.saveJson(
        namespace: 'burnout_latest_score',
        scope: '7',
        data: {'score': scoreJson(80, 'old')},
      );
      await OfflineCacheStore.saveJson(
        namespace: 'burnout_pattern_summary',
        scope: '7_${LogApi.todayKey()}',
        data: {'latest_score': scoreJson(80, 'old')},
      );
      await http.runWithClient(
        () async {
          final display = await BurnoutDisplayData.load(forceRefresh: true);
          expect(display.score, isNull);
          expect(
            await BurnoutScoreApi.fetchLatestScore(forceRefresh: true),
            isNull,
          );
        },
        () => MockClient(
          (_) async =>
              http.Response('{"latest_score":null,"has_score":false}', 200),
        ),
      );
      final cache = await OfflineCacheStore.readLatestJson(
        namespace: 'burnout_latest_score',
        scope: '7',
      );
      expect(cache?['score'], isNull);
    },
  );

  test('zero inputs are displayed as zero while missing inputs stay empty', () {
    expect(LogApi.formatSleepHours(0), '0h');
    expect(LogApi.formatHydrationLiters(0), '0L');
    expect(LogApi.formatSleepHours(null), '--');
    expect(LogApi.formatHydrationLiters(null), '--');
  });
}

Map<String, dynamic> scoreJson(num value, String version) => {
  'score_date': LogApi.todayKey(),
  'overall_score': value,
  'risk_level': 'high',
  'confidence_score': 90,
  'completeness_score': 100,
  'scoring_version': version,
};
