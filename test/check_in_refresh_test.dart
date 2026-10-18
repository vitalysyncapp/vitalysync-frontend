import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/activity/data/activity_service.dart';
import 'package:vitalysync/features/dashboard/data/burnout_display_data.dart';
import 'package:vitalysync/features/dashboard/data/burnout_score_api.dart';
import 'package:vitalysync/features/dashboard/data/weekly_user_metrics.dart';
import 'package:vitalysync/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/sleep_pattern_card.dart';
import 'package:vitalysync/features/home/presentation/pages/home_page.dart';
import 'package:vitalysync/features/home/presentation/widgets/burnout_card.dart';
import 'package:vitalysync/features/home/presentation/widgets/info_card.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/log/presentation/pages/log_page.dart';
import 'package:vitalysync/features/log/presentation/widgets/check_in_success_view.dart';
import 'package:vitalysync/features/log/presentation/widgets/log_widgets.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';

import 'test_helpers.dart';

const draft = CheckInDraft(
  sleepHours: 6,
  energyLevel: 4,
  hydrationLiters: 0.5,
  exerciseNames: {'Walking'},
  symptomNames: {'None'},
  habitNames: {'Quiet break'},
  perceivedPressureLevel: 3,
  recoveryRestLevel: 3,
  detachmentLevel: 2,
  productivityFocusLevel: 4,
  accomplishmentLevel: 4,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);
  setUp(configureLoggedInSession);

  testWidgets('new users see the same baseline, then their first check-in', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('onboarding_initial_burnout_score', 35);
    await prefs.setString('onboarding_initial_burnout_level', 'Moderate');
    final server = CheckInServer()..hasLog = false;
    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: IndexedStack(
            children: [
              HomePage(onProfileTap: () {}),
              const Dashboard(),
            ],
          ),
        ),
      );
      await flushWidgets(tester);
      final home = tester.widget<BurnoutCard>(find.byType(BurnoutCard));
      expect(home.score, 35);
      expect(home.sourceLabel, contains('Baseline'));
      expect(riskStat(tester).value, '35/100');
      expect(riskStat(tester).detail, contains('Baseline'));
      expect(
        tester
            .widgetList<InfoCard>(find.byType(InfoCard))
            .singleWhere((card) => card.title == 'Sleep')
            .value,
        '--',
      );

      await LogApi.saveCheckIn(
        draft: draft.copyWith(sleepHours: 8),
        mode: CheckInMode.daily,
      );
      await flushWidgets(tester);
      expect(tester.widget<BurnoutCard>(find.byType(BurnoutCard)).score, 62);
      expect(riskStat(tester).value, '62/100');
      expect(
        tester
            .widgetList<InfoCard>(find.byType(InfoCard))
            .singleWhere((card) => card.title == 'Sleep')
            .value,
        '8h',
      );
      server.insight.complete(http.Response('{}', 200));
      await flushWidgets(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await ActivityService.instance.disposeTracking();
    }, () => MockClient(server.respond));
  });

  for (final fromAssistant in [false, true]) {
    testWidgets(
      '${fromAssistant ? 'assistant' : 'log page'} save refreshes mounted home and dashboard',
      (tester) async {
        final server = CheckInServer();
        final controller = LogPageController();
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await http.runWithClient(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: IndexedStack(
                index: 2,
                children: [
                  HomePage(onProfileTap: () {}),
                  const Dashboard(),
                  if (!fromAssistant)
                    LogPage(controller: controller)
                  else
                    Scaffold(
                      body: AssistantExperiencePanel(
                        message: 'Take a calm moment.',
                        emoji: 'heart',
                        recommendations: const [],
                        adaptiveNudges: const [],
                        hasLoadedAdaptiveNudges: true,
                        hasLoadedNutritionInsight: true,
                        onRefreshRecommendations: () async => const [],
                        onRefreshAdaptiveNudges:
                            ({bool forceRefresh = false}) async => const [],
                        onRefreshNutritionInsight:
                            ({bool forceRefresh = false}) async => null,
                        onRefreshEnvironment: () async => null,
                        initialSectionIndex: 1,
                      ),
                    ),
                ],
              ),
            ),
          );
          await flushWidgets(tester);
          expect(
            tester
                .widget<BurnoutCard>(
                  find.byType(BurnoutCard, skipOffstage: false),
                )
                .score,
            35,
          );
          // A delayed AI insight must not keep the numeric dashboard cards loading.
          expect(riskStat(tester).value, '35/100');
          expect(riskStat(tester).isLoading, isFalse);

          tester
              .widget<CheckInSuccessView>(find.byType(CheckInSuccessView))
              .onRedo();
          await flushWidgets(tester);
          final form = tester.widget<LogWidgets>(find.byType(LogWidgets));
          form.onSleepChanged(8);
          await tester.pump();
          tester
              .widget<LogWidgets>(find.byType(LogWidgets))
              .onHydrationAdd(1.5);
          await tester.pump();
          if (fromAssistant) {
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Save daily check-in'),
                )
                .onPressed!();
          } else {
            unawaited(controller.save());
          }
          await flushWidgets(tester);
          expect(server.saves, 1);
          expect(
            tester
                .widget<BurnoutCard>(
                  find.byType(BurnoutCard, skipOffstage: false),
                )
                .score,
            62,
          );
          expect(riskStat(tester).value, '62/100');
          final summaries = tester.widgetList<InfoCard>(
            find.byType(InfoCard, skipOffstage: false),
          );
          expect(
            summaries.singleWhere((card) => card.title == 'Sleep').value,
            '8h',
          );
          expect(
            summaries.singleWhere((card) => card.title == 'Hydration').value,
            '2L',
          );
          final sleep = tester.widget<SleepPatternCard>(
            find.byType(SleepPatternCard, skipOffstage: false),
          );
          expect(sleep.metrics?.averageSleep, 8);
          expect(tester.takeException(), isNull);
          server.insight.complete(http.Response('{}', 200));
          await flushWidgets(tester);
          await tester.pumpWidget(const SizedBox.shrink());
          await ActivityService.instance.disposeTracking();
        }, () => MockClient(server.respond));
        controller.dispose();
        await tester.binding.setSurfaceSize(null);
      },
    );
  }

  test(
    'offline save invalidates weekly metrics, exposes inputs and synchronizes once',
    () async {
      final server = CheckInServer();
      await http.runWithClient(() async {
        final before = await WeeklyUserMetricsService.loadCurrentWeek();
        expect(before.averageSleep, 6);
        expect((await BurnoutDisplayData.load()).score, 35);
        final originalRevision = BurnoutScoreApi.refreshSignal.value;
        server.offline = true;
        final result = await LogApi.saveCheckIn(
          draft: draft.copyWith(sleepHours: 9, hydrationLiters: 2),
          mode: CheckInMode.daily,
        );
        expect(result['is_offline'], isTrue);
        expect(
          BurnoutScoreApi.refreshSignal.value,
          greaterThan(originalRevision),
        );
        final latest = await LogApi.fetchLatestLog();
        expect(latest['log']['sleep_hours'], 9);
        expect(latest['pending_sync_count'], 1);
        expect(
          (await WeeklyUserMetricsService.loadCurrentWeek()).averageSleep,
          9,
        );
        final offlineDisplay = await BurnoutDisplayData.load();
        expect(offlineDisplay.hasPendingCheckIn, isTrue);
        expect(offlineDisplay.score, 35);
        expect(
          offlineDisplay.patternSummary?.windowForDays(7)?.points,
          hasLength(1),
        );

        server.offline = false;
        await Future.wait([
          LogApi.fetchLatestLog(),
          WeeklyUserMetricsService.loadCurrentWeek(forceRefresh: true),
        ]);
        expect(server.saves, 1);
        expect(await LogApi.pendingLogCount(), 0);
        final synced = await BurnoutDisplayData.load();
        expect(synced.score, 62);
        expect(synced.hasPendingCheckIn, isFalse);
      }, () => MockClient(server.respond));
    },
  );

  test('weekly metrics are isolated between signed-in users', () async {
    await http.runWithClient(
      () async {
        expect(
          (await WeeklyUserMetricsService.loadCurrentWeek()).averageSleep,
          6,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', 2);
        expect(
          (await WeeklyUserMetricsService.loadCurrentWeek()).averageSleep,
          9,
        );
      },
      () => MockClient(
        (request) async => http.Response(
          jsonEncode({
            'logs': [
              {
                ...draft.dailyJson(),
                'log_date': LogApi.todayKey(),
                'sleep_hours': request.url.queryParameters['user_id'] == '2'
                    ? 9
                    : 6,
              },
            ],
          }),
          200,
        ),
      ),
    );
  });

  test(
    'a pre-save home request cannot overwrite the newly saved log',
    () async {
      final server = CheckInServer();
      final started = Completer<void>();
      final oldResponse = Completer<http.Response>();
      var latestRequests = 0;
      await http.runWithClient(
        () async {
          final oldLoad = LogApi.fetchLatestLog();
          await started.future;
          await LogApi.saveCheckIn(
            draft: draft.copyWith(sleepHours: 8),
            mode: CheckInMode.daily,
          );
          oldResponse.complete(
            http.Response(
              jsonEncode({
                'has_log': true,
                'log': {...draft.dailyJson(), 'log_date': LogApi.todayKey()},
              }),
              200,
            ),
          );
          expect((await oldLoad)['log']['sleep_hours'], 8);
          server.offline = true;
          expect((await LogApi.fetchLatestLog())['log']['sleep_hours'], 8);
        },
        () => MockClient((request) {
          if (request.url.path == '/api/logs/latest' && latestRequests++ == 0) {
            started.complete();
            return oldResponse.future;
          }
          return server.respond(request);
        }),
      );
    },
  );
}

