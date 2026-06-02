import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/exercise/data/exercise_goal_model.dart';
import 'package:vitalysync/features/exercise/data/exercise_recommendation_policy.dart';

void main() {
  test('sedentary users start light and only rise to moderate', () {
    final summary = ExerciseRecommendationPolicy.summarizeGoalHistory(
      List.generate(
        14,
        (index) => _goal(_daysAgo(14 - index), status: 'completed'),
      ),
      now: _now,
    );
    final plan = ExerciseRecommendationPolicy.resolveEffortPlan(
      lifestyleType: 'Sedentary',
      exerciseGoalDays: '3-4 days',
      history: summary,
      needsRecovery: false,
    );

    expect(summary.completedStreak, 14);
    expect(plan.baselineLevel, ExerciseEffortLevel.light);
    expect(plan.targetLevel, ExerciseEffortLevel.moderate);
  });

  test('very active users drop one effort level per three missed days', () {
    final threeMisses = ExerciseRecommendationPolicy.summarizeGoalHistory(
      List.generate(3, (index) => _goal(_daysAgo(3 - index), status: 'none')),
      now: _now,
    );
    final sixMisses = ExerciseRecommendationPolicy.summarizeGoalHistory(
      List.generate(
        6,
        (index) => _goal(_daysAgo(6 - index), status: 'canceled'),
      ),
      now: _now,
    );

    final activePlan = ExerciseRecommendationPolicy.resolveEffortPlan(
      lifestyleType: 'Very Active',
      exerciseGoalDays: '5+ days',
      history: threeMisses,
      needsRecovery: false,
    );
    final moderatePlan = ExerciseRecommendationPolicy.resolveEffortPlan(
      lifestyleType: 'Very Active',
      exerciseGoalDays: '5+ days',
      history: sixMisses,
      needsRecovery: false,
    );

    expect(threeMisses.missedStreak, 3);
    expect(activePlan.targetLevel, ExerciseEffortLevel.active);
    expect(sixMisses.missedStreak, 6);
    expect(moderatePlan.targetLevel, ExerciseEffortLevel.moderate);
  });

  test('missing dates count as missed only after goal history exists', () {
    final noHistory = ExerciseRecommendationPolicy.summarizeGoalHistory(
      const [],
      now: _now,
    );
    final staleHistory = ExerciseRecommendationPolicy.summarizeGoalHistory([
      _goal(_daysAgo(4), status: 'completed'),
    ], now: _now);

    expect(noHistory.missedStreak, 0);
    expect(staleHistory.missedStreak, 3);
  });

  test('very active recommendations include high intensity options', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      const ExerciseRecommendationPolicyContext(
        lifestyleType: 'Very Active',
        exerciseGoalDays: '5+ days',
        steps: 3000,
        needsRecovery: false,
        outdoorSafe: true,
        gentleOutdoor: false,
        airSafe: true,
        weatherReason: 'Weather looks safe for outdoor movement.',
        history: ExerciseGoalHistorySummary.empty,
      ),
    );
    final names = result.recommendations.map((item) => item.exerciseName);

    expect(names, contains('Gym strength session'));
    expect(names, contains('Long jog'));
    expect(names, contains('Run'));
    expect(names, contains('None today'));
  });
}

final _now = DateTime(2026, 6, 2);

ExerciseGoalModel _goal(String logDate, {required String status}) {
  return ExerciseGoalModel(
    goalId: null,
    userId: 1,
    logDate: logDate,
    recommendedBy: 'vitalysync_assistant',
    exerciseName: status == 'none' ? 'None today' : 'Walk',
    exerciseCategory: status == 'none' ? 'none' : 'walking',
    targetDistanceMeters: status == 'none' ? null : 800,
    targetMinutes: status == 'none' ? null : 10,
    targetReps: null,
    completionMethod: status == 'none' ? 'none' : 'distance',
    status: status,
    completedAt: status == 'completed' ? DateTime.now() : null,
  );
}

String _daysAgo(int days) {
  final date = _now.subtract(Duration(days: days));
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
