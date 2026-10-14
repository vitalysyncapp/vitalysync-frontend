enum CheckInMode {
  daily,
  weekly;

  String get apiValue => name;

  static CheckInMode fromValue(Object? value) {
    return value?.toString().toLowerCase() == 'weekly'
        ? CheckInMode.weekly
        : CheckInMode.daily;
  }
}

class CheckInFormOptions {
  static const workloadHoursBands = [
    'None',
    '1-2 hours',
    '3-4 hours',
    '5-6 hours',
    '6-7 hours',
    '8-9 hours',
    '10-12 hours',
  ];
  static const sleepLabels = ['Poor', 'Fair', 'Good', 'Very good', 'Excellent'];
  static const sleepStars = [1, 2, 3, 4, 5];
  static const moods = [
    '\u{1F61E}',
    '\u{1F641}',
    '\u{1F610}',
    '\u{1F642}',
    '\u{1F60A}',
  ];
  static const symptoms = [
    'Headache',
    'Fatigue',
    'Irritability',
    'Anxiety',
    'Body pain',
    'Back pain',
    'None',
  ];
  static const habits = [
    'Quiet break',
    'Sunlight or fresh air',
    'Deep breathing',
    'Meditation',
    'Less screen time',
    'Talked with someone',
    'Read a book',
    'Listened to music',
    'Hobby or creative activity',
    'None',
  ];

  const CheckInFormOptions._();
}

class CheckInDraft {
  static const Object _unset = Object();

  final double sleepHours;
  final int sleepQuality;
  final int moodIndex;
  final int? energyLevel;
  final double hydrationLiters;
  final String workloadHoursBand;
  final Set<String> exerciseNames;
  final Set<String> symptomNames;
  final Set<String> habitNames;
  final int? perceivedPressureLevel;
  final int? recoveryRestLevel;
  final int? detachmentLevel;
  final int? productivityFocusLevel;
  final int? accomplishmentLevel;

  const CheckInDraft({
    this.sleepHours = 7,
    this.sleepQuality = 2,
    this.moodIndex = 3,
    this.energyLevel,
    this.hydrationLiters = 0.5,
    this.workloadHoursBand = 'None',
    this.exerciseNames = const <String>{},
    this.symptomNames = const <String>{},
    this.habitNames = const <String>{},
    this.perceivedPressureLevel,
    this.recoveryRestLevel,
    this.detachmentLevel,
    this.productivityFocusLevel,
    this.accomplishmentLevel,
  });

  factory CheckInDraft.fromJson({
    Map<String, dynamic>? daily,
    Map<String, dynamic>? weekly,
    double defaultSleepHours = 7,
    double hydrationPrefill = 0,
    String? exercisePrefill,
  }) {
    final hasDaily = daily != null;
    final exercises = _stringSet(daily?['exercise_names']);
    if (exercisePrefill != null && exercisePrefill.isNotEmpty) {
      exercises
        ..clear()
        ..add(exercisePrefill);
    }

    return CheckInDraft(
      sleepHours: hasDaily
          ? _doubleValue(daily['sleep_hours'], defaultSleepHours)
          : defaultSleepHours,
      sleepQuality: hasDaily ? _intValue(daily['sleep_quality'], 2) : 2,
      moodIndex: hasDaily ? _intValue(daily['mood_index'], 3) : 3,
      energyLevel: _optionalInt(daily?['energy_level']),
      hydrationLiters: hasDaily
          ? (_doubleValue(daily['hydration_liters'], 0.5) + hydrationPrefill)
                .clamp(0, 10)
                .toDouble()
          : hydrationPrefill > 0
          ? hydrationPrefill.clamp(0, 10).toDouble()
          : 0.5,
      workloadHoursBand:
          daily?['workload_hours_band']?.toString().trim().isNotEmpty == true
          ? daily!['workload_hours_band'].toString()
          : 'None',
      exerciseNames: exercises,
      symptomNames: _stringSet(daily?['symptom_names']),
      habitNames: _stringSet(daily?['habit_names'])
          .map(_readableHabitName)
          .where(CheckInFormOptions.habits.contains)
          .toSet(),
      perceivedPressureLevel: _optionalInt(
        weekly?['perceived_pressure_level'] ?? daily?['perceived_stress_level'],
      ),
      recoveryRestLevel: _optionalInt(
        weekly?['recovery_rest_level'] ?? daily?['break_quality_level'],
      ),
      detachmentLevel: _optionalInt(
        weekly?['detachment_level'] ?? daily?['daily_detachment_level'],
      ),
      productivityFocusLevel: _optionalInt(
        weekly?['productivity_focus_level'] ?? daily?['daily_focus_level'],
      ),
      accomplishmentLevel: _optionalInt(
        weekly?['accomplishment_level'] ?? daily?['daily_accomplishment_level'],
      ),
    );
  }

