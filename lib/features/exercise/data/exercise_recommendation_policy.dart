import 'exercise_goal_model.dart';
import 'exercise_recommendation_model.dart';

enum ExerciseEffortLevel { restorative, light, moderate, active, veryActive }

extension ExerciseEffortLevelLabel on ExerciseEffortLevel {
  String get label {
    switch (this) {
      case ExerciseEffortLevel.restorative:
        return 'Restorative';
      case ExerciseEffortLevel.light:
        return 'Light';
      case ExerciseEffortLevel.moderate:
        return 'Moderate';
      case ExerciseEffortLevel.active:
        return 'Active';
      case ExerciseEffortLevel.veryActive:
        return 'Very Active';
    }
  }
}

class ExerciseGoalHistorySummary {
  final int completedStreak;
  final int missedStreak;

  const ExerciseGoalHistorySummary({
    required this.completedStreak,
    required this.missedStreak,
  });

  static const empty = ExerciseGoalHistorySummary(
    completedStreak: 0,
    missedStreak: 0,
  );
}

class ExerciseEffortPlan {
  final ExerciseEffortLevel baselineLevel;
  final ExerciseEffortLevel targetLevel;
  final String lifestyleLabel;
  final String note;

  const ExerciseEffortPlan({
    required this.baselineLevel,
    required this.targetLevel,
    required this.lifestyleLabel,
    required this.note,
  });
}

class ExerciseRecommendationPolicyContext {
  final String? lifestyleType;
  final String? exerciseGoalDays;
  final int steps;
  final bool needsRecovery;
  final bool outdoorSafe;
  final bool gentleOutdoor;
  final bool airSafe;
  final String weatherReason;
  final ExerciseGoalHistorySummary history;

  const ExerciseRecommendationPolicyContext({
    required this.lifestyleType,
    required this.exerciseGoalDays,
    required this.steps,
    required this.needsRecovery,
    required this.outdoorSafe,
    required this.gentleOutdoor,
    required this.airSafe,
    required this.weatherReason,
    required this.history,
  });
}

class ExerciseRecommendationPolicyResult {
  final ExerciseEffortPlan plan;
  final List<ExerciseRecommendationModel> recommendations;

  const ExerciseRecommendationPolicyResult({
    required this.plan,
    required this.recommendations,
  });
}

class ExerciseRecommendationPolicy {
  const ExerciseRecommendationPolicy._();

  static ExerciseGoalHistorySummary summarizeGoalHistory(
    List<ExerciseGoalModel> goals, {
    DateTime? now,
  }) {
    if (goals.isEmpty) {
      return ExerciseGoalHistorySummary.empty;
    }

    final today = _dateOnly(now ?? DateTime.now());
    final goalsByDate = <String, ExerciseGoalModel>{};
    DateTime? earliest;

    for (final goal in goals) {
      final date = _parseDateKey(goal.logDate);
      if (date == null || !date.isBefore(today)) {
        continue;
      }

      goalsByDate[_dateKey(date)] = goal;
      earliest = earliest == null || date.isBefore(earliest) ? date : earliest;
    }

    if (goalsByDate.isEmpty || earliest == null) {
      return ExerciseGoalHistorySummary.empty;
    }

    var completedStreak = 0;
    var missedStreak = 0;
    var cursor = today.subtract(const Duration(days: 1));

    while (!cursor.isBefore(earliest)) {
      final goal = goalsByDate[_dateKey(cursor)];
      final status = goal?.status.toLowerCase();

      if (status == 'completed') {
        if (missedStreak > 0) {
          break;
        }
        completedStreak++;
      } else {
        if (completedStreak > 0) {
          break;
        }
        missedStreak++;
      }

      cursor = cursor.subtract(const Duration(days: 1));
    }

    return ExerciseGoalHistorySummary(
      completedStreak: completedStreak,
      missedStreak: missedStreak,
    );
  }

