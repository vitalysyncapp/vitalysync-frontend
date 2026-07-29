import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/exercise/data/exercise_goal_model.dart';
import 'package:vitalysync/features/exercise/data/exercise_context_policy.dart';
import 'package:vitalysync/features/exercise/data/exercise_log_context_policy.dart';
import 'package:vitalysync/features/exercise/data/exercise_recommendation_model.dart';
import 'package:vitalysync/features/exercise/data/exercise_recommendation_policy.dart';
import 'package:vitalysync/features/exercise/presentation/widgets/assistant_exercise_card.dart';

void main() {
  test('current steady evidence overrides an old high onboarding baseline', () {
    final result = ExerciseContextPolicy.resolve(
      hasCurrentBurnoutEvidence: true,
      currentBurnoutNeedsRecovery: false,
      currentWorkloadHoursBand: '3-4 hours',
      initialBurnoutLevel: 'High',
      initialBurnoutScore: 60,
      onboardingWorkloadLevel: 5,
    );

    expect(result.needsRecovery, isFalse);
    expect(result.workloadHoursBand, '3-4 hours');
  });

  test('onboarding burnout and workload are fallback-only context', () {
    final result = ExerciseContextPolicy.resolve(
      hasCurrentBurnoutEvidence: false,
      currentBurnoutNeedsRecovery: false,
      currentWorkloadHoursBand: null,
      initialBurnoutLevel: 'Very High',
      initialBurnoutScore: 60,
      onboardingWorkloadLevel: 4,
    );

    expect(result.needsRecovery, isTrue);
    expect(result.workloadHoursBand, '8-9 hours');
  });

  test('current burnout recovery evidence always remains authoritative', () {
    final result = ExerciseContextPolicy.resolve(
      hasCurrentBurnoutEvidence: true,
      currentBurnoutNeedsRecovery: true,
      currentWorkloadHoursBand: 'None',
      initialBurnoutLevel: 'Low',
      initialBurnoutScore: 10,
      onboardingWorkloadLevel: 1,
    );

    expect(result.needsRecovery, isTrue);
    expect(result.workloadHoursBand, 'None');
  });

  test('yesterday or a recent log can supply recovery context', () {
    final yesterday = <String, dynamic>{
      'log_date': '2026-06-01',
      'energy_level': 2,
    };
    final sevenDaysAgo = <String, dynamic>{
      'log_date': '2026-05-26',
      'sleep_hours': 5,
    };

    expect(
      ExerciseLogContextPolicy.selectRecentFallback(yesterday, now: _now),
      same(yesterday),
    );
    expect(
      ExerciseLogContextPolicy.selectRecentFallback(sevenDaysAgo, now: _now),
      same(sevenDaysAgo),
    );
  });

  test('stale, future, or undated logs do not shape recommendations', () {
    expect(
      ExerciseLogContextPolicy.selectRecentFallback({
        'log_date': '2026-05-25',
      }, now: _now),
      isNull,
    );
    expect(
      ExerciseLogContextPolicy.selectRecentFallback({
        'log_date': '2026-06-03',
      }, now: _now),
      isNull,
    );
    expect(
      ExerciseLogContextPolicy.selectRecentFallback({
        'energy_level': 2,
      }, now: _now),
      isNull,
    );
  });

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

  test('good consistency gently raises effort within lifestyle bounds', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(
        lifestyleType: 'Moderately Active',
        history: const ExerciseGoalHistorySummary(
          completedStreak: 7,
          missedStreak: 0,
        ),
      ),
    );

    expect(result.plan.baselineLevel, ExerciseEffortLevel.moderate);
    expect(result.plan.targetLevel, ExerciseEffortLevel.active);
    expect(result.plan.note, contains('consistency'));
  });

  test('low energy caps a strong streak at light effort', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(
        lifestyleType: 'Very Active',
        energyLevel: 2,
        history: const ExerciseGoalHistorySummary(
          completedStreak: 21,
          missedStreak: 0,
        ),
      ),
    );

    expect(result.plan.targetLevel, ExerciseEffortLevel.light);
    expect(result.plan.note.toLowerCase(), contains('energy'));
  });

  test('poor sleep caps a strong streak at light effort', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(
        lifestyleType: 'Very Active',
        sleepHours: 5.5,
        sleepQuality: 1,
        history: const ExerciseGoalHistorySummary(
          completedStreak: 14,
          missedStreak: 0,
        ),
      ),
    );

    expect(result.plan.targetLevel, ExerciseEffortLevel.light);
    expect(result.plan.note.toLowerCase(), contains('sleep'));
  });

  test('short sleep plus heavy workload selects restorative effort', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(
        lifestyleType: 'Very Active',
        sleepHours: 5,
        workloadHoursBand: '8-9 hours',
      ),
    );

    expect(result.plan.targetLevel, ExerciseEffortLevel.restorative);
    expect(result.plan.note.toLowerCase(), contains('sleep'));
    expect(result.plan.note.toLowerCase(), contains('workload'));
  });

  test('heavy workload alone caps effort at light', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(lifestyleType: 'Active', workloadHoursBand: '10-12 hours'),
    );

    expect(result.plan.targetLevel, ExerciseEffortLevel.light);
    expect(result.plan.note.toLowerCase(), contains('workload'));
  });

  test('burnout pattern works without daily recovery inputs', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(
        lifestyleType: 'Very Active',
        burnoutPatternFocus: 'support',
        burnoutPatternSeverity: 'needs support',
        history: const ExerciseGoalHistorySummary(
          completedStreak: 28,
          missedStreak: 0,
        ),
      ),
    );

    expect(result.plan.targetLevel, ExerciseEffortLevel.restorative);
    expect(result.plan.note.toLowerCase(), contains('needs-support'));
  });

  test('unsafe weather keeps recommendations indoors', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(
        lifestyleType: 'Very Active',
        outdoorSafe: false,
        weatherReason: 'Heavy rain makes outdoor movement unsafe.',
      ),
    );
    final names = result.recommendations.map((item) => item.exerciseName);

    expect(names, isNot(contains('Long jog')));
    expect(names, isNot(contains('Run')));
    for (final recommendation in result.recommendations.where(
      (item) => !item.isNoneToday,
    )) {
      expect(recommendation.reason, contains('indoor'));
    }
  });

  test('unsafe air quality keeps recommendations indoors', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(lifestyleType: 'Active', airSafe: false),
    );
    final names = result.recommendations.map((item) => item.exerciseName);

    expect(names, isNot(contains('Jog')));
    expect(result.recommendations.first.reason, contains('Air quality'));
  });

  test('high step count keeps recovery stretching visible first', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(lifestyleType: 'Moderately Active', steps: 10000),
    );

    expect(result.recommendations.first.exerciseName, 'Recovery stretching');
    expect(result.recommendations.first.reason, contains('step count'));
  });

  test('recommendation reasons stay supportive and one sentence', () {
    final result = ExerciseRecommendationPolicy.buildRecommendations(
      _context(needsRecovery: true, outdoorSafe: false, airSafe: false),
    );

    for (final recommendation in result.recommendations) {
      expect(RegExp(r'[.!?]').allMatches(recommendation.reason).length, 1);
      expect(recommendation.reason.length, lessThanOrEqualTo(120));
      expect(
        recommendation.reason.toLowerCase(),
        isNot(matches(RegExp(r'diagnos|treat|medical|burnout'))),
      );
    }
    final noneToday = result.recommendations.last;
    expect(noneToday.exerciseName, 'None today');
    expect(noneToday.reason, contains('valid way'));
  });

  testWidgets(
    'assistant exercise card presents rest as an intentional choice',
    (tester) async {
      const noneToday = ExerciseRecommendationModel(
        exerciseName: 'None today',
        exerciseCategory: 'none',
        targetDistanceMeters: null,
        targetMinutes: null,
        targetReps: null,
        completionMethod: 'none',
        reason: 'Choosing rest today is a valid way to protect your recovery.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantExerciseCard(
              recommendations: const [noneToday],
              isSaving: false,
              onChoose: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Choose what fits your energy today'), findsOneWidget);
      expect(find.byIcon(Icons.self_improvement_rounded), findsOneWidget);
      expect(find.text(noneToday.reason), findsOneWidget);
    },
  );
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

ExerciseRecommendationPolicyContext _context({
  String lifestyleType = 'Lightly Active',
  String exerciseGoalDays = '5+ days',
  int steps = 3000,
  bool needsRecovery = false,
  int? energyLevel,
  double? sleepHours,
  int? sleepQuality,
  String? workloadHoursBand,
  String? burnoutPatternFocus,
  String? burnoutPatternSeverity,
  bool outdoorSafe = true,
  bool gentleOutdoor = false,
  bool airSafe = true,
  String weatherReason = 'Weather looks safe for outdoor movement.',
  ExerciseGoalHistorySummary history = ExerciseGoalHistorySummary.empty,
}) {
  return ExerciseRecommendationPolicyContext(
    lifestyleType: lifestyleType,
    exerciseGoalDays: exerciseGoalDays,
    steps: steps,
    needsRecovery: needsRecovery,
    energyLevel: energyLevel,
    sleepHours: sleepHours,
    sleepQuality: sleepQuality,
    workloadHoursBand: workloadHoursBand,
    burnoutPatternFocus: burnoutPatternFocus,
    burnoutPatternSeverity: burnoutPatternSeverity,
    outdoorSafe: outdoorSafe,
    gentleOutdoor: gentleOutdoor,
    airSafe: airSafe,
    weatherReason: weatherReason,
    history: history,
  );
}