  CheckInDraft copyWith({
    double? sleepHours,
    int? sleepQuality,
    int? moodIndex,
    Object? energyLevel = _unset,
    double? hydrationLiters,
    String? workloadHoursBand,
    Set<String>? exerciseNames,
    Set<String>? symptomNames,
    Set<String>? habitNames,
    Object? perceivedPressureLevel = _unset,
    Object? recoveryRestLevel = _unset,
    Object? detachmentLevel = _unset,
    Object? productivityFocusLevel = _unset,
    Object? accomplishmentLevel = _unset,
  }) {
    return CheckInDraft(
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      moodIndex: moodIndex ?? this.moodIndex,
      energyLevel: identical(energyLevel, _unset)
          ? this.energyLevel
          : energyLevel as int?,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      workloadHoursBand: workloadHoursBand ?? this.workloadHoursBand,
      exerciseNames: exerciseNames ?? this.exerciseNames,
      symptomNames: symptomNames ?? this.symptomNames,
      habitNames: habitNames ?? this.habitNames,
      perceivedPressureLevel: identical(perceivedPressureLevel, _unset)
          ? this.perceivedPressureLevel
          : perceivedPressureLevel as int?,
      recoveryRestLevel: identical(recoveryRestLevel, _unset)
          ? this.recoveryRestLevel
          : recoveryRestLevel as int?,
      detachmentLevel: identical(detachmentLevel, _unset)
          ? this.detachmentLevel
          : detachmentLevel as int?,
      productivityFocusLevel: identical(productivityFocusLevel, _unset)
          ? this.productivityFocusLevel
          : productivityFocusLevel as int?,
      accomplishmentLevel: identical(accomplishmentLevel, _unset)
          ? this.accomplishmentLevel
          : accomplishmentLevel as int?,
    );
  }

  List<String> validationErrors(CheckInMode mode) {
    final errors = <String>[];
    if (sleepHours < 0 || sleepHours > 24) errors.add('sleep duration');
    if (sleepQuality < 0 || sleepQuality > 4) errors.add('sleep quality');
    if (moodIndex < 0 || moodIndex > 4) errors.add('mood');
    if (energyLevel == null || energyLevel! < 1 || energyLevel! > 5) {
      errors.add('energy');
    }
    if (hydrationLiters <= 0 || hydrationLiters > 20) {
      errors.add('hydration');
    }
    if (!CheckInFormOptions.workloadHoursBands.contains(workloadHoursBand)) {
      errors.add('workload');
    }
    _validateSelection(errors, exerciseNames, 'exercise');
    _validateSelection(errors, symptomNames, 'symptoms');
    _validateSelection(errors, habitNames, 'recovery habits');

    if (mode == CheckInMode.weekly) {
      if (!_validLikert(perceivedPressureLevel)) errors.add('pressure');
      if (!_validLikert(recoveryRestLevel)) errors.add('recovery breaks');
      if (!_validLikert(detachmentLevel)) errors.add('detachment');
      if (!_validLikert(productivityFocusLevel)) errors.add('focus');
      if (!_validLikert(accomplishmentLevel)) errors.add('accomplishment');
    }
    return errors;
  }

  Map<String, dynamic> dailyJson() {
    return {
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'mood_index': moodIndex,
      'energy_level': energyLevel,
      'hydration_liters': hydrationLiters,
      'workload_hours_band': workloadHoursBand,
      'exercise_names': exerciseNames.toList()..sort(),
      'symptom_names': symptomNames.toList()..sort(),
      'habit_names': habitNames.toList()..sort(),
    };
  }

  Map<String, dynamic> weeklyJson() {
    return {
      'perceived_pressure_level': perceivedPressureLevel,
      'recovery_rest_level': recoveryRestLevel,
      'detachment_level': detachmentLevel,
      'productivity_focus_level': productivityFocusLevel,
      'accomplishment_level': accomplishmentLevel,
    };
  }

  static void _validateSelection(
    List<String> errors,
    Set<String> values,
    String label,
  ) {
    if (values.isEmpty || (values.contains('None') && values.length > 1)) {
      errors.add(label);
    }
  }

  static bool _validLikert(int? value) =>
      value != null && value >= 1 && value <= 5;
}

