class ExerciseRecommendationModel {
  final String exerciseName;
  final String exerciseCategory;
  final double? targetDistanceMeters;
  final int? targetMinutes;
  final int? targetReps;
  final String completionMethod;
  final String reason;
  final String recommendedBy;

  const ExerciseRecommendationModel({
    required this.exerciseName,
    required this.exerciseCategory,
    required this.targetDistanceMeters,
    required this.targetMinutes,
    required this.targetReps,
    required this.completionMethod,
    required this.reason,
    this.recommendedBy = 'vitalysync_assistant',
  });

  bool get isNoneToday => exerciseName.toLowerCase() == 'none today';

  bool get isDistanceBased {
    return completionMethod == 'distance' || completionMethod == 'steps';
  }

  String get targetLabel {
    if (isNoneToday) {
      return 'Rest day saved';
    }

    final distance = targetDistanceMeters;
    if (distance != null && distance > 0) {
      final km = distance / 1000;
      return km < 1 ? '${distance.round()} m' : '${km.toStringAsFixed(1)} km';
    }

    final minutes = targetMinutes;
    if (minutes != null && minutes > 0) {
      return '$minutes min';
    }

    final reps = targetReps;
    if (reps != null && reps > 0) {
      return '$reps reps';
    }

    return 'Light effort';
  }

  Map<String, dynamic> toGoalJson({required String logDate}) {
    return {
      'log_date': logDate,
      'recommended_by': recommendedBy,
      'exercise_name': exerciseName,
      'exercise_category': exerciseCategory,
      'target_distance_meters': targetDistanceMeters,
      'target_minutes': targetMinutes,
      'target_reps': targetReps,
      'completion_method': completionMethod,
      'status': isNoneToday ? 'none' : 'active',
    };
  }
}
