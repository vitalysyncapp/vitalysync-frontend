class ActivityLog {
  static const int defaultGoalSteps = 5000;
  static const double stepLengthMeters = 0.75;

  final String logDate;
  final int steps;
  final double distanceMeters;
  final int activeMinutes;
  final double caloriesBurned;
  final String exerciseType;
  final int goalSteps;
  final double goalDistanceMeters;
  final bool goalCompleted;
  final String source;

  const ActivityLog({
    required this.logDate,
    required this.steps,
    required this.distanceMeters,
    required this.activeMinutes,
    required this.caloriesBurned,
    required this.exerciseType,
    required this.goalSteps,
    required this.goalDistanceMeters,
    required this.goalCompleted,
    required this.source,
  });

  factory ActivityLog.empty({required String logDate}) {
    return ActivityLog.fromSteps(logDate: logDate, steps: 0);
  }

  factory ActivityLog.fromSteps({
    required String logDate,
    required int steps,
    int goalSteps = defaultGoalSteps,
    String source = 'phone_sensor',
  }) {
    final safeSteps = steps < 0 ? 0 : steps;
    final safeGoalSteps = goalSteps < 0 ? defaultGoalSteps : goalSteps;
    final distanceMeters = safeSteps * stepLengthMeters;
    final goalDistanceMeters = safeGoalSteps * stepLengthMeters;

    return ActivityLog(
      logDate: logDate,
      steps: safeSteps,
      distanceMeters: distanceMeters,
      activeMinutes: (safeSteps / 100).round(),
      caloriesBurned: safeSteps * 0.04,
      exerciseType: 'walking',
      goalSteps: safeGoalSteps,
      goalDistanceMeters: goalDistanceMeters,
      goalCompleted:
          safeSteps >= safeGoalSteps || distanceMeters >= goalDistanceMeters,
      source: source,
    );
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final steps = _parseInt(json['steps']);
    final goalSteps = _parseInt(json['goal_steps'], fallback: defaultGoalSteps);
    final distanceMeters = _parseDouble(
      json['distance_meters'],
      fallback: steps * stepLengthMeters,
    );
    final goalDistanceMeters = _parseDouble(
      json['goal_distance_meters'],
      fallback: goalSteps * stepLengthMeters,
    );
    final rawDate = (json['log_date'] ?? '').toString();
    final logDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

    return ActivityLog(
      logDate: logDate,
      steps: steps,
      distanceMeters: distanceMeters,
      activeMinutes: _parseInt(json['active_minutes']),
      caloriesBurned: _parseDouble(json['calories_burned']),
      exerciseType: (json['exercise_type'] ?? 'walking').toString(),
      goalSteps: goalSteps,
      goalDistanceMeters: goalDistanceMeters,
      goalCompleted:
          json['goal_completed'] == true ||
          steps >= goalSteps ||
          distanceMeters >= goalDistanceMeters,
      source: (json['source'] ?? 'phone_sensor').toString(),
    );
  }

  double get distanceKm => distanceMeters / 1000;

  double get progress {
    if (goalSteps <= 0) {
      return goalCompleted ? 1 : 0;
    }

    return (steps / goalSteps).clamp(0.0, 1.0).toDouble();
  }

  String get statusLabel {
    if (goalCompleted) {
      return 'Goal completed';
    }

    if (steps == 0) {
      return 'Ready to track';
    }

    if (progress >= 0.75) {
      return 'Almost there';
    }

    if (progress >= 0.35) {
      return 'Steady progress';
    }

    return 'Light movement';
  }

  ActivityLog copyWith({
    String? logDate,
    int? steps,
    double? distanceMeters,
    int? activeMinutes,
    double? caloriesBurned,
    String? exerciseType,
    int? goalSteps,
    double? goalDistanceMeters,
    bool? goalCompleted,
    String? source,
  }) {
    return ActivityLog(
      logDate: logDate ?? this.logDate,
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      exerciseType: exerciseType ?? this.exerciseType,
      goalSteps: goalSteps ?? this.goalSteps,
      goalDistanceMeters: goalDistanceMeters ?? this.goalDistanceMeters,
      goalCompleted: goalCompleted ?? this.goalCompleted,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_date': logDate,
      'steps': steps,
      'distance_meters': distanceMeters,
      'active_minutes': activeMinutes,
      'calories_burned': caloriesBurned,
      'exercise_type': exerciseType,
      'goal_steps': goalSteps,
      'goal_distance_meters': goalDistanceMeters,
      'goal_completed': goalCompleted,
      'source': source,
    };
  }
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('${value ?? ''}') ?? fallback;
}

double _parseDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse('${value ?? ''}') ?? fallback;
}