class CheckInSchedule {
  final bool isDue;
  final bool isOverdue;
  final bool completedToday;
  final String? dueDate;
  final String? nextDueDate;
  final int pulseWeekday;

  const CheckInSchedule({
    this.isDue = false,
    this.isOverdue = false,
    this.completedToday = false,
    this.dueDate,
    this.nextDueDate,
    this.pulseWeekday = DateTime.monday,
  });

  factory CheckInSchedule.fromJson(Map<String, dynamic>? json) {
    return CheckInSchedule(
      isDue: json?['is_due'] == true,
      isOverdue: json?['is_overdue'] == true,
      completedToday: json?['completed_today'] == true,
      dueDate: json?['due_date']?.toString(),
      nextDueDate: json?['next_due_date']?.toString(),
      pulseWeekday: _intValue(json?['pulse_weekday'], DateTime.monday),
    );
  }
}

class CheckInStatus {
  final CheckInMode requiredMode;
  final bool hasTodayLog;
  final CheckInSchedule schedule;
  final Map<String, dynamic>? daily;
  final Map<String, dynamic>? weekly;
  final bool isOffline;
  final int pendingSyncCount;
  final bool requiresBaselineRefresh;
  final String? baselineRefreshReason;
  final String? lastLoggedDate;
  final int? daysSinceLastLog;

  const CheckInStatus({
    required this.requiredMode,
    required this.hasTodayLog,
    required this.schedule,
    this.daily,
    this.weekly,
    this.isOffline = false,
    this.pendingSyncCount = 0,
    this.requiresBaselineRefresh = false,
    this.baselineRefreshReason,
    this.lastLoggedDate,
    this.daysSinceLastLog,
  });

  bool get isComplete =>
      !requiresBaselineRefresh &&
      hasTodayLog &&
      (requiredMode == CheckInMode.daily || schedule.completedToday);

  factory CheckInStatus.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? pendingPayload,
    bool isOffline = false,
    int pendingSyncCount = 0,
    String? localDate,
  }) {
    final existing = json['existing_check_in'];
    final existingMap = existing is Map
        ? Map<String, dynamic>.from(existing)
        : const <String, dynamic>{};
    final pendingDaily = pendingPayload?['daily'];
    final pendingWeekly = pendingPayload?['weekly'];
    final schedule = CheckInSchedule.fromJson(
      json['schedule'] is Map
          ? Map<String, dynamic>.from(json['schedule'] as Map)
          : null,
    );
    var mode = CheckInMode.fromValue(json['required_mode']);
    final today = localDate ?? _dateKey(DateTime.now());
    final dueDate = schedule.dueDate ?? schedule.nextDueDate;
    if (isOffline &&
        !schedule.completedToday &&
        dueDate != null &&
        dueDate.compareTo(today) <= 0) {
      mode = CheckInMode.weekly;
    }
    final daily = pendingDaily is Map
        ? Map<String, dynamic>.from(pendingDaily)
        : existingMap['daily'] is Map
        ? Map<String, dynamic>.from(existingMap['daily'] as Map)
        : null;
    final weekly = pendingWeekly is Map
        ? Map<String, dynamic>.from(pendingWeekly)
        : existingMap['weekly'] is Map
        ? Map<String, dynamic>.from(existingMap['weekly'] as Map)
        : null;

    return CheckInStatus(
      requiredMode: mode,
      hasTodayLog: json['has_today_log'] == true || daily != null,
      schedule: schedule,
      daily: daily,
      weekly: weekly,
      isOffline: isOffline,
      pendingSyncCount: pendingSyncCount,
      requiresBaselineRefresh: json['requires_baseline_refresh'] == true,
      baselineRefreshReason: json['baseline_refresh_reason']?.toString(),
      lastLoggedDate: json['last_logged_date']?.toString(),
      daysSinceLastLog: _optionalInt(json['days_since_last_log']),
    );
  }
}

int _intValue(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  final parsed = _intValue(value, -1);
  return parsed < 0 ? null : parsed;
}

double _doubleValue(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

Set<String> _stringSet(Object? value) {
  if (value is! List) return <String>{};
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet();
}

String _readableHabitName(String habit) {
  return switch (habit) {
    'Mindful break' => 'Quiet break',
    'Outdoor light' => 'Sunlight or fresh air',
    'Screen boundary' => 'Less screen time',
    'Healthy meal' => 'Balanced meal',
    'Social connection' => 'Talked with someone',
    _ => habit,
  };
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
