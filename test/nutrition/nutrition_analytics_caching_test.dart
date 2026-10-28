import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitalysync/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/dashboard_goal_tracking_card.dart';

import '../helpers/test_helpers.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/nutrition_analytics_card.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_api.dart';
import 'package:vitalysync/shared/offline/fetch_policy.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);
  setUp(configureLoggedInSession);

  for (final initialCalories in [0, 1000]) {
    testWidgets(
      'successful meal refreshes dashboard from $initialCalories calories',
      (tester) async {
        var calories = initialCalories;
        var historyReads = 0;
        var failSave = false;
        await http.runWithClient(
          () async {
            await tester.pumpWidget(const MaterialApp(home: Dashboard()));
            for (var i = 0; i < 20; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            final beforeReads = historyReads;
            final beforeVersion = tester
                .widget<DashboardGoalTrackingCard>(
                  find.byType(DashboardGoalTrackingCard),
                )
                .refreshVersion;
            final beforeSignal = NutritionApi.refreshSignal.value;
            await NutritionApi.confirmMeal(
              attemptId: 1,
              mealType: 'lunch',
              logDate: NutritionApi.todayKey(),
              items: [],
            );
            for (var i = 0; i < 20; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            expect(historyReads, greaterThan(beforeReads));
            expect(find.text('1,700 cal'), findsOneWidget);
            expect(NutritionApi.refreshSignal.value, beforeSignal + 1);
            expect(
              tester
                  .widget<DashboardGoalTrackingCard>(
                    find.byType(DashboardGoalTrackingCard),
                  )
                  .refreshVersion,
              beforeVersion + 1,
            );
            failSave = true;
            final readsAfterSave = historyReads;
            await expectLater(
              NutritionApi.confirmMeal(
                attemptId: 2,
                mealType: 'dinner',
                logDate: NutritionApi.todayKey(),
                items: [],
              ),
              throwsException,
            );
            await tester.pump();
            expect(NutritionApi.refreshSignal.value, beforeSignal + 1);
            expect(historyReads, readsAfterSave);
            expect(find.text('1,700 cal'), findsOneWidget);
            await tester.pumpWidget(const SizedBox.shrink());
          },
          () => MockClient((request) async {
            if (request.url.path.endsWith('/nutrition/confirm')) {
              if (failSave) return http.Response('{}', 500);
              calories = 1700;
            }
            if (request.url.path.endsWith('/nutrition/history')) {
              historyReads++;
              return http.Response(
                jsonEncode({
                  'days': [
                    {
                      'log_date': NutritionApi.todayKey(),
                      'total_calories': calories,
                      'total_protein_g': 80,
                      'total_carbs_g': 160,
                      'total_fat_g': 50,
                      'meal_count': calories == 0 ? 0 : 2,
                    },
                  ],
                }),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
        );
      },
    );
  }

  test(
    'meal save detaches pre-save history requests and keeps the new cache',
    () async {
      final started = Completer<void>();
      final oldResponse = Completer<http.Response>();
      var reads = 0;
      final date = NutritionApi.todayKey();
      await http.runWithClient(
        () async {
          final oldLoad = NutritionApi.fetchHistoryCached(
            start: date,
            end: date,
          );
          await started.future;
          await NutritionApi.confirmMeal(
            attemptId: 1,
            mealType: 'lunch',
            logDate: date,
            items: [],
          );
          final fresh = await NutritionApi.fetchHistoryCached(
            start: date,
            end: date,
          );
          expect(fresh.data.single.totalCalories, 1700);
          oldResponse.complete(
            http.Response(
              jsonEncode({
                'days': [
                  {'log_date': date, 'total_calories': 1000},
                ],
              }),
              200,
            ),
          );
          await oldLoad;
          final cached = await NutritionApi.fetchHistoryCached(
            start: date,
            end: date,
          );
          expect(cached.data.single.totalCalories, 1700);
          expect(reads, 2);
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/nutrition/history')) {
            if (++reads == 1) {
              started.complete();
              return oldResponse.future;
            }
            return http.Response(
              jsonEncode({
                'days': [
                  {'log_date': date, 'total_calories': 1700},
                ],
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );
    },
  );

  testWidgets('renders cached nutrition while a refresh is pending', (
    tester,
  ) async {
    final refresh = Completer<List<NutritionHistoryDay>>();

    await tester.pumpWidget(
      _testApp(
        NutritionAnalyticsCard(
          historyFetcher:
              ({
                required String start,
                required String end,
                bool forceRefresh = false,
              }) async {
                return CachedFetchResult(
                  data: [_historyDay(start, calories: 1200)],
                  isFromCache: true,
                  isStale: true,
                  cachedAt: DateTime.now(),
                  refresh: refresh.future,
                );
              },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1,200 cal'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    refresh.complete([_historyDay(_weekStart(), calories: 1800)]);
    await tester.pump();

    expect(find.text('1,800 cal'), findsOneWidget);
    expect(find.text('1,200 cal'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('preserves cached nutrition when background refresh fails', (
    tester,
  ) async {
    final refresh = Completer<List<NutritionHistoryDay>>();

    await tester.pumpWidget(
      _testApp(
        NutritionAnalyticsCard(
          historyFetcher:
              ({
                required String start,
                required String end,
                bool forceRefresh = false,
              }) async {
                return CachedFetchResult(
                  data: [_historyDay(start, calories: 1350)],
                  isFromCache: true,
                  isStale: true,
                  cachedAt: DateTime.now(),
                  refresh: refresh.future,
                );
              },
        ),
      ),
    );
    await tester.pump();

    refresh.completeError(Exception('temporary network failure'));
    await tester.pump();

    expect(find.text('1,350 cal'), findsOneWidget);
    expect(find.text('Saved nutrition data unavailable'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('retries after an initial nutrition history failure', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      _testApp(
        NutritionAnalyticsCard(
          historyFetcher:
              ({
                required String start,
                required String end,
                bool forceRefresh = false,
              }) async {
                attempts++;
                if (attempts == 1) {
                  throw Exception('temporary network failure');
                }
                expect(forceRefresh, isTrue);
                return CachedFetchResult(
                  data: [_historyDay(start, calories: 1600)],
                  isFromCache: false,
                  isStale: false,
                  cachedAt: null,
                );
              },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Saved nutrition data unavailable'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Retry nutrition data').first);
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('1,600 cal'), findsOneWidget);
    expect(find.text('Saved nutrition data unavailable'), findsNothing);
  });

  testWidgets('dashboard refresh forces a fetch without clearing card data', (
    tester,
  ) async {
    final forcedResult =
        Completer<CachedFetchResult<List<NutritionHistoryDay>>>();
    var attempts = 0;
    Future<CachedFetchResult<List<NutritionHistoryDay>>> fetcher({
      required String start,
      required String end,
      bool forceRefresh = false,
    }) async {
      attempts++;
      if (attempts == 1) {
        return CachedFetchResult(
          data: [_historyDay(start, calories: 1000)],
          isFromCache: true,
          isStale: false,
          cachedAt: DateTime.now(),
        );
      }

      expect(forceRefresh, isTrue);
      return forcedResult.future;
    }

    await tester.pumpWidget(
      _testApp(NutritionAnalyticsCard(historyFetcher: fetcher)),
    );
    await tester.pump();
    expect(find.text('1,000 cal'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        NutritionAnalyticsCard(refreshVersion: 1, historyFetcher: fetcher),
      ),
    );
    await tester.pump();

    expect(find.text('1,000 cal'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    forcedResult.complete(
      CachedFetchResult(
        data: [_historyDay(_weekStart(), calories: 1700)],
        isFromCache: false,
        isStale: false,
        cachedAt: null,
      ),
    );
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('1,700 cal'), findsOneWidget);
    expect(find.text('1,000 cal'), findsNothing);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

NutritionHistoryDay _historyDay(String logDate, {required double calories}) {
  return NutritionHistoryDay(
    logDate: logDate,
    totalCalories: calories,
    totalProteinG: 80,
    totalCarbsG: 160,
    totalFatG: 50,
    mealCount: 3,
  );
}

String _weekStart() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
}
