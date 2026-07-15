import 'dart:math';

import '../../../shared/goals/user_goals.dart';
import '../../../shared/preferences/user_session.dart';
import '../../nutrition/data/nutrition_api.dart';
import 'weekly_user_metrics.dart';

enum GoalTrackingMetricStatus { onTrack, needsLogs, belowTarget, aboveTarget }

class DashboardGoalTrackingSnapshot {
  final UserGoalsSnapshot goals;
  final WeeklyUserMetrics weeklyMetrics;
  final List<NutritionHistoryDay> nutritionDays;
  final List<GoalTrackingMetric> metrics;
  final List<GoalFocusRecommendation> recommendations;
  final bool isNutritionUnavailable;

  const DashboardGoalTrackingSnapshot({
    required this.goals,
    required this.weeklyMetrics,
    required this.nutritionDays,
    required this.metrics,
    required this.recommendations,
    required this.isNutritionUnavailable,
  });

  List<String> get wellnessGoalHeaders => goals.wellnessGoals;
}

class GoalTrackingMetric {
  final String id;
  final String title;
  final String valueLabel;
  final String targetLabel;
  final String detailLabel;
  final double progress;
  final double focusScore;
  final bool isOnTrack;
  final bool hasData;
  final GoalTrackingMetricStatus status;
  final String statusLabel;
  final String recommendationTitle;
  final String recommendationMessage;

  const GoalTrackingMetric({
    required this.id,
    required this.title,
    required this.valueLabel,
    required this.targetLabel,
    required this.detailLabel,
    required this.progress,
    required this.focusScore,
    required this.isOnTrack,
    required this.hasData,
    required this.status,
    required this.statusLabel,
    required this.recommendationTitle,
    required this.recommendationMessage,
  });

  bool get needsAttention => !hasData || !isOnTrack;
}

class GoalFocusRecommendation {
  final String metricId;
  final String title;
  final String message;

  const GoalFocusRecommendation({
    required this.metricId,
    required this.title,
    required this.message,
  });
}

class GoalTrackingMetricsService {
  GoalTrackingMetricsService._();

