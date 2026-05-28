import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../offline/offline_cache_store.dart';

class UserGoalsSnapshot {
  final String wellnessGoal;
  final double sleepHours;
  final double hydrationLiters;
  final int activityDaysPerWeek;
  final int dailySteps;
  final int nutritionCalories;

  const UserGoalsSnapshot({
    required this.wellnessGoal,
    required this.sleepHours,
    required this.hydrationLiters,
    required this.activityDaysPerWeek,
    required this.dailySteps,
    required this.nutritionCalories,
  });

  factory UserGoalsSnapshot.defaults({
    String wellnessGoal = 'Not set',
    double sleepHours = 8,
    double hydrationLiters = 2.5,
    int activityDaysPerWeek = 3,
    int dailySteps = 5000,
    int nutritionCalories = 2000,
  }) {
    return UserGoalsSnapshot(
      wellnessGoal: _nonEmpty(wellnessGoal) ?? 'Not set',
      sleepHours: sleepHours.clamp(1, 24).toDouble(),
      hydrationLiters: hydrationLiters.clamp(0.25, 20).toDouble(),
      activityDaysPerWeek: activityDaysPerWeek.clamp(0, 7).toInt(),
      dailySteps: dailySteps.clamp(1000, 50000).toInt(),
      nutritionCalories: nutritionCalories.clamp(800, 6000).toInt(),
    );
  }

  factory UserGoalsSnapshot.fromApi(
    Map<String, dynamic> json, {
    UserGoalsSnapshot? fallback,
  }) {
    final defaults = fallback ?? UserGoalsSnapshot.defaults();
    final rawGoals = json['goals'] is Map
        ? Map<String, dynamic>.from(json['goals'] as Map)
        : const <String, dynamic>{};

    return UserGoalsSnapshot.defaults(
      wellnessGoal: _goalText(rawGoals['wellness']) ?? defaults.wellnessGoal,
      sleepHours: _goalDouble(rawGoals['sleep_hours']) ?? defaults.sleepHours,
      hydrationLiters:
          _goalDouble(rawGoals['hydration_liters']) ?? defaults.hydrationLiters,
      activityDaysPerWeek:
          _goalInt(rawGoals['activity_days_per_week']) ??
          defaults.activityDaysPerWeek,
      dailySteps: _goalInt(rawGoals['daily_steps']) ?? defaults.dailySteps,
      nutritionCalories:
          _goalInt(rawGoals['nutrition_calories']) ??
          defaults.nutritionCalories,
    );
  }

  UserGoalsSnapshot copyWith({
    String? wellnessGoal,
    double? sleepHours,
    double? hydrationLiters,
    int? activityDaysPerWeek,
    int? dailySteps,
    int? nutritionCalories,
  }) {
    return UserGoalsSnapshot.defaults(
      wellnessGoal: wellnessGoal ?? this.wellnessGoal,
      sleepHours: sleepHours ?? this.sleepHours,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      activityDaysPerWeek: activityDaysPerWeek ?? this.activityDaysPerWeek,
      dailySteps: dailySteps ?? this.dailySteps,
      nutritionCalories: nutritionCalories ?? this.nutritionCalories,
    );
  }

  Map<String, dynamic> toApiGoals() {
    return {
      'wellness': {'target_text': wellnessGoal, 'source': 'profile'},
      'sleep_hours': {
        'target_value': sleepHours,
        'unit': 'hours',
        'source': 'profile',
      },
      'hydration_liters': {
        'target_value': hydrationLiters,
        'unit': 'L',
        'source': 'profile',
      },
      'activity_days_per_week': {
        'target_value': activityDaysPerWeek,
        'unit': 'days/week',
        'source': 'profile',
      },
      'daily_steps': {
        'target_value': dailySteps,
        'unit': 'steps',
        'source': 'profile',
      },
      'nutrition_calories': {
        'target_value': nutritionCalories,
        'unit': 'kcal',
        'source': 'profile',
      },
    };
  }

  Map<String, dynamic> toCacheJson() {
    return {'goals': toApiGoals()};
  }

