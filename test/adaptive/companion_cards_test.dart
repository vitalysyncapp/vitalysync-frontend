import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/adaptive/data/adaptive_nudge_api.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/personal_insight_card.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_coach.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';
import '../helpers/test_helpers.dart';

const smart = <String, dynamic>{
  'title': 'Make room for a pause',
  'message':
      'Before your next task, take a two-minute break away from your screen.\n\nThere is no need to rush.',
  'nudge_type': 'maintenance',
  'priority': 'low',
  'severity': 'steady',
  'metadata': {
    'content_id': '1234567890abcdef1234567890abcdef',
    'action_id': 'screen_break',
    'context_hash': 'today',
    'surface': 'wellness',
    'evidence': 'Hidden smart evidence',
    'ai_why_this_matters': 'Hidden legacy evidence',
  },
};

Widget panel() => AssistantExperiencePanel(
  message: 'A small step for today',
  emoji: 'sparkles',
  recommendations: const [],
  adaptiveNudges: [AdaptiveNudgeRecommendation.fromJson(smart)],
  nutritionInsight: NutritionInsight.fromJson({
    'id': 'nutrition_one',
    'title': 'A fresh addition',
    'message': 'Add a fruit you enjoy to your next meal.',
    'confidence': 'low',
    'source': 'nutrition',
    'generated_at': DateTime.now().toIso8601String(),
    'metadata': {
      'surface': 'nutrition',
      'evidence': 'Nutrition context stays visible',
    },
  }),
  hasLoadedAdaptiveNudges: true,
  hasLoadedNutritionInsight: true,
  onRefreshRecommendations: () async => [],
  onRefreshAdaptiveNudges: ({bool forceRefresh = false}) async => [],
  onRefreshNutritionInsight: ({bool forceRefresh = false}) async => null,
  onRefreshEnvironment: () async => null,
  checkInStatusLoader: () async => const CheckInStatus(
    requiredMode: CheckInMode.daily,
    hasTodayLog: false,
    schedule: CheckInSchedule(),
  ),
  todayLogLoader: () async => {
    'streak': {'current_streak': 0},
  },
  useSafeAreaPadding: false,
);

