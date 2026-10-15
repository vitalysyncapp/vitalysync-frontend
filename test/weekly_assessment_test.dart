import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/weekly_assessment_api.dart';
import 'package:vitalysync/features/log/presentation/widgets/weekly_assessment_card.dart';
import 'package:vitalysync/features/onboarding/data/burnout_baseline_questions.dart';
import 'package:vitalysync/features/onboarding/widgets/likert_question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'user_id': 7}));

  Map<String, int> answers(int value) => {
    for (final section in kBurnoutWeeklySections)
      for (final question in section.questions) question.questionKey: value,
  };

  test(
    'baseline keeps 9/5/8 while weekly uses 5/3/3 on the same 1-5 scale',
    () {
      expect(kBurnoutBaselineSections.map((s) => s.questions.length), [
        9,
        5,
        8,
      ]);
      expect(kBurnoutWeeklySections.map((s) => s.questions.length), [5, 3, 3]);
      expect(answers(3).length, 11);
      expect(kBurnoutBaselineScale.map((o) => o.value), [1, 2, 3, 4, 5]);
    },
  );

  test(
    'weekly offline queue survives retry without modifying daily logs or streaks',
    () async {
      final today = LogApi.todayKey();
      final offline = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      await http.runWithClient(() async {
        expect(await WeeklyAssessmentApi.save(today, answers(3)), isFalse);
        expect(await WeeklyAssessmentApi.draft(today), answers(3));
      }, () => offline);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().any(
          (key) => key.contains('streak') || key.contains('daily_logs'),
        ),
        isFalse,
      );
      var posts = 0;
      final online = MockClient((request) async {
        if (request.method == 'POST') {
          posts++;
          final body = jsonDecode(request.body) as Map;
          expect(body['questionnaire_version'], kWeeklyQuestionnaireVersion);
          expect((body['answers'] as Map).length, 11);
          expect(body.containsKey('daily'), isFalse);
          return http.Response('{}', 200);
        }
        return http.Response(
          jsonEncode({
            'completed_today': true,
            'due_date': today,
            'history': [],
          }),
          200,
        );
      });
      await http.runWithClient(() async {
        final result = await WeeklyAssessmentApi.load();
        expect(result['pending'], isEmpty);
        await WeeklyAssessmentApi.load();
      }, () => online);
      expect(posts, 1);
    },
  );

  test(
    'invalid weekly submissions are not disguised as successful offline saves',
    () async {
      await http.runWithClient(
        () async {
          await expectLater(
            WeeklyAssessmentApi.save(LogApi.todayKey(), answers(3)),
            throwsA(isA<Exception>()),
          );
        },
        () => MockClient(
          (_) async => http.Response('{"message":"Unsupported version"}', 400),
        ),
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'weekly_assessment_pending_7',
        ),
        isNull,
      );
    },
  );

  test(
    'sync and a concurrent offline edit preserve the latest weekly answers',
    () async {
      final today = LogApi.todayKey();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'weekly_assessment_pending_7',
        jsonEncode({
          today: {
            'due_date': today,
            'response_date': today,
            'questionnaire_version': kWeeklyQuestionnaireVersion,
            'answers': answers(3),
          },
        }),
      );
      final syncStarted = Completer<void>();
      final releaseSync = Completer<void>();
      var posts = 0;
      await http.runWithClient(
        () async {
          final loading = WeeklyAssessmentApi.load();
          await syncStarted.future;
          final saving = WeeklyAssessmentApi.save(today, answers(5));
          releaseSync.complete();
          await loading;
          expect(await saving, isFalse);
          expect(await WeeklyAssessmentApi.draft(today), answers(5));
        },
        () => MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            if (posts == 1) {
              syncStarted.complete();
              await releaseSync.future;
              return http.Response('{}', 200);
            }
            throw http.ClientException('offline');
          }
          return http.Response(jsonEncode({'due_date': today}), 200);
        }),
      );
      expect(posts, 2);
    },
  );

  test(
    'legacy queued daily and pulse logs sync without fabricated answers',
    () async {
      final today = LogApi.todayKey();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'unified_pending_check_ins_v1_7',
        jsonEncode([
          {
            'log_date': today,
            'check_in_type': 'weekly',
            'daily': {
              'sleep_hours': 7,
              'sleep_quality': 2,
              'mood_index': 3,
              'energy_level': 4,
              'hydration_liters': 2,
              'workload_hours_band': '3-4 hours',
              'exercise_names': ['Walking'],
              'symptom_names': ['None'],
              'habit_names': ['Quiet break'],
            },
            'weekly': {
              'perceived_pressure_level': 3,
              'productivity_focus_level': 4,
              'recovery_rest_level': 3,
              'detachment_level': 2,
              'accomplishment_level': 4,
            },
          },
        ]),
      );
      final posts = <String>[];
      await http.runWithClient(
        () async {
          await LogApi.fetchCheckInStatus();
        },
        () => MockClient((request) async {
          if (request.method == 'POST') {
            posts.add(request.url.path);
            final body = jsonDecode(request.body) as Map;
            expect(body.containsKey('answers'), isFalse);
            if (!request.url.path.endsWith('/weekly-pulse')) {
              expect(body['sleep_hours'], 7);
              expect(body['perceived_stress_level'], isNull);
              expect(body['daily_focus_level'], isNull);
            } else {
              expect(body['productivity_focus_level'], 4);
            }
          }
          return http.Response('{}', 200);
        }),
      );
      expect(posts.length, 2);
      expect(posts.first, endsWith('/logs'));
      expect(posts.last, endsWith('/weekly-pulse'));
      expect(prefs.getString('unified_pending_check_ins_v1_7'), isNull);
    },
  );

  testWidgets(
    'weekly form renders 11 items and all response labels in narrow dark layout',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.4),
            ),
            child: WeeklyAssessmentPage(dueDate: LogApi.todayKey()),
          ),
        ),
      );
      expect(find.byType(LikertQuestion), findsNWidgets(11));
      expect(find.text('0 of 11 answered'), findsOneWidget);
      for (final option in kBurnoutBaselineScale) {
        expect(find.text('${option.value} · ${option.label}'), findsOneWidget);
      }
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'weekly-day save sends nine inputs without hidden daily reflections',
    () async {
      var posts = 0;
      await http.runWithClient(
        () async {
          await LogApi.saveCheckIn(
            mode: CheckInMode.weekly,
            draft: const CheckInDraft(
              energyLevel: 4,
              hydrationLiters: 2,
              exerciseNames: {'Walking'},
              symptomNames: {'None'},
              habitNames: {'Quiet break'},
              perceivedPressureLevel: 5,
              recoveryRestLevel: 1,
              detachmentLevel: 5,
              productivityFocusLevel: 1,
              accomplishmentLevel: 1,
            ),
          );
        },
        () => MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            final body = jsonDecode(request.body) as Map;
            expect(body['schema_version'], 3);
            expect(body['check_in_type'], 'daily');
            final daily = body['daily'] as Map;
            expect(daily['questionnaire_version'], 'daily_core9_v3');
            for (final key in [
              'perceived_stress_level',
              'break_quality_level',
              'daily_detachment_level',
              'daily_focus_level',
              'daily_accomplishment_level',
            ]) {
              expect(daily.containsKey(key), isFalse);
            }
            expect(daily['energy_level'], 4);
            expect(body.containsKey('weekly'), isFalse);
          }
          return http.Response('{}', 200);
        }),
      );
      expect(posts, 1);
    },
  );

  test(
    'old twenty-two-item weekly queue retains its version during replay',
    () async {
      final today = LogApi.todayKey();
      final oldAnswers = {
        for (final section in kBurnoutBaselineSections)
          for (final question in section.questions) question.questionKey: 3,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'weekly_assessment_pending_7',
        jsonEncode({
          today: {
            'due_date': today,
            'response_date': today,
            'questionnaire_version': kBurnoutQuestionnaireVersion,
            'answers': oldAnswers,
          },
        }),
      );
      var posts = 0;
      await http.runWithClient(
        () async {
          final status = await WeeklyAssessmentApi.load();
          expect(status['pending'], isEmpty);
        },
        () => MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            final payload = jsonDecode(request.body) as Map;
            expect(
              payload['questionnaire_version'],
              kBurnoutQuestionnaireVersion,
            );
            expect((payload['answers'] as Map).length, 22);
          }
          return http.Response('{}', 200);
        }),
      );
      expect(posts, 1);
    },
  );

  testWidgets('old weekly draft prefills only the eleven retained questions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyAssessmentPage(
          dueDate: LogApi.todayKey(),
          initialAnswers: {
            for (final section in kBurnoutBaselineSections)
              for (final question in section.questions) question.questionKey: 3,
          },
        ),
      ),
    );
    expect(find.byType(LikertQuestion), findsNWidgets(11));
    expect(find.text('11 of 11 answered'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
