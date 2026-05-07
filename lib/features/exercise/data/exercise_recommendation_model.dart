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

  factory ExerciseRecommendationModel.fromJson(Map<String, dynamic> json) {
    return ExerciseRecommendationModel(
      exerciseName: json['exercise_name']?.toString() ?? 'None today',
      exerciseCategory: json['exercise_category']?.toString() ?? 'none',
      targetDistanceMeters: _parseNullableDouble(
        json['target_distance_meters'],
      ),
      targetMinutes: _parseNullableInt(json['target_minutes']),
      targetReps: _parseNullableInt(json['target_reps']),
      completionMethod: json['completion_method']?.toString() ?? 'none',
      reason: json['reason']?.toString() ?? '',
      recommendedBy:
          json['recommended_by']?.toString() ?? 'vitalysync_assistant',
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'recommended_by': recommendedBy,
      'exercise_name': exerciseName,
      'exercise_category': exerciseCategory,
      'target_distance_meters': targetDistanceMeters,
      'target_minutes': targetMinutes,
      'target_reps': targetReps,
      'completion_method': completionMethod,
      'reason': reason,
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
