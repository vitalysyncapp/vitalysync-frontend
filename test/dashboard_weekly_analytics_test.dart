import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/activity/data/activity_log.dart';
import 'package:vitalysync/features/activity/data/activity_service.dart';
import 'package:vitalysync/features/activity/presentation/widgets/activity_summary_card.dart';
import 'package:vitalysync/features/dashboard/data/weekly_user_metrics.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/wellness_index_card.dart';

void main() {
  test('weekly metrics normalize steps against each daily goal', () {
    final metrics = _metrics(
      stepsPerDay: 2500,
      goalSteps: 5000,
      includeWellnessLogs: false,
    );

    expect(metrics.totalSteps, 17500);
    expect(metrics.averageSteps, 2500);
    expect(metrics.stepIndex, 50);
  });

  test(
    'latest live activity replaces stale history without losing higher data',
    () {
      final metrics = _metrics(
        stepsPerDay: 1000,
        goalSteps: 5000,
        includeWellnessLogs: false,
      );
      final todayKey = _dateKey(DateTime.now());

      final updated = metrics.withLatestActivity(
        ActivityLog.fromSteps(logDate: todayKey, steps: 3000, goalSteps: 5000),
      );
      final protected = updated.withLatestActivity(
        ActivityLog.fromSteps(logDate: todayKey, steps: 100, goalSteps: 5000),
      );

      expect(updated.totalSteps, 9000);
      expect(protected.totalSteps, 9000);
    },
  );

  testWidgets('weekly steps card compares totals with the previous week', (
    tester,
  ) async {
    final current = _metrics(
      stepsPerDay: 2000,
      goalSteps: 5000,
      includeWellnessLogs: false,
    );
    final previous = _metrics(
      stepsPerDay: 1000,
      goalSteps: 5000,
      includeWellnessLogs: false,
      start: DateTime.now().subtract(const Duration(days: 13)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyStepAnalyticsCard(
            state: _activityState(steps: 2000),
            currentWeek: current,
            previousWeek: previous,
            isLoading: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('14,000'), findsOneWidget);
    expect(find.text('+100% vs last week'), findsOneWidget);
  });

  testWidgets('wellness index uses steps and explains its insight pills', (
    tester,
  ) async {
    final metrics = _metrics(
      stepsPerDay: 2500,
      goalSteps: 5000,
      includeWellnessLogs: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WellnessIndexCard(metrics: metrics, isLoading: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<RadarChart>(find.byType(RadarChart));
    expect(chart.data.getTitle!(4, 0).text, 'Steps');
    expect(find.text('Highest: Sleep 100%'), findsOneWidget);
    expect(find.text('Build: Water 40%'), findsOneWidget);
    expect(find.text('Data: 6/6 areas'), findsOneWidget);
    expect(find.textContaining('not a medical assessment'), findsOneWidget);
  });

  test('missing mood logs produce an empty mood index', () {
    final metrics = _metrics(
      stepsPerDay: 0,
      goalSteps: 5000,
      includeWellnessLogs: false,
    );

    expect(metrics.moodIndex, 0);
  });
}

WeeklyUserMetrics _metrics({
  required int stepsPerDay,
  required int goalSteps,
  required bool includeWellnessLogs,
  DateTime? start,
}) {
  final today = DateTime.now();
  final rangeStart = start ?? today.subtract(const Duration(days: 6));

  return WeeklyUserMetrics(
    days: List.generate(7, (index) {
      final date = DateTime(
        rangeStart.year,
        rangeStart.month,
        rangeStart.day,
      ).add(Duration(days: index));
      return DailyUserMetric(
        date: date,
        dateKey: _dateKey(date),
        dayLabel: const [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][index],
        log: includeWellnessLogs
            ? const {
                'sleep_hours': 8,
                'mood_index': 2,
                'energy_level': 3,
                'hydration_liters': 1,
              }
            : null,
        activity: ActivityLog.fromSteps(
          logDate: _dateKey(date),
          steps: stepsPerDay,
          goalSteps: goalSteps,
        ),
      );
    }),
  );
}

ActivityTrackingState _activityState({required int steps}) {
  return ActivityTrackingState(
    log: ActivityLog.fromSteps(
      logDate: _dateKey(DateTime.now()),
      steps: steps,
      goalSteps: 5000,
    ),
    isLoading: false,
    isOffline: false,
    permissionGranted: true,
    isTracking: true,
    isStepTrackingSupported: true,
    pendingSyncCount: 0,
    errorMessage: null,
  );
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
