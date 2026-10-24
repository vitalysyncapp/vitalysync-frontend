import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/adaptive/data/adaptive_nudge_api.dart';
import 'package:vitalysync/features/adaptive/data/wellness_content_api.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/personal_insight_card.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_coach.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_insight_store.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';
import 'package:vitalysync/shared/widgets/wellness_content_widgets.dart';
import 'package:vitalysync/l10n/app_copy.dart';

const content = <String, dynamic>{
  'nudge_type': 'recovery_break',
  'title': 'A little room for you',
  'message': 'Take one short off-screen pause.',
  'priority': 'high',
  'severity': 'high',
  'metadata': {
    'content_id': '1234567890abcdef1234567890abcdef',
    'surface': 'wellness',
    'action_id': 'screen_break',
    'evidence': 'Your recent check-in context.',
  },
};

http.Response echoEvent(http.Request request) {
  final body = jsonDecode(request.body) as Map<String, dynamic>;
  return http.Response(
    jsonEncode({
      'event': {...body, 'nudge_event_id': 3, 'status': 'shown'},
    }),
    201,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('response controls and acknowledgments have Taglish copy', () {
    for (final text in [
      'Another idea',
      'Not now',
      'Let’s find a different small step.',
      'Of course. We’ll give this some space.',
      'Thanks. We’ll adjust your suggestions.',
    ]) {
      expect(localizeAppCopy(text, const Locale('fil')), isNot(text));
    }
  });
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'app_language': 'english',
    }),
  );

  test(
    'concurrent impressions coalesce and later rebuilds reuse the saved event',
    () async {
      var requests = 0;
      await http.runWithClient(
        () async {
          await Future.wait([
            WellnessContentApi.respond(content, 'shown'),
            WellnessContentApi.respond(content, 'shown'),
          ]);
          await WellnessContentApi.respond(content, 'shown');
          expect(requests, 1);
          expect(
            (await WellnessContentApi.savedEvent(content))?['nudge_event_id'],
            3,
          );
        },
        () => MockClient((request) async {
          requests++;
          return echoEvent(request);
        }),
      );
    },
  );

  test(
    'failed responses do not overwrite local feedback or invalidate guidance',
    () async {
      var fail = false;
      await http.runWithClient(
        () async {
          await WellnessContentApi.respond(content, 'shown');
          final previous = await WellnessContentApi.savedEvent(content);
          final revision = WellnessContentApi.revision;
          fail = true;
          await expectLater(
            WellnessContentApi.respond(content, 'done'),
            throwsException,
          );
          expect(await WellnessContentApi.savedEvent(content), previous);
          expect(WellnessContentApi.revision, revision);
        },
        () => MockClient(
          (request) async =>
              fail ? http.Response('{}', 503) : echoEvent(request),
        ),
      );
    },
  );

  test('events are isolated by user and language', () async {
    await http.runWithClient(() async {
      await WellnessContentApi.respond(content, 'shown');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', 2);
      expect(await WellnessContentApi.savedEvent(content), isNull);
      await prefs.setInt('user_id', 1);
      await prefs.setString('app_language', 'tagalog');
      expect(await WellnessContentApi.savedEvent(content), isNull);
      await prefs.setString('app_language', 'english');
      expect(await WellnessContentApi.savedEvent(content), isNotNull);
    }, () => MockClient((request) async => echoEvent(request)));
  });

  test('fresh rules guidance takes precedence over older AI copy', () async {
    await OfflineCacheStore.saveJson(
      namespace: 'adaptive_nudge_recommendations',
      scope: '1_ai',
      data: {
        'recommendations': [
          {
            ...content,
            'message': 'Old AI text',
            'metadata': {'ai_enhanced': true},
          },
        ],
      },
    );
    await http.runWithClient(
      () async {
        final response = await AdaptiveNudgeApi.fetchRecommendations();
        expect(response.recommendations.single.message, content['message']);
      },
      () => MockClient((request) async {
        expect(request.url.queryParameters['record'], 'false');
        return http.Response(
          jsonEncode({
            'recommendations': [content],
          }),
          200,
        );
      }),
    );
  });

  test(
    'personal insight uses its own route and labels offline content',
    () async {
      await http.runWithClient(
        () async {
          final insight = await AdaptiveNudgeApi.fetchPersonalInsight();
          expect(insight?.title, content['title']);
        },
        () => MockClient((request) async {
          expect(request.url.path, '/api/adaptive/personal-insight');
          return http.Response(jsonEncode({'insight': content}), 200);
        }),
      );
      await http.runWithClient(() async {
        final cached = await AdaptiveNudgeApi.fetchPersonalInsight();
        expect(cached?.metadata['offline_cached'], true);
        expect(cached?.metadata['cached_at'], isNotNull);
      }, () => MockClient((_) async => throw http.ClientException('offline')));
    },
  );

  test('input changes invalidate guidance and nutrition caches', () async {
    await OfflineCacheStore.saveJson(
      namespace: 'personal_insight',
      scope: '1',
      data: {'insight': content},
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nutrition_assistant_insight', '{}');
    await WellnessContentApi.invalidate(notify: false);
    expect(
      await OfflineCacheStore.readLatestJson(
        namespace: 'personal_insight',
        scope: '1',
      ),
      isNull,
    );
    expect(prefs.getString('nutrition_assistant_insight'), isNull);
  });

  test('nutrition cache rejects another user or language', () async {
    final insight = NutritionInsight.fromJson({
      ...content,
      'id': 'nutrition',
      'generated_at': DateTime.now().toIso8601String(),
    });
    await NutritionInsightStore.instance.saveAssistantInsightForToday(insight);
    expect(
      await NutritionInsightStore.instance.readAssistantInsightForToday(),
      isNotNull,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', 2);
    expect(
      await NutritionInsightStore.instance.readAssistantInsightForToday(),
      isNull,
    );
    await prefs.setInt('user_id', 1);
    await prefs.setString('app_language', 'tagalog');
    expect(
      await NutritionInsightStore.instance.readAssistantInsightForToday(),
      isNull,
    );
  });

  test('backend order survives AI-enhanced lower priority recommendations', () {
    final high = AdaptiveNudgeRecommendation.fromJson(content);
    final low = AdaptiveNudgeRecommendation.fromJson({
      ...content,
      'nudge_type': 'maintenance',
      'priority': 'low',
      'metadata': {'ai_enhanced': true},
    });
    expect(prioritizeAssistantNudges([high, low]).first, high);
  });

  testWidgets(
    'response buttons fit a small screen with large text in dark mode',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final responses = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(2),
              ),
              child: NudgeResponseActions(
                enabled: true,
                onResponse: responses.add,
              ),
            ),
          ),
        ),
      );
      for (final label in ['Done', 'Another idea', 'Not now']) {
        await tester.tap(find.text(label));
      }
      expect(responses, ['done', 'another_idea', 'not_now']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NudgeResponseActions(
              enabled: false,
              onResponse: responses.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Done'));
      expect(responses.length, 3);
    },
  );

  testWidgets(
    'personal insight has expandable evidence and no action buttons',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 640),
                  textScaler: TextScaler.linear(2),
                ),
                child: PersonalInsightCard(
                  recommendation: AdaptiveNudgeRecommendation.fromJson(content),
                  isLoading: false,
                  learningState: null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Personal insights'), findsOneWidget);
      expect(find.text('Another idea'), findsNothing);
      await tester.tap(find.text('What this is based on'));
      await tester.pumpAndSettle();
      expect(find.text('Your recent check-in context.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'offscreen cards record exposure only after scrolling into view',
    (tester) async {
      var requests = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 250,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 900),
                        WellnessContentExposure(
                          content: content,
                          child: const SizedBox(
                            height: 100,
                            child: Text('Visible content'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(requests, 0);
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -950),
          );
          await tester.pumpAndSettle();
          expect(requests, 1);
          await tester.pump();
          expect(requests, 1);
        },
        () => MockClient((request) async {
          requests++;
          return echoEvent(request);
        }),
      );
    },
  );

  testWidgets(
    'insight feedback blocks duplicate taps and restores controls after failure',
    (tester) async {
      final pending = Completer<http.Response>();
      var responses = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PersonalInsightCard(
                  recommendation: AdaptiveNudgeRecommendation.fromJson(content),
                  isLoading: false,
                  learningState: null,
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.tap(find.byTooltip('Helpful'));
          await tester.pump();
          await tester.tap(find.byTooltip('Helpful'));
          expect(responses, 1);
          pending.complete(http.Response('{}', 503));
          await tester.pumpAndSettle();
          expect(
            find.text('Unable to save your response. Please try again.'),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.ancestor(
                    of: find.byIcon(Icons.thumb_up_outlined),
                    matching: find.byType(IconButton),
                  ),
                )
                .onPressed,
            isNotNull,
          );
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          if (body['interaction'] == 'shown') return echoEvent(request);
          responses++;
          return pending.future;
        }),
      );
    },
  );
  testWidgets('inactive IndexedStack tabs are not counted as seen', (
    tester,
  ) async {
    var requests = 0;
    await http.runWithClient(
      () async {
        Widget tabs(int index) => MaterialApp(
          home: Scaffold(
            body: IndexedStack(
              index: index,
              children: [
                const Text('Home'),
                WellnessContentExposure(
                  content: content,
                  child: const SizedBox(height: 100, child: Text('Insight')),
                ),
              ],
            ),
          ),
        );
        await tester.pumpWidget(tabs(0));
        await tester.pump();
        expect(requests, 0);
        await tester.pumpWidget(tabs(1));
        await tester.pumpAndSettle();
        expect(requests, 1);
      },
      () => MockClient((request) async {
        requests++;
        return echoEvent(request);
      }),
    );
  });

  test(
    'a language change during a request cannot populate the new locale cache',
    () async {
      final requested = Completer<void>();
      final response = Completer<http.Response>();
      await http.runWithClient(
        () async {
          final future = AdaptiveNudgeApi.fetchPersonalInsight();
          await requested.future;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_language', 'tagalog');
          response.complete(
            http.Response(jsonEncode({'insight': content}), 200),
          );
          expect(await future, isNull);
          expect(
            await OfflineCacheStore.readLatestJson(
              namespace: 'personal_insight',
              scope: '1',
            ),
            isNull,
          );
        },
        () => MockClient((request) async {
          requested.complete();
          return response.future;
        }),
      );
    },
  );
}
