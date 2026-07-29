import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/nutrition_analytics_card.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_api.dart';
import 'package:vitalysync/shared/offline/fetch_policy.dart';

void main() {
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
