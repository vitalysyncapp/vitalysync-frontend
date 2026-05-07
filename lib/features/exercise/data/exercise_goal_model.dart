import 'exercise_recommendation_model.dart';

class ExerciseGoalModel {
  final int? goalId;
  final int? userId;
  final String logDate;
  final String recommendedBy;
  final String exerciseName;
  final String exerciseCategory;
  final double? targetDistanceMeters;
  final int? targetMinutes;
  final int? targetReps;
  final String completionMethod;
  final String status;
  final DateTime? completedAt;

  const ExerciseGoalModel({
    required this.goalId,
    required this.userId,
    required this.logDate,
    required this.recommendedBy,
    required this.exerciseName,
    required this.exerciseCategory,
    required this.targetDistanceMeters,
    required this.targetMinutes,
    required this.targetReps,
    required this.completionMethod,
    required this.status,
    required this.completedAt,
  });

  factory ExerciseGoalModel.fromRecommendation({
    required ExerciseRecommendationModel recommendation,
    required String logDate,
    int? userId,
  }) {
    return ExerciseGoalModel(
      goalId: null,
      userId: userId,
      logDate: logDate,
      recommendedBy: recommendation.recommendedBy,
      exerciseName: recommendation.exerciseName,
      exerciseCategory: recommendation.exerciseCategory,
      targetDistanceMeters: recommendation.targetDistanceMeters,
      targetMinutes: recommendation.targetMinutes,
      targetReps: recommendation.targetReps,
      completionMethod: recommendation.completionMethod,
      status: recommendation.isNoneToday ? 'none' : 'active',
      completedAt: null,
    );
  }

  factory ExerciseGoalModel.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['log_date'] ?? '').toString();

    return ExerciseGoalModel(
      goalId: _parseNullableInt(json['goal_id']),
      userId: _parseNullableInt(json['user_id']),
      logDate: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      recommendedBy: (json['recommended_by'] ?? 'vitalysync_assistant')
          .toString(),
      exerciseName: (json['exercise_name'] ?? 'Exercise').toString(),
      exerciseCategory: (json['exercise_category'] ?? 'general').toString(),
      targetDistanceMeters: _parseNullableDouble(
        json['target_distance_meters'],
      ),
      targetMinutes: _parseNullableInt(json['target_minutes']),
      targetReps: _parseNullableInt(json['target_reps']),
      completionMethod: (json['completion_method'] ?? 'manual').toString(),
      status: (json['status'] ?? 'active').toString(),
      completedAt: DateTime.tryParse((json['completed_at'] ?? '').toString()),
    );
  }

  bool get isNoneToday => status == 'none';

  bool get isCanceled => status == 'canceled';

  bool get isCompleted => status == 'completed';

  bool get isActive => status == 'active';

  bool get hasSelectedGoal => !isCanceled;

  bool get isDistanceBased {
    return completionMethod == 'distance' || completionMethod == 'steps';
  }

  bool get isStepTrackedMovement {
    final category = exerciseCategory.toLowerCase();
    final name = exerciseName.toLowerCase();
    return isDistanceBased &&
        (category.contains('walking') ||
            category.contains('jogging') ||
            category.contains('running') ||
            name.contains('walk') ||
            name.contains('jog') ||
            name.contains('run'));
  }

  bool get canManualComplete => !isCompleted && !isCanceled && !isNoneToday;

  double progressForDistance(double distanceMeters) {
    final target = targetDistanceMeters ?? 0;
    if (target <= 0) {
      return isCompleted ? 1 : 0;
    }

    return (distanceMeters / target).clamp(0.0, 1.0).toDouble();
  }

  String targetLabel() {
    if (isNoneToday) {
      return 'No exercise goal today';
    }

    final distance = targetDistanceMeters;
    if (distance != null && distance > 0) {
      final km = distance / 1000;
      return km < 1 ? '${distance.round()} m' : '${km.toStringAsFixed(1)} km';
    }

    final minutes = targetMinutes;
    if (minutes != null && minutes > 0) {
      return '$minutes minutes';
    }

    final reps = targetReps;
    if (reps != null && reps > 0) {
      return '$reps reps';
    }

    return 'Light effort';
  }

  ExerciseGoalModel copyWith({
    int? goalId,
    int? userId,
    String? logDate,
    String? recommendedBy,
    String? exerciseName,
    String? exerciseCategory,
    double? targetDistanceMeters,
    int? targetMinutes,
    int? targetReps,
    String? completionMethod,
    String? status,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ExerciseGoalModel(
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      recommendedBy: recommendedBy ?? this.recommendedBy,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseCategory: exerciseCategory ?? this.exerciseCategory,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      targetReps: targetReps ?? this.targetReps,
      completionMethod: completionMethod ?? this.completionMethod,
      status: status ?? this.status,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'user_id': userId,
      'log_date': logDate,
      'recommended_by': recommendedBy,
      'exercise_name': exerciseName,
      'exercise_category': exerciseCategory,
      'target_distance_meters': targetDistanceMeters,
      'target_minutes': targetMinutes,
      'target_reps': targetReps,
      'completion_method': completionMethod,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toChooseJson() {
    return {
      'log_date': logDate,
      'recommended_by': recommendedBy,
      'exercise_name': exerciseName,
      'exercise_category': exerciseCategory,
      'target_distance_meters': targetDistanceMeters,
      'target_minutes': targetMinutes,
      'target_reps': targetReps,
      'completion_method': completionMethod,
      'status': status,
    };
  }

  Map<String, dynamic> toDailyLogMetadata() {
    return {
      'exercise_goal_name': exerciseName,
      'exercise_goal_completed': isCompleted,
      'exercise_goal_source': 'assistant',
      'exercise_goal_status': status,
    };
  }
}

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double? _parseNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}
