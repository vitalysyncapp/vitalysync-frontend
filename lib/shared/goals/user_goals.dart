import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../offline/fetch_policy.dart';
import '../offline/offline_cache_store.dart';

const List<String> kWellnessGoalOptions = [
  'Reduce stress',
  'Improve sleep',
  'Be more active',
  'Improve focus',
  'Build healthier habits',
  'Manage burnout',
];

class UserGoalsSnapshot {
  final String wellnessGoal;
  final List<String> wellnessGoals;
  final double sleepHours;
  final double hydrationLiters;
  final int activityDaysPerWeek;
  final int dailySteps;
  final int nutritionCalories;
  final String nutritionCaloriesSource;
  final int? balancedNutritionCalories;

  const UserGoalsSnapshot({
    required this.wellnessGoal,
    required this.wellnessGoals,
    required this.sleepHours,
    required this.hydrationLiters,
    required this.activityDaysPerWeek,
    required this.dailySteps,
    required this.nutritionCalories,
    required this.nutritionCaloriesSource,
    required this.balancedNutritionCalories,
  });

  factory UserGoalsSnapshot.defaults({
    String wellnessGoal = 'Not set',
    List<String>? wellnessGoals,
    double sleepHours = 8,
    double hydrationLiters = 2.5,
    int activityDaysPerWeek = 3,
    int dailySteps = 5000,
    int nutritionCalories = 2000,
    String nutritionCaloriesSource = 'default',
    int? balancedNutritionCalories,
  }) {
    final selectedWellnessGoals = _normalizeWellnessGoals(
      wellnessGoals ?? _wellnessGoalsFromText(wellnessGoal),
    );
    final wellnessGoalText = selectedWellnessGoals.isEmpty
        ? _nonEmpty(wellnessGoal) ?? 'Not set'
        : selectedWellnessGoals.join(', ');

    return UserGoalsSnapshot(
      wellnessGoal: wellnessGoalText,
      wellnessGoals: List.unmodifiable(selectedWellnessGoals),
      sleepHours: sleepHours.clamp(1, 24).toDouble(),
      hydrationLiters: hydrationLiters.clamp(0.25, 20).toDouble(),
      activityDaysPerWeek: activityDaysPerWeek.clamp(0, 7).toInt(),
      dailySteps: dailySteps.clamp(1000, 50000).toInt(),
      nutritionCalories: nutritionCalories.clamp(800, 6000).toInt(),
      nutritionCaloriesSource: nutritionCaloriesSource,
      balancedNutritionCalories: balancedNutritionCalories
          ?.clamp(800, 6000)
          .toInt(),
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
    final rawWellnessGoal = rawGoals['wellness'];
    final wellnessGoalText = _goalText(rawWellnessGoal);
    final wellnessGoals = _goalWellnessGoals(rawWellnessGoal);

    return UserGoalsSnapshot.defaults(
      wellnessGoal: wellnessGoalText ?? defaults.wellnessGoal,
      wellnessGoals: wellnessGoals.isEmpty
          ? defaults.wellnessGoals
          : wellnessGoals,
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
      nutritionCaloriesSource:
          _goalSource(rawGoals['nutrition_calories']) ??
          defaults.nutritionCaloriesSource,
      balancedNutritionCalories:
          _goalMetadataInt(rawGoals['nutrition_calories'], 'balanced_kcal') ??
          defaults.balancedNutritionCalories,
    );
  }

  UserGoalsSnapshot copyWith({
    String? wellnessGoal,
    List<String>? wellnessGoals,
    double? sleepHours,
    double? hydrationLiters,
    int? activityDaysPerWeek,
    int? dailySteps,
    int? nutritionCalories,
    String? nutritionCaloriesSource,
    int? balancedNutritionCalories,
  }) {
    return UserGoalsSnapshot.defaults(
      wellnessGoal: wellnessGoal ?? this.wellnessGoal,
      wellnessGoals: wellnessGoals ?? this.wellnessGoals,
      sleepHours: sleepHours ?? this.sleepHours,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      activityDaysPerWeek: activityDaysPerWeek ?? this.activityDaysPerWeek,
      dailySteps: dailySteps ?? this.dailySteps,
      nutritionCalories: nutritionCalories ?? this.nutritionCalories,
      nutritionCaloriesSource:
          nutritionCaloriesSource ?? this.nutritionCaloriesSource,
      balancedNutritionCalories:
          balancedNutritionCalories ?? this.balancedNutritionCalories,
    );
  }

  Map<String, dynamic> toApiGoals({bool includeNutritionCalories = true}) {
    final goals = {
      'wellness': {
        'target_text': wellnessGoal,
        'source': 'profile',
        'metadata': {'selected_goals': wellnessGoals},
      },
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
    };

    if (includeNutritionCalories) {
      goals['nutrition_calories'] = {
        'target_value': nutritionCalories,
        'unit': 'kcal',
        'source': 'profile',
      };
    }

    return goals;
  }

  Map<String, dynamic> toCacheJson() {
    return {'goals': toApiGoals()};
  }

  String get sleepLabel => '${_formatNumber(sleepHours)} hours';

  String get hydrationLabel => '${_formatNumber(hydrationLiters)} L';

  String get activityLabel => '$activityDaysPerWeek days/week';

  String get dailyStepsLabel => '${_formatInt(dailySteps)} steps';

  String get nutritionLabel => '${_formatInt(nutritionCalories)} kcal';

  String? get balancedNutritionLabel {
    final calories = balancedNutritionCalories;
    if (calories == null) {
      return null;
    }

    return '${_formatInt(calories)} kcal';
  }

  bool get nutritionCaloriesIsAutoManaged {
    return nutritionCaloriesSource == 'system_default' ||
        nutritionCaloriesSource == 'default';
  }
}

class UserGoalsService {
  UserGoalsService._();