  static ExerciseEffortPlan resolveEffortPlan({
    required String? lifestyleType,
    required String? exerciseGoalDays,
    required ExerciseGoalHistorySummary history,
    required bool needsRecovery,
  }) {
    final bounds = _lifestyleBounds(lifestyleType);
    final completedBumps = history.completedStreak ~/ 7;
    final missedDrops = history.missedStreak ~/ 3;
    final preferenceMax = _preferenceMaxLevel(
      exerciseGoalDays,
      fallbackMax: bounds.maxLevel,
    );
    final maxLevel = preferenceMax < bounds.maxLevel
        ? preferenceMax
        : bounds.maxLevel;
    var targetIndex = bounds.startLevel + completedBumps - missedDrops;
    targetIndex = _clampInt(targetIndex, bounds.minLevel, maxLevel);

    if (needsRecovery) {
      final recoveryCap = bounds.startLevel >= 3 ? 2 : 1;
      targetIndex = _clampInt(targetIndex, bounds.minLevel, recoveryCap);
    }

    final note = _planNote(
      bounds: bounds,
      history: history,
      completedBumps: completedBumps,
      missedDrops: missedDrops,
      preferenceMax: preferenceMax,
      needsRecovery: needsRecovery,
    );

    return ExerciseEffortPlan(
      baselineLevel: _levelFromIndex(bounds.startLevel),
      targetLevel: _levelFromIndex(targetIndex),
      lifestyleLabel: bounds.label,
      note: note,
    );
  }

  static ExerciseRecommendationPolicyResult buildRecommendations(
    ExerciseRecommendationPolicyContext context,
  ) {
    final plan = resolveEffortPlan(
      lifestyleType: context.lifestyleType,
      exerciseGoalDays: context.exerciseGoalDays,
      history: context.history,
      needsRecovery: context.needsRecovery,
    );
    final indoorOnly = !context.outdoorSafe || !context.airSafe;
    final reason = indoorOnly || context.gentleOutdoor
        ? '${plan.note} ${context.weatherReason}'
        : plan.note;
    final candidates = indoorOnly
        ? _indoorRecommendations(plan.targetLevel, reason)
        : context.gentleOutdoor
        ? _gentleWeatherRecommendations(plan.targetLevel, reason)
        : _outdoorRecommendations(plan.targetLevel, reason);

    if (context.steps >= 9000 && plan.targetLevel.index >= 2) {
      candidates.add(
        _activity(
          name: 'Recovery stretching',
          category: 'stretching',
          minutes: 8,
          method: 'manual',
          reason:
              '${plan.note} You already have many steps today, so recovery keeps the plan sustainable.',
        ),
      );
    }

    return ExerciseRecommendationPolicyResult(
      plan: plan,
      recommendations: _withNoneToday(candidates),
    );
  }

