import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/adaptive/data/adaptive_nudge_api.dart';
import 'package:vitalysync/features/adaptive/data/wellness_content_api.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';

Map<String, dynamic> nudge(String message, {DateTime? due}) => {
  'nudge_type': 'recovery_break',
  'title': 'A small pause',
  'message': message,
  'metadata': {
    'content_id': '1234567890abcdef1234567890abcdef',
    'action_id': message,
    'generated_at': DateTime.now()
        .subtract(const Duration(hours: 1))
        .toIso8601String(),
    'next_due_at': (due ?? DateTime.now().add(const Duration(hours: 7)))
        .toIso8601String(),
    'nudge_cooldown_hours': 8,
  },
};

http.Response response(Map<String, dynamic> item) => http.Response(
  jsonEncode({
    'recommendations': [item],
    'selection': {'status': 'available'},
  }),
  200,
);

Future<void> save(Map<String, dynamic> item) => OfflineCacheStore.saveJson(
  namespace: 'assistant_nudge_recommendations',
  scope: '1_persistent_v1',
  data: {
    'recommendations': [item],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'app_language': 'english',
    }),
  );

  test(
    'reopened engines reuse persisted copy across midnight and data updates',
    () async {
      final saved = nudge('Original');
      saved['metadata']['generated_at'] = DateTime.now()
          .subtract(const Duration(hours: 12))
          .toIso8601String();
      await save(saved);
      final prefs = await SharedPreferences.getInstance();
      final disk = {for (final key in prefs.getKeys()) key: prefs.get(key)!};
      // Recreate the preference instance from disk, as after an app restart.
      SharedPreferences.setMockInitialValues(disk);
      await WellnessContentApi.invalidate(notify: false);
      await http.runWithClient(
        () async {
          for (var i = 0; i < 2; i++) {
            final result =
                await AdaptiveNudgeApi.fetchAssistantRecommendations();
            expect(result.recommendations.single.message, 'Original');
          }
        },
        () => MockClient(
          (_) async => fail('A current nudge must not be fetched again'),
        ),
      );
    },
  );

  test('a due nudge fetches and persists its replacement', () async {
    await save(
      nudge('Old', due: DateTime.now().subtract(const Duration(seconds: 1))),
    );
    var requests = 0;
    await http.runWithClient(
      () async {
        final result = await AdaptiveNudgeApi.fetchAssistantRecommendations();
        expect(result.recommendations.single.message, 'New');
        final reopened = await AdaptiveNudgeApi.fetchAssistantRecommendations();
        expect(reopened.recommendations.single.message, 'New');
        expect(requests, 1);
      },
      () => MockClient((request) async {
        requests++;
        expect(request.url.queryParameters['selection_mode'], 'default');
        return response(nudge('New'));
      }),
    );
  });

  test(
    'manual refresh and another idea both update the shared cache',
    () async {
      await save(nudge('Original'));
      var requests = 0;
      await http.runWithClient(
        () async {
          final refreshed =
              await AdaptiveNudgeApi.fetchAssistantRecommendations(
                forceRefresh: true,
              );
          expect(refreshed.recommendations.single.message, 'Refresh');
          final alternative = await AdaptiveNudgeApi.anotherIdea(
            excludeActionIds: ['Refresh'],
          );
          expect(alternative.item?.message, 'Alternative');
          final reopened =
              await AdaptiveNudgeApi.fetchAssistantRecommendations();
          expect(reopened.recommendations.single.message, 'Alternative');
          expect(requests, 2);
        },
        () => MockClient((request) async {
          requests++;
          expect(request.url.queryParameters['selection_mode'], 'next');
          return response(nudge(requests == 1 ? 'Refresh' : 'Alternative'));
        }),
      );
    },
  );

  test(
    'failed refresh retains the last nudge without extending its due time',
    () async {
      final due = DateTime.now().subtract(const Duration(minutes: 1));
      await save(nudge('Original', due: due));
      // An independent recommendation consumer must not replace assistant copy
      // when a network error falls back to its separate cache.
      await OfflineCacheStore.saveJson(
        namespace: 'adaptive_nudge_recommendations',
        scope: '1_ai_companion_v2',
        data: {
          'recommendations': [nudge('Different service')],
        },
      );
      await http.runWithClient(() async {
        for (final force in [false, true]) {
          final result = await AdaptiveNudgeApi.fetchAssistantRecommendations(
            forceRefresh: force,
          );
          expect(result.recommendations.single.message, 'Original');
          expect(
            result.recommendations.single.metadata['next_due_at'],
            due.toIso8601String(),
          );
        }
      }, () => MockClient((_) async => throw http.ClientException('offline')));
      final cached = await OfflineCacheStore.readLatestJson(
        namespace: 'assistant_nudge_recommendations',
        scope: '1_persistent_v1',
      );
      expect(cached?['recommendations'][0]['message'], 'Original');
      expect(
        cached?['recommendations'][0]['metadata']['next_due_at'],
        due.toIso8601String(),
      );
    },
  );

  test('cached content is isolated by account and language', () async {
    await save(nudge('Original'));
    final prefs = await SharedPreferences.getInstance();
    var requests = 0;
    await http.runWithClient(
      () async {
        await prefs.setInt('user_id', 2);
        expect(
          (await AdaptiveNudgeApi.fetchAssistantRecommendations())
              .recommendations
              .single
              .message,
          'Other user',
        );
        await prefs.setInt('user_id', 1);
        await prefs.setString('app_language', 'tagalog');
        expect(
          (await AdaptiveNudgeApi.fetchAssistantRecommendations())
              .recommendations
              .single
              .message,
          'Other language',
        );
        await prefs.setString('app_language', 'english');
        expect(
          (await AdaptiveNudgeApi.fetchAssistantRecommendations())
              .recommendations
              .single
              .message,
          'Original',
        );
        expect(requests, 2);
      },
      () => MockClient((_) async {
        requests++;
        return response(nudge(requests == 1 ? 'Other user' : 'Other language'));
      }),
    );
  });

  test('concurrent consumers share one request', () async {
    var requests = 0;
    await http.runWithClient(
      () async {
        final results = await Future.wait([
          AdaptiveNudgeApi.fetchAssistantRecommendations(),
          AdaptiveNudgeApi.fetchAssistantRecommendations(),
        ]);
        expect(requests, 1);
        expect(results.map((item) => item.recommendations.single.message), [
          'Shared',
          'Shared',
        ]);
      },
      () => MockClient((_) async {
        requests++;
        await Future<void>.delayed(Duration.zero);
        return response(nudge('Shared'));
      }),
    );
  });

  test('an account switch during a request cannot save its result', () async {
    final started = Completer<void>();
    final pending = Completer<http.Response>();
    await http.runWithClient(
      () async {
        final work = AdaptiveNudgeApi.fetchAssistantRecommendations();
        await started.future;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', 2);
        pending.complete(response(nudge('Old account')));
        expect((await work).recommendations, isEmpty);
        expect(
          await OfflineCacheStore.readLatestJson(
            namespace: 'assistant_nudge_recommendations',
            scope: '2_persistent_v1',
          ),
          isNull,
        );
      },
      () => MockClient((_) {
        started.complete();
        return pending.future;
      }),
    );
  });
}
