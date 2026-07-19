import 'package:shared_preferences/shared_preferences.dart';

class OnboardingDefaults {
  final String? role;
  final String? lifestyleType;
  final String? wellnessGoal;
  final List<String> wellnessGoals;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? usualSleepTime;
  final String? usualWakeTime;
  final String? exerciseGoalDays;
  final int? workloadLevel;
  final double? initialBurnoutScore;
  final String? initialBurnoutLevel;

  const OnboardingDefaults({
    this.role,
    this.lifestyleType,
    this.wellnessGoal,
    this.wellnessGoals = const <String>[],
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.usualSleepTime,
    this.usualWakeTime,
    this.exerciseGoalDays,
    this.workloadLevel,
    this.initialBurnoutScore,
    this.initialBurnoutLevel,
  });

  double sleepHours({double fallback = 7}) {
    return OnboardingService.sleepHoursBetween(
      usualSleepTime,
      usualWakeTime,
      fallback: fallback,
    );
  }

  int get burnoutScoreForDisplay {
    final score = initialBurnoutScore;
    if (score == null) {
      return 40;
    }

    return score.round().clamp(0, 100);
  }
}

class OnboardingService {
  static const String roleKey = 'onboarding_role';
  static const String lifestyleTypeKey = 'onboarding_lifestyle_type';
  static const String wellnessGoalKey = 'onboarding_wellness_goal';
  static const String wellnessGoalsKey = 'onboarding_wellness_goals';
  static const String heightCmKey = 'onboarding_height_cm';
  static const String weightKgKey = 'onboarding_weight_kg';
  static const String bmiKey = 'onboarding_bmi';
  static const String usualSleepTimeKey = 'onboarding_usual_sleep_time';
  static const String usualWakeTimeKey = 'onboarding_usual_wake_time';
  static const String exerciseGoalDaysKey = 'onboarding_exercise_goal_days';
  static const String workloadLevelKey = 'onboarding_workload_level';
  static const String initialBurnoutScoreKey =
      'onboarding_initial_burnout_score';
  static const String initialBurnoutLevelKey =
      'onboarding_initial_burnout_level';

  static Future<void> saveDefaultsFromSummary(
    Map<String, dynamic> summary,
  ) async {
    final rawProfile = summary['profile'] ?? summary['onboarding_profile'];
    final profile = Map<String, dynamic>.from(
      rawProfile is Map ? rawProfile : const <String, dynamic>{},
    );

    if (profile.isEmpty) {
      return;
    }

    await saveDefaultsFromProfile(profile);
  }

  static Future<void> saveDefaultsFromProfile(
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await _setStringOrRemove(prefs, roleKey, profile['role']);
    await _setStringOrRemove(
      prefs,
      lifestyleTypeKey,
      profile['lifestyle_type'],
    );
    await _setStringOrRemove(prefs, wellnessGoalKey, profile['wellness_goal']);
    final wellnessGoals = _normalizeStringList(profile['wellness_goals']);
    await _setStringListOrRemove(
      prefs,
      wellnessGoalsKey,
      wellnessGoals.isEmpty
          ? _normalizeStringList(profile['wellness_goal'])
          : wellnessGoals,
    );
    await _setDoubleOrRemove(prefs, heightCmKey, profile['height_cm']);
    await _setDoubleOrRemove(prefs, weightKgKey, profile['weight_kg']);
    await _setDoubleOrRemove(prefs, bmiKey, profile['bmi']);
    await _setStringOrRemove(
      prefs,
      usualSleepTimeKey,
      _normalizeTime(profile['usual_sleep_time']),
    );
    await _setStringOrRemove(
      prefs,
      usualWakeTimeKey,
      _normalizeTime(profile['usual_wake_time']),
    );
    await _setStringOrRemove(
      prefs,
      exerciseGoalDaysKey,
      profile['exercise_goal_days'],
    );
    await _setIntOrRemove(prefs, workloadLevelKey, profile['workload_level']);
    await _setDoubleOrRemove(
      prefs,
      initialBurnoutScoreKey,
      profile['initial_burnout_score'],
    );
    await _setStringOrRemove(
      prefs,
      initialBurnoutLevelKey,
      profile['initial_burnout_level'],
    );
  }

  static Future<OnboardingDefaults> loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    return OnboardingDefaults(
      role: prefs.getString(roleKey),
      lifestyleType: prefs.getString(lifestyleTypeKey),
      wellnessGoal: prefs.getString(wellnessGoalKey),
      wellnessGoals: prefs.getStringList(wellnessGoalsKey) ?? const <String>[],
      heightCm: prefs.getDouble(heightCmKey),
      weightKg: prefs.getDouble(weightKgKey),
      bmi: prefs.getDouble(bmiKey),
      usualSleepTime: prefs.getString(usualSleepTimeKey),
      usualWakeTime: prefs.getString(usualWakeTimeKey),
      exerciseGoalDays: prefs.getString(exerciseGoalDaysKey),
      workloadLevel: prefs.getInt(workloadLevelKey),
      initialBurnoutScore: prefs.getDouble(initialBurnoutScoreKey),
      initialBurnoutLevel: prefs.getString(initialBurnoutLevelKey),
    );
  }

  static Future<void> clearDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      roleKey,
      lifestyleTypeKey,
      wellnessGoalKey,
      wellnessGoalsKey,
      heightCmKey,
      weightKgKey,
      bmiKey,
      usualSleepTimeKey,
      usualWakeTimeKey,
      exerciseGoalDaysKey,
      workloadLevelKey,
      initialBurnoutScoreKey,
      initialBurnoutLevelKey,
    ]) {
      await prefs.remove(key);
    }
  }

  static double sleepHoursBetween(
    String? sleepTime,
    String? wakeTime, {
    double fallback = 7,
  }) {
    final sleepMinutes = _timeToMinutes(sleepTime);
    final wakeMinutes = _timeToMinutes(wakeTime);

    if (sleepMinutes == null || wakeMinutes == null) {
      return fallback;
    }

    var adjustedWake = wakeMinutes;
    if (adjustedWake <= sleepMinutes) {
      adjustedWake += 24 * 60;
    }

    return ((adjustedWake - sleepMinutes) / 60 * 10).round() / 10;
  }

  static Future<void> _setStringOrRemove(
    SharedPreferences prefs,
    String key,
    dynamic value,
  ) async {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty) {
      await prefs.remove(key);
      return;
    }

    await prefs.setString(key, normalized);
  }

  static Future<void> _setStringListOrRemove(
    SharedPreferences prefs,
    String key,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      await prefs.remove(key);
      return;
    }

    await prefs.setStringList(key, values);
  }

  static Future<void> _setIntOrRemove(
    SharedPreferences prefs,
    String key,
    dynamic value,
  ) async {
    final parsed = value is int ? value : int.tryParse('${value ?? ''}');
    if (parsed == null) {
      await prefs.remove(key);
      return;
    }

    await prefs.setInt(key, parsed);
  }

  static Future<void> _setDoubleOrRemove(
    SharedPreferences prefs,
    String key,
    dynamic value,
  ) async {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null) {
      await prefs.remove(key);
      return;
    }

    await prefs.setDouble(key, parsed);
  }

  static int? _timeToMinutes(String? value) {
    final normalized = _normalizeTime(value);
    if (normalized == null) {
      return null;
    }

    final parts = normalized.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return hour * 60 + minute;
  }

  static String? _normalizeTime(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.length < 5) {
      return null;
    }

    final normalized = text.substring(0, 5);
    return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(normalized)
        ? normalized
        : null;
  }

  static List<String> _normalizeStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return const <String>[];
    }

    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