  static List<ExerciseRecommendationModel> _outdoorRecommendations(
    ExerciseEffortLevel level,
    String reason,
  ) {
    switch (level) {
      case ExerciseEffortLevel.restorative:
        return [
          _activity(
            name: 'Breathing exercise',
            category: 'breathing',
            minutes: 5,
            method: 'manual',
            reason: '$reason A low-load reset is enough for today.',
          ),
          _activity(
            name: '500 m walk',
            category: 'walking',
            distanceMeters: 500,
            minutes: 7,
            method: 'distance',
            reason: '$reason A tiny walk keeps momentum without pressure.',
          ),
          _activity(
            name: 'Chair mobility',
            category: 'mobility',
            minutes: 6,
            method: 'manual',
            reason: '$reason Gentle joint movement fits a recovery day.',
          ),
          _activity(
            name: 'Light stretching',
            category: 'stretching',
            minutes: 8,
            method: 'manual',
            reason: '$reason Keeps your body loose without adding strain.',
          ),
        ];
      case ExerciseEffortLevel.light:
        return [
          _activity(
            name: 'Short walk',
            category: 'walking',
            distanceMeters: 800,
            minutes: 10,
            method: 'distance',
            reason: '$reason Light movement is the best first step.',
          ),
          _activity(
            name: 'Light stretching',
            category: 'stretching',
            minutes: 10,
            method: 'manual',
            reason: '$reason A simple mobility reset supports consistency.',
          ),
          _activity(
            name: 'Gentle yoga',
            category: 'yoga',
            minutes: 12,
            method: 'manual',
            reason:
                '$reason Low-impact movement keeps the routine approachable.',
          ),
          _activity(
            name: 'Beginner bodyweight',
            category: 'bodyweight',
            minutes: 8,
            reps: 12,
            method: 'manual',
            reason: '$reason A short strength primer without overdoing it.',
          ),
        ];
      case ExerciseEffortLevel.moderate:
        return [
          _activity(
            name: 'Brisk walk',
            category: 'walking',
            distanceMeters: 1600,
            minutes: 20,
            method: 'distance',
            reason: '$reason This adds moderate cardio without a big jump.',
          ),
          _activity(
            name: 'Easy jog',
            category: 'jogging',
            distanceMeters: 1200,
            minutes: 12,
            method: 'distance',
            reason: '$reason A controlled jog gently raises intensity.',
          ),
          _activity(
            name: 'Bodyweight circuit',
            category: 'bodyweight',
            minutes: 15,
            reps: 30,
            method: 'manual',
            reason: '$reason A compact strength session fits moderate effort.',
          ),
          _activity(
            name: 'Yoga flow',
            category: 'yoga',
            minutes: 15,
            method: 'manual',
            reason: '$reason Mobility and balance keep the plan rounded.',
          ),
        ];
      case ExerciseEffortLevel.active:
        return [
          _activity(
            name: 'Jog',
            category: 'jogging',
            distanceMeters: 3000,
            minutes: 25,
            method: 'distance',
            reason: '$reason A steady jog fits an active baseline.',
          ),
          _activity(
            name: 'Strength circuit',
            category: 'strength',
            minutes: 25,
            reps: 60,
            method: 'manual',
            reason: '$reason Strength work matches a frequent exercise rhythm.',
          ),
          _activity(
            name: 'Jump rope intervals',
            category: 'cardio',
            minutes: 10,
            method: 'manual',
            reason:
                '$reason Short intervals add challenge without taking long.',
          ),
          _activity(
            name: 'Push-up and squat sets',
            category: 'bodyweight',
            minutes: 20,
            reps: 50,
            method: 'manual',
            reason: '$reason Bodyweight volume fits active conditioning.',
          ),
        ];
      case ExerciseEffortLevel.veryActive:
        return [
          _activity(
            name: 'Gym strength session',
            category: 'strength',
            minutes: 45,
            method: 'manual',
            reason:
                '$reason A full gym session fits your very active baseline.',
          ),
          _activity(
            name: 'Long jog',
            category: 'jogging',
            distanceMeters: 5000,
            minutes: 35,
            method: 'distance',
            reason: '$reason Longer cardio matches high activity capacity.',
          ),
          _activity(
            name: 'Run',
            category: 'running',
            distanceMeters: 3000,
            minutes: 20,
            method: 'distance',
            reason: '$reason A focused run keeps intensity high.',
          ),
          _activity(
            name: 'Push-ups and jump rope',
            category: 'conditioning',
            minutes: 25,
            reps: 60,
            method: 'manual',
            reason:
                '$reason Bodyweight and rope work fit a very active routine.',
          ),
          _activity(
            name: 'Jump rope',
            category: 'cardio',
            minutes: 15,
            method: 'manual',
            reason: '$reason Conditioning work fits high daily activity.',
          ),
        ];
    }
  }