  String get sleepLabel => '${_formatNumber(sleepHours)} hours';

  String get hydrationLabel => '${_formatNumber(hydrationLiters)} L';

  String get activityLabel => '$activityDaysPerWeek days/week';

  String get dailyStepsLabel => '${_formatInt(dailySteps)} steps';

  String get nutritionLabel => '${_formatInt(nutritionCalories)} kcal';
}

class UserGoalsService {
  UserGoalsService._();

  static const Duration _requestTimeout = Duration(seconds: 8);
  static const String _cacheNamespace = 'user_goals';
  static final ValueNotifier<int> refreshSignal = ValueNotifier<int>(0);

  static Future<UserGoalsSnapshot> fetch({
    required int userId,
    UserGoalsSnapshot? defaults,
  }) async {
    if (userId <= 0) {
      return defaults ?? UserGoalsSnapshot.defaults();
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.goals('/$userId')),
            headers: await ApiConfig.acceptJsonHeaders(),
          )
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        return await loadCached(userId, defaults: defaults) ??
            (defaults ?? UserGoalsSnapshot.defaults());
      }

      await OfflineCacheStore.saveJson(
        namespace: _cacheNamespace,
        scope: userId.toString(),
        data: data,
      );
      return UserGoalsSnapshot.fromApi(data, fallback: defaults);
    } catch (_) {
      return await loadCached(userId, defaults: defaults) ??
          (defaults ?? UserGoalsSnapshot.defaults());
    }
  }

  static Future<UserGoalsSnapshot?> loadCached(
    int userId, {
    UserGoalsSnapshot? defaults,
  }) async {
    if (userId <= 0) {
      return defaults;
    }

    final data = await OfflineCacheStore.readLatestJson(
      namespace: _cacheNamespace,
      scope: userId.toString(),
    );
    if (data == null) {
      return defaults;
    }

    return UserGoalsSnapshot.fromApi(data, fallback: defaults);
  }

  static Future<UserGoalsSnapshot> save({
    required int userId,
    required UserGoalsSnapshot goals,
  }) {
    return updateGoals(userId: userId, goals: goals.toApiGoals());
  }

  static Future<UserGoalsSnapshot> updateDailySteps({
    required int userId,
    required int dailySteps,
  }) {
    return updateGoals(
      userId: userId,
      goals: {
        'daily_steps': {
          'target_value': max(1000, dailySteps),
          'unit': 'steps',
          'source': 'home',
        },
      },
    );
  }

  static Future<UserGoalsSnapshot> updateGoals({
    required int userId,
    required Map<String, dynamic> goals,
  }) async {
    if (userId <= 0) {
      return UserGoalsSnapshot.defaults();
    }

    final response = await http
        .put(
          Uri.parse(ApiConfig.goals('/$userId')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({'goals': goals}),
        )
        .timeout(_requestTimeout);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update goals');
    }

    await OfflineCacheStore.saveJson(
      namespace: _cacheNamespace,
      scope: userId.toString(),
      data: data,
    );
    refreshSignal.value++;
    return UserGoalsSnapshot.fromApi(data);
  }

  static Map<String, dynamic> _decodeResponseMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Fall through to readable fallback.
    }

    return {'message': response.reasonPhrase ?? 'Unexpected server response'};
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String? _goalText(dynamic rawGoal) {
  if (rawGoal is! Map) {
    return null;
  }

  final goal = Map<String, dynamic>.from(rawGoal);
  return _nonEmpty(goal['target_text']?.toString()) ??
      _nonEmpty(goal['display_value']?.toString());
}

double? _goalDouble(dynamic rawGoal) {
  if (rawGoal is! Map) {
    return null;
  }

  final goal = Map<String, dynamic>.from(rawGoal);
  final value = goal['target_value'];
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse('${value ?? ''}');
}

int? _goalInt(dynamic rawGoal) {
  final value = _goalDouble(rawGoal);
  return value?.round();
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }

  return value.toStringAsFixed(1);
}

String _formatInt(int value) {
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