Map<String, dynamic> insight() => {
  ...smart,
  'title': 'Your week, beyond a single score',
  'message':
      'Your recent logs bring together sleep, movement, and meal logging. The highlights show the observations and the days behind them.',
  'metadata': {
    ...smart['metadata'] as Map,
    'surface': 'dashboard',
    'period': {'start_date': '2026-10-17', 'end_date': '2026-10-23'},
    'evidence': 'Based on the days you recorded. Missing days remain unknown.',
    'highlights': [
      {
        'topic': 'sleep',
        'label': 'Sleep',
        'observation':
            'Sleep averaged 7 h across 4 recorded days. That is 0.5 h higher than the previous week.',
      },
      {
        'topic': 'activity',
        'label': 'Daily steps',
        'observation': 'Daily steps averaged 4,200 across 3 recorded days.',
      },
      {
        'topic': 'nutrition',
        'label': 'Meal logging',
        'observation':
            'You recorded 6 meals across 3 days. This describes your logs, not everything you ate.',
      },
    ],
  },
};

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    for (final size in [const Size(320, 720), const Size(900, 450)]) {
      testWidgets(
        'personal insights fits ${size.width}px ${dark ? 'dark' : 'light'} with enlarged text',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(2),
                  ),
                  child: SingleChildScrollView(
                    child: PersonalInsightCard(
                      recommendation: AdaptiveNudgeRecommendation.fromJson(
                        insight(),
                      ),
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
          expect(find.text('Sleep'), findsOneWidget);
          expect(find.text('Daily steps'), findsOneWidget);
          expect(find.text('Meal logging'), findsOneWidget);
          expect(find.text('Oct 17 – Oct 23'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Smart evidence is hidden, Nutrition context retained, including overlay-sized layout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: panel()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hidden smart evidence'), findsNothing);
      expect(find.text('Hidden legacy evidence'), findsNothing);
      expect(find.text('Nutrition context stays visible'), findsOneWidget);
      expect(find.text(smart['message'] as String), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Another idea keeps card visible until replacement resolves and ignores double taps',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'app_language': 'english',
      });
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pending = Completer<http.Response>();
      var requests = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(MaterialApp(home: Scaffold(body: panel())));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.ensureVisible(find.text('Another idea').first);
          await tester.tap(find.text('Another idea').first);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Another idea').first);
          await tester.pump();
          expect(requests, 1);
          expect(find.text(smart['message'] as String), findsOneWidget);
          expect(find.text('Finding another idea…'), findsOneWidget);
          pending.complete(
            http.Response(
              jsonEncode({
                'recommendations': [
                  {
                    ...smart,
                    'title': 'An easier evening',
                    'message': 'Put your phone aside for a few quiet minutes.',
                    'metadata': {
                      ...smart['metadata'] as Map,
                      'content_id': '2234567890abcdef1234567890abcdef',
                      'action_id': 'easy_evening',
                    },
                  },
                ],
                'selection': {'status': 'available', 'can_revisit': false},
              }),
              200,
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            find.text('Put your phone aside for a few quiet minutes.'),
            findsOneWidget,
          );
          expect(find.text(smart['message'] as String), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/nudges/recommendations')) {
            requests++;
            return pending.future;
          }
          if (request.url.path.endsWith('/nudge-events') &&
              request.method == 'POST') {
            return http.Response(
              jsonEncode({
                'event': {
                  ...jsonDecode(request.body) as Map,
                  'nudge_event_id': 1,
                  'status': 'shown',
                },
              }),
              201,
            );
          }
          return http.Response('{}', 200);
        }),
      );
    },
  );

  testWidgets(
    'feedback from an older insight never attaches to the replacement',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'app_language': 'english',
      });
      final pending = Completer<http.Response>();
      Map<String, dynamic>? feedbackBody;
      Widget card(Map<String, dynamic> data) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalInsightCard(
              recommendation: AdaptiveNudgeRecommendation.fromJson(data),
              isLoading: false,
              learningState: null,
            ),
          ),
        ),
      );
      await http.runWithClient(
        () async {
          await tester.pumpWidget(card(smart));
          await tester.pump();
          await tester.tap(find.byTooltip('Helpful'));
          await tester.pump();
          final replacement = {
            ...smart,
            'title': 'A new observation',
            'metadata': {
              ...smart['metadata'] as Map,
              'content_id': '2234567890abcdef1234567890abcdef',
            },
          };
          await tester.pumpWidget(card(replacement));
          await tester.pump();
          pending.complete(
            http.Response(
              jsonEncode({
                'event': {
                  ...feedbackBody!,
                  'nudge_event_id': 1,
                  'status': 'accepted',
                },
              }),
              201,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.thumb_up_rounded), findsNothing);
          expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
          expect(
            (feedbackBody!['metadata'] as Map)['content_id'],
            (smart['metadata'] as Map)['content_id'],
          );
        },
        () => MockClient((request) async {
          final body = Map<String, dynamic>.from(
            jsonDecode(request.body) as Map,
          );
          if (body['interaction'] == 'like') {
            feedbackBody = body;
            return pending.future;
          }
          return http.Response(
            jsonEncode({
              'event': {...body, 'nudge_event_id': 1, 'status': 'shown'},
            }),
            201,
          );
        }),
      );
    },
  );

  testWidgets(
    'renders light and dark insight previews for optional visual inspection',
    (tester) async {
      const output = String.fromEnvironment('COMPANION_PREVIEW_DIR');
      if (output.isEmpty) return;
      const fontDir = String.fromEnvironment('COMPANION_FONT_DIR');
      if (fontDir.isNotEmpty) {
        await tester.runAsync(() async {
          for (final entry in {
            'Preview': 'roboto-regular.ttf',
            'MaterialIcons': 'materialicons-regular.otf',
          }.entries) {
            final loader = FontLoader(entry.key)
              ..addFont(
                File(
                  '$fontDir/${entry.value}',
                ).readAsBytes().then(ByteData.sublistView),
              );
            await loader.load();
          }
        });
      }
      await tester.binding.setSurfaceSize(const Size(390, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final dark in [false, true]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
              fontFamily: 'Preview',
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: key,
                  child: Container(
                    color: dark
                        ? const Color(0xff121922)
                        : const Color(0xffeff9f6),
                    padding: const EdgeInsets.all(16),
                    child: PersonalInsightCard(
                      recommendation: AdaptiveNudgeRecommendation.fromJson(
                        insight(),
                      ),
                      isLoading: false,
                      learningState: null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File(
            '$output/insights_${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }
    },
  );
}