  static List<ExerciseRecommendationModel> _indoorRecommendations(
    ExerciseEffortLevel level,
    String reason,
  ) {
    switch (level) {
      case ExerciseEffortLevel.restorative:
        return [
          _activity(
            name: 'Breathing exercise',
            category: 'breathing',
            minutes: 5,
            method: 'manual',
            reason: '$reason Stay indoors and keep effort restorative.',
          ),
          _activity(
            name: 'Chair mobility',
            category: 'mobility',
            minutes: 6,
            method: 'manual',
            reason: '$reason Gentle indoor mobility is the safer fit.',
          ),
          _activity(
            name: 'Light stretching',
            category: 'stretching',
            minutes: 8,
            method: 'manual',
            reason: '$reason Low-impact movement works well indoors.',
          ),
        ];
      case ExerciseEffortLevel.light:
        return [
          _activity(
            name: 'Gentle yoga',
            category: 'yoga',
            minutes: 12,
            method: 'manual',
            reason: '$reason This keeps today light and weather-safe.',
          ),
          _activity(
            name: 'Light stretching',
            category: 'stretching',
            minutes: 10,
            method: 'manual',
            reason: '$reason A simple indoor reset protects consistency.',
          ),
          _activity(
            name: 'Indoor walk',
            category: 'walking',
            minutes: 10,
            method: 'manual',
            reason: '$reason Stay inside while still adding light movement.',
          ),
          _activity(
            name: 'Breathing exercise',
            category: 'breathing',
            minutes: 5,
            method: 'manual',
            reason: '$reason A safe option when conditions are not ideal.',
          ),
        ];
      case ExerciseEffortLevel.moderate:
        return [
          _activity(
            name: 'Bodyweight circuit',
            category: 'bodyweight',
            minutes: 15,
            reps: 30,
            method: 'manual',
            reason: '$reason Moderate effort can stay indoors today.',
          ),
          _activity(
            name: 'Yoga flow',
            category: 'yoga',
            minutes: 15,
            method: 'manual',
            reason: '$reason Controlled indoor movement fits the conditions.',
          ),
          _activity(
            name: 'Indoor cardio',
            category: 'cardio',
            minutes: 15,
            method: 'manual',
            reason: '$reason Keeps cardio available without outdoor exposure.',
          ),
          _activity(
            name: 'Core session',
            category: 'strength',
            minutes: 12,
            reps: 30,
            method: 'manual',
            reason: '$reason A compact indoor strength option.',
          ),
        ];
      case ExerciseEffortLevel.active:
        return [
          _activity(
            name: 'Strength circuit',
            category: 'strength',
            minutes: 25,
            reps: 60,
            method: 'manual',
            reason: '$reason Active training can stay indoors today.',
          ),
          _activity(
            name: 'Jump rope intervals',
            category: 'cardio',
            minutes: 10,
            method: 'manual',
            reason: '$reason Intensity stays high without going outside.',
          ),
          _activity(
            name: 'Push-up and squat sets',
            category: 'bodyweight',
            minutes: 20,
            reps: 50,
            method: 'manual',
            reason: '$reason Bodyweight work fits an active indoor plan.',
          ),
          _activity(
            name: 'Indoor cardio',
            category: 'cardio',
            minutes: 20,
            method: 'manual',
            reason: '$reason Keeps the session active while avoiding weather.',
          ),
        ];
      case ExerciseEffortLevel.veryActive:
        return [
          _activity(
            name: 'Gym strength session',
            category: 'strength',
            minutes: 45,
            method: 'manual',
            reason: '$reason Gym training avoids poor outdoor conditions.',
          ),
          _activity(
            name: 'Jump rope',
            category: 'cardio',
            minutes: 15,
            method: 'manual',
            reason: '$reason Conditioning stays intense and indoor-friendly.',
          ),
          _activity(
            name: 'Push-ups',
            category: 'bodyweight',
            minutes: 20,
            reps: 60,
            method: 'manual',
            reason: '$reason High-volume bodyweight work fits your baseline.',
          ),
          _activity(
            name: 'Strength circuit',
            category: 'strength',
            minutes: 30,
            reps: 80,
            method: 'manual',
            reason: '$reason A strong indoor session replaces outdoor cardio.',
          ),
        ];
    }
  }

  static List<ExerciseRecommendationModel> _gentleWeatherRecommendations(
    ExerciseEffortLevel level,
    String reason,
  ) {
    if (level.index <= ExerciseEffortLevel.light.index) {
      return _outdoorRecommendations(level, reason);
    }

    final adjustedLevel = level.index >= ExerciseEffortLevel.active.index
        ? ExerciseEffortLevel.active
        : level;
    final recommendations = _outdoorRecommendations(adjustedLevel, reason);
    recommendations.insert(
      0,
      _activity(
        name: 'Controlled walk',
        category: 'walking',
        distanceMeters: 1000,
        minutes: 12,
        method: 'distance',
        reason: '$reason Outdoor movement should stay controlled today.',
      ),
    );
    return recommendations;
  }