DashboardStatCard riskStat(WidgetTester tester) => tester
    .widgetList<DashboardStatCard>(
      find.byType(DashboardStatCard, skipOffstage: false),
    )
    .singleWhere((card) => card.title == 'Burnout Risk estimate');

Future<void> flushWidgets(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class CheckInServer {
  Map<String, dynamic> log = {
    ...draft.dailyJson(),
    'log_date': LogApi.todayKey(),
  };
  int saves = 0;
  bool offline = false;
  bool hasLog = true;
  final insight = Completer<http.Response>();
  Map<String, dynamic> get score => {
    'score_date': LogApi.todayKey(),
    'overall_score': saves == 0 ? 35 : 62,
    'risk_level': saves == 0 ? 'moderate' : 'high',
    'confidence_score': 90,
    'scoring_version': 'burnout_engine_v5_daily14_v1',
  };

  Future<http.Response> respond(http.Request request) async {
    if (offline) throw http.ClientException('Failed host lookup');
    final path = request.url.path;
    if (path.endsWith('/personal-insight')) return insight.future;
    if (path == '/api/logs/check-in' && request.method == 'POST') {
      saves++;
      hasLog = true;
      final body = jsonDecode(request.body) as Map;
      log = {
        ...Map<String, dynamic>.from(body['daily'] as Map),
        'log_date': body['log_date'],
      };
      return json({
        'log': log,
        'burnout_score': score,
        'streak': {'current_streak': 1},
      });
    }
    if (path == '/api/logs/check-in/status') {
      return json({
        'has_today_log': hasLog,
        'required_mode': 'daily',
        'schedule': {},
        'existing_check_in': {'daily': hasLog ? log : null},
      });
    }
    if (path == '/api/logs/latest' || path == '/api/logs/today') {
      return json({'has_log': hasLog, 'log': hasLog ? log : null});
    }
    if (path == '/api/logs/history') {
      final start = request.url.queryParameters['start'] ?? '';
      final end = request.url.queryParameters['end'] ?? '9999';
      final date = log['log_date'] as String;
      return json({
        'logs': hasLog && date.compareTo(start) >= 0 && date.compareTo(end) <= 0
            ? [log]
            : [],
      });
    }
    if (path.endsWith('/scores/latest')) {
      return json({'has_score': hasLog, 'score': hasLog ? score : null});
    }
    if (path.endsWith('/patterns/summary')) {
      return json({
        'latest_score': hasLog ? score : null,
        'windows': {
          '7_day': {
            'window_days': 7,
            'latest_score': score['overall_score'],
            'points': hasLog ? [score] : [],
          },
        },
      });
    }
    return json({});
  }

  http.Response json(Map<String, dynamic> data) =>
      http.Response(jsonEncode(data), 200);
}