  static const Duration _requestTimeout = ApiRequestTimeouts.fastRead;
  static const String _cacheNamespace = 'user_goals';
  static final ValueNotifier<int> refreshSignal = ValueNotifier<int>(0);

  static Future<UserGoalsSnapshot> fetch({
    required int userId,
    UserGoalsSnapshot? defaults,
    bool forceRefresh = false,
  }) async {
    if (userId <= 0) {
      return defaults ?? UserGoalsSnapshot.defaults();
    }

    final cachedSnapshot = await OfflineCacheStore.readLatestJsonSnapshot(
      namespace: _cacheNamespace,
      scope: userId.toString(),
    );
    if (!forceRefresh &&
        cachedSnapshot?.isFresh(FetchPolicy.perMinute.maxAge) == true) {
      return UserGoalsSnapshot.fromApi(
        cachedSnapshot!.data,
        fallback: defaults,
      );
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
    bool includeNutritionCalories = true,
  }) {
    return updateGoals(
      userId: userId,
      goals: goals.toApiGoals(
        includeNutritionCalories: includeNutritionCalories,
      ),
    );
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

List<String> _goalWellnessGoals(dynamic rawGoal) {
  if (rawGoal is! Map) {
    return const <String>[];
  }

  final goal = Map<String, dynamic>.from(rawGoal);
  final metadata = goal['metadata'] is Map
      ? Map<String, dynamic>.from(goal['metadata'] as Map)
      : const <String, dynamic>{};
  final rawSelected = metadata['selected_goals'] ?? goal['selected_goals'];

  if (rawSelected is List) {
    return _normalizeWellnessGoals(
      rawSelected.map((value) => value.toString()),
    );
  }

  return _wellnessGoalsFromText(_goalText(goal) ?? '');
}

List<String> _normalizeWellnessGoals(Iterable<String> goals) {
  final selected = <String>[];
  for (final option in kWellnessGoalOptions) {
    if (goals.any(
      (goal) => goal.trim().toLowerCase() == option.toLowerCase(),
    )) {
      selected.add(option);
    }
  }

  return selected;
}

List<String> _wellnessGoalsFromText(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == 'Not set') {
    return const <String>[];
  }

  final parts = normalized
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);
  return _normalizeWellnessGoals(parts);
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

String? _goalSource(dynamic rawGoal) {
  if (rawGoal is! Map) {
    return null;
  }

  final source = rawGoal['source']?.toString().trim() ?? '';
  return source.isEmpty ? null : source;
}

int? _goalMetadataInt(dynamic rawGoal, String key) {
  if (rawGoal is! Map) {
    return null;
  }

  final goal = Map<String, dynamic>.from(rawGoal);
  final rawMetadata = goal['metadata'];
  if (rawMetadata is! Map) {
    return null;
  }

  final metadata = Map<String, dynamic>.from(rawMetadata);
  final value = metadata[key];
  if (value is num) {
    return value.round();
  }

  return int.tryParse('${value ?? ''}');
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