  static Future<DashboardGoalTrackingSnapshot> loadCurrentWeek() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));

    final results = await Future.wait<Object>([
      userId > 0
          ? UserGoalsService.fetch(userId: userId)
          : Future.value(UserGoalsSnapshot.defaults()),
      WeeklyUserMetricsService.loadCurrentWeek(),
      _loadNutritionHistory(userId: userId, start: start, end: today),
    ]);

    final goals = results[0] as UserGoalsSnapshot;
    final weeklyMetrics = results[1] as WeeklyUserMetrics;
    final nutritionResult = results[2] as _NutritionHistoryResult;
    final nutritionSnapshot = _WeeklyNutritionSnapshot.fromHistory(
      history: nutritionResult.days,
    );
    final metrics = _buildMetrics(
      goals: goals,
      weeklyMetrics: weeklyMetrics,
      nutrition: nutritionSnapshot,
    );

    return DashboardGoalTrackingSnapshot(
      goals: goals,
      weeklyMetrics: weeklyMetrics,
      nutritionDays: nutritionResult.days,
      metrics: metrics,
      recommendations: _buildRecommendations(goals: goals, metrics: metrics),
      isNutritionUnavailable: nutritionResult.unavailable,
    );
  }

  static Future<_NutritionHistoryResult> _loadNutritionHistory({
    required int userId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (userId <= 0) {
      return const _NutritionHistoryResult(days: []);
    }

    try {
      final days = await NutritionApi.fetchHistory(
        start: _dateKey(start),
        end: _dateKey(end),
      );
      return _NutritionHistoryResult(days: days);
    } catch (_) {
      return const _NutritionHistoryResult(days: [], unavailable: true);
    }
  }

  static List<GoalTrackingMetric> _buildMetrics({
    required UserGoalsSnapshot goals,
    required WeeklyUserMetrics weeklyMetrics,
    required _WeeklyNutritionSnapshot nutrition,
  }) {
    final sleepLoggedDays = weeklyMetrics.days
        .where((day) => day.sleepHours > 0)
        .length;
    final hydrationLoggedDays = weeklyMetrics.days
        .where((day) => day.hydrationLiters > 0)
        .length;
    final stepGoalDays = weeklyMetrics.days.where((day) {
      final steps = day.activity?.steps ?? 0;
      return steps >= goals.dailySteps;
    }).length;

    return [
      _targetMetric(
        id: 'sleep',
        title: 'Sleep goal',
        current: weeklyMetrics.averageSleep,
        target: goals.sleepHours,
        valueLabel: weeklyMetrics.averageSleep > 0
            ? '${_formatNumber(weeklyMetrics.averageSleep)}h avg'
            : 'No sleep logs',
        targetLabel: '${goals.sleepLabel} goal',
        detailLabel: sleepLoggedDays > 0
            ? '$sleepLoggedDays/7 sleep logs this week'
            : 'Log sleep in the daily log to compare progress.',
        hasData: sleepLoggedDays > 0,
        recommendationTitle: 'Protect sleep consistency',
        recommendationMessage:
            'Aim for ${goals.sleepLabel} tonight and keep logging sleep so recovery trends stay visible.',
      ),
      _targetMetric(
        id: 'hydration',
        title: 'Hydration goal',
        current: weeklyMetrics.averageHydration,
        target: goals.hydrationLiters,
        valueLabel: weeklyMetrics.averageHydration > 0
            ? '${_formatNumber(weeklyMetrics.averageHydration)} L avg'
            : 'No hydration logs',
        targetLabel: '${goals.hydrationLabel} goal',
        detailLabel: hydrationLoggedDays > 0
            ? '$hydrationLoggedDays/7 hydration logs this week'
            : 'Add hydration in the daily log to see your trend.',
        hasData: hydrationLoggedDays > 0,
        recommendationTitle: 'Stabilize hydration',
        recommendationMessage:
            'Bring your daily water intake closer to ${goals.hydrationLabel}, especially on busy or high-stress days.',
      ),
      _targetMetric(
        id: 'activity',
        title: 'Activity goal',
        current: weeklyMetrics.exerciseDays.toDouble(),
        target: goals.activityDaysPerWeek.toDouble(),
        valueLabel: '${weeklyMetrics.exerciseDays}/7 movement days',
        targetLabel: '${goals.activityLabel} goal',
        detailLabel: weeklyMetrics.exerciseDays > 0
            ? 'Movement logged on ${weeklyMetrics.exerciseDays} days.'
            : 'Log walks, exercise, or completed step goals.',
        hasData: weeklyMetrics.exerciseDays > 0 || weeklyMetrics.loggedDays > 0,
        recommendationTitle: 'Add a movement day',
        recommendationMessage:
            'Plan one manageable activity session to move toward ${goals.activityLabel}.',
      ),
      _targetMetric(
        id: 'steps',
        title: 'Daily steps',
        current: weeklyMetrics.averageSteps.toDouble(),
        target: goals.dailySteps.toDouble(),
        valueLabel: '${_formatInt(weeklyMetrics.averageSteps)} avg',
        targetLabel: '${goals.dailyStepsLabel} goal',
        detailLabel: stepGoalDays > 0
            ? '$stepGoalDays/7 step-goal days reached'
            : 'Keep your phone with you so step trends can build.',
        hasData: weeklyMetrics.totalSteps > 0,
        recommendationTitle: 'Build step momentum',
        recommendationMessage:
            'Use short walks or movement breaks to close the gap toward ${goals.dailyStepsLabel}.',
      ),
      _nutritionMetric(goals: goals, nutrition: nutrition),
    ];
  }

  static GoalTrackingMetric _targetMetric({
    required String id,
    required String title,
    required double current,
    required double target,
    required String valueLabel,
    required String targetLabel,
    required String detailLabel,
    required bool hasData,
    required String recommendationTitle,
    required String recommendationMessage,
  }) {
    final targetReached = target <= 0 || current >= target;
    final progress = _targetProgress(current, target);
    final isOnTrack = hasData && targetReached;

    return GoalTrackingMetric(
      id: id,
      title: title,
      valueLabel: valueLabel,
      targetLabel: targetLabel,
      detailLabel: detailLabel,
      progress: hasData ? progress : 0,
      focusScore: hasData ? progress : 0,
      isOnTrack: isOnTrack,
      hasData: hasData,
      status: !hasData
          ? GoalTrackingMetricStatus.needsLogs
          : isOnTrack
          ? GoalTrackingMetricStatus.onTrack
          : GoalTrackingMetricStatus.belowTarget,
      statusLabel: !hasData
          ? 'Needs logs'
          : isOnTrack
          ? 'On track'
          : 'Below goal',
      recommendationTitle: !hasData ? 'Log your $title' : recommendationTitle,
      recommendationMessage: !hasData
          ? 'Add a few entries this week so VitalySync can compare your progress with your goal.'
          : recommendationMessage,
    );
  }

  static GoalTrackingMetric _nutritionMetric({
    required UserGoalsSnapshot goals,
    required _WeeklyNutritionSnapshot nutrition,
  }) {
    final target = goals.nutritionCalories.toDouble();
    final current = nutrition.averageCalories;
    final hasData = nutrition.loggedDays > 0;
    final ratio = target <= 0 ? 1.0 : current / target;
    final isOnTrack = hasData && ratio >= 0.9 && ratio <= 1.1;
    final status = !hasData
        ? GoalTrackingMetricStatus.needsLogs
        : isOnTrack
        ? GoalTrackingMetricStatus.onTrack
        : ratio > 1.1
        ? GoalTrackingMetricStatus.aboveTarget
        : GoalTrackingMetricStatus.belowTarget;
    final focusScore = !hasData
        ? 0.0
        : isOnTrack
        ? 1.0
        : ratio < 0.9
        ? (ratio / 0.9).clamp(0.0, 1.0).toDouble()
        : (1 - ((ratio - 1.1) / 0.5)).clamp(0.0, 1.0).toDouble();
    final recommendationTitle = !hasData
        ? 'Log meals for nutrition insight'
        : ratio > 1.1
        ? 'Ease nutrition closer to target'
        : 'Bring nutrition up steadily';
    final recommendationMessage = !hasData
        ? 'Log at least one meal so your nutrition goal can be compared with real intake.'
        : ratio > 1.1
        ? 'Your logged average is above ${goals.nutritionLabel}; try balancing portions and snacks over the next day.'
        : 'Your logged average is below ${goals.nutritionLabel}; add steady meals or snacks that support your energy.';

    return GoalTrackingMetric(
      id: 'nutrition',
      title: 'Nutrition goal',
      valueLabel: hasData
          ? '${_formatInt(current.round())} kcal avg'
          : 'No meal logs',
      targetLabel: '${goals.nutritionLabel} goal',
      detailLabel: hasData
          ? '${nutrition.loggedDays}/7 meal-log days this week'
          : 'Log meals to compare calories with your target.',
      progress: hasData ? min(ratio, 1).clamp(0.0, 1.0).toDouble() : 0,
      focusScore: focusScore,
      isOnTrack: isOnTrack,
      hasData: hasData,
      status: status,
      statusLabel: switch (status) {
        GoalTrackingMetricStatus.onTrack => 'On track',
        GoalTrackingMetricStatus.needsLogs => 'Needs logs',
        GoalTrackingMetricStatus.aboveTarget => 'Above target',
        GoalTrackingMetricStatus.belowTarget => 'Below target',
      },
      recommendationTitle: recommendationTitle,
      recommendationMessage: recommendationMessage,
    );
  }

  static List<GoalFocusRecommendation> _buildRecommendations({
    required UserGoalsSnapshot goals,
    required List<GoalTrackingMetric> metrics,
  }) {
    final candidates =
        metrics
            .where((metric) => metric.needsAttention)
            .map(
              (metric) => _RecommendationCandidate(
                metric: metric,
                priority:
                    (1 - metric.focusScore) +
                    _wellnessGoalWeight(goals.wellnessGoals, metric.id) +
                    (metric.hasData ? 0 : 0.16),
              ),
            )
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

    if (candidates.isEmpty) {
      return const [
        GoalFocusRecommendation(
          metricId: 'wellness',
          title: 'Keep your goals steady',
          message:
              'Your current goal patterns look on track. Keep logging daily so the dashboard can keep this view accurate.',
        ),
      ];
    }

    return candidates
        .take(3)
        .map(
          (candidate) => GoalFocusRecommendation(
            metricId: candidate.metric.id,
            title: candidate.metric.recommendationTitle,
            message: candidate.metric.recommendationMessage,
          ),
        )
        .toList();
  }

  static double _wellnessGoalWeight(List<String> wellnessGoals, String id) {
    var weight = 0.0;

    for (final goal in wellnessGoals) {
      switch (goal) {
        case 'Improve sleep':
          if (id == 'sleep') weight += 0.35;
          break;
        case 'Be more active':
          if (id == 'activity' || id == 'steps') weight += 0.28;
          break;
        case 'Build healthier habits':
          if (id == 'hydration' || id == 'nutrition' || id == 'steps') {
            weight += 0.24;
          }
          break;
        case 'Reduce stress':
        case 'Manage burnout':
          if (id == 'sleep' || id == 'hydration' || id == 'activity') {
            weight += 0.22;
          }
          break;
        case 'Improve focus':
          if (id == 'sleep' || id == 'hydration' || id == 'nutrition') {
            weight += 0.22;
          }
          break;
      }
    }

    return min(weight, 0.6);
  }

  static double _targetProgress(double current, double target) {
    if (target <= 0) {
      return 1;
    }

    return (current / target).clamp(0.0, 1.0).toDouble();
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }

  static String _formatInt(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}

class _NutritionHistoryResult {
  final List<NutritionHistoryDay> days;
  final bool unavailable;

  const _NutritionHistoryResult({required this.days, this.unavailable = false});
}

class _WeeklyNutritionSnapshot {
  final int loggedDays;
  final double averageCalories;

  const _WeeklyNutritionSnapshot({
    required this.loggedDays,
    required this.averageCalories,
  });

  factory _WeeklyNutritionSnapshot.fromHistory({
    required List<NutritionHistoryDay> history,
  }) {
    final loggedDays = history
        .where((day) => day.mealCount > 0 || day.totalCalories > 0)
        .toList();
    final totalCalories = loggedDays.fold<double>(
      0,
      (sum, day) => sum + day.totalCalories,
    );

    return _WeeklyNutritionSnapshot(
      loggedDays: loggedDays.length,
      averageCalories: loggedDays.isEmpty
          ? 0
          : totalCalories / loggedDays.length,
    );
  }
}

class _RecommendationCandidate {
  final GoalTrackingMetric metric;
  final double priority;

  const _RecommendationCandidate({
    required this.metric,
    required this.priority,
  });
}