  static List<ExerciseRecommendationModel> _withNoneToday(
    List<ExerciseRecommendationModel> candidates,
  ) {
    final unique = <String, ExerciseRecommendationModel>{};
    for (final item in candidates) {
      unique.putIfAbsent(item.exerciseName, () => item);
    }

    return [
      ...unique.values.take(4),
      const ExerciseRecommendationModel(
        exerciseName: 'None today',
        exerciseCategory: 'none',
        targetDistanceMeters: null,
        targetMinutes: null,
        targetReps: null,
        completionMethod: 'none',
        reason: 'Save an intentional rest day instead of skipping by accident.',
      ),
    ];
  }

  static ExerciseRecommendationModel _activity({
    required String name,
    required String category,
    double? distanceMeters,
    int? minutes,
    int? reps,
    required String method,
    required String reason,
  }) {
    return ExerciseRecommendationModel(
      exerciseName: name,
      exerciseCategory: category,
      targetDistanceMeters: distanceMeters,
      targetMinutes: minutes,
      targetReps: reps,
      completionMethod: method,
      reason: reason,
    );
  }

  static String _planNote({
    required _LifestyleBounds bounds,
    required ExerciseGoalHistorySummary history,
    required int completedBumps,
    required int missedDrops,
    required int preferenceMax,
    required bool needsRecovery,
  }) {
    if (needsRecovery) {
      return 'Kept gentler for sleep or burnout recovery.';
    }

    if (preferenceMax < bounds.maxLevel) {
      return 'Aligned with your exercise-day preference.';
    }

    if (missedDrops > 0) {
      return 'Lowered after ${history.missedStreak} none or missed days.';
    }

    if (completedBumps > 0) {
      return 'Raised after ${history.completedStreak} completed days.';
    }

    return 'Matches your ${bounds.label} lifestyle baseline.';
  }

  static int _preferenceMaxLevel(
    String? exerciseGoalDays, {
    required int fallbackMax,
  }) {
    final normalized = exerciseGoalDays?.trim().toLowerCase() ?? '';
    if (normalized == '0 days') {
      return 0;
    }
    if (normalized == '1-2 days') {
      return fallbackMax < 2 ? fallbackMax : 2;
    }
    return fallbackMax;
  }

  static _LifestyleBounds _lifestyleBounds(String? lifestyleType) {
    final normalized = lifestyleType?.trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'sedentary':
        return const _LifestyleBounds(
          label: 'Sedentary',
          minLevel: 0,
          startLevel: 1,
          maxLevel: 2,
        );
      case 'lightly active':
        return const _LifestyleBounds(
          label: 'Lightly Active',
          minLevel: 0,
          startLevel: 1,
          maxLevel: 3,
        );
      case 'moderately active':
        return const _LifestyleBounds(
          label: 'Moderately Active',
          minLevel: 0,
          startLevel: 2,
          maxLevel: 4,
        );
      case 'active':
        return const _LifestyleBounds(
          label: 'Active',
          minLevel: 0,
          startLevel: 3,
          maxLevel: 4,
        );
      case 'very active':
        return const _LifestyleBounds(
          label: 'Very Active',
          minLevel: 0,
          startLevel: 4,
          maxLevel: 4,
        );
      default:
        return const _LifestyleBounds(
          label: 'Lightly Active',
          minLevel: 0,
          startLevel: 1,
          maxLevel: 3,
        );
    }
  }

  static ExerciseEffortLevel _levelFromIndex(int index) {
    if (index <= 0) {
      return ExerciseEffortLevel.restorative;
    }
    if (index >= ExerciseEffortLevel.values.length - 1) {
      return ExerciseEffortLevel.veryActive;
    }
    return ExerciseEffortLevel.values[index];
  }

  static int _clampInt(int value, int min, int max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  static DateTime? _parseDateKey(String value) {
    if (value.length < 10) {
      return null;
    }
    final parsed = DateTime.tryParse(value.substring(0, 10));
    return parsed == null ? null : _dateOnly(parsed);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _LifestyleBounds {
  final String label;
  final int minLevel;
  final int startLevel;
  final int maxLevel;

  const _LifestyleBounds({
    required this.label,
    required this.minLevel,
    required this.startLevel,
    required this.maxLevel,
  });
}
