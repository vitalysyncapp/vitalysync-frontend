import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/preferences/user_session.dart';
import 'nutrition_api.dart';

class NutritionMealSuggestionStore {
  NutritionMealSuggestionStore._();

  static const int _maxSuggestions = 30;
  static const String _keyPrefix = 'nutrition_manual_meal_suggestions';

  static Future<List<String>> loadMealNames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _cacheKey());
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<String>> saveManualMeals(
    List<ManualNutritionInput> meals,
  ) {
    return saveMealNames(meals.map((meal) => meal.mealName));
  }

  static Future<List<String>> saveMealNames(Iterable<String> names) async {
    final normalizedNames = names
        .map((name) => _normalizedMealName(name))
        .where((name) => name.isNotEmpty)
        .toList();
    if (normalizedNames.isEmpty) {
      return loadMealNames();
    }

    final existing = await loadMealNames();
    final merged = <String>[];

    for (final name in [...normalizedNames.reversed, ...existing]) {
      final alreadySaved = merged.any(
        (item) => item.toLowerCase() == name.toLowerCase(),
      );
      if (!alreadySaved) {
        merged.add(name);
      }
      if (merged.length >= _maxSuggestions) {
        break;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _cacheKey(), jsonEncode(merged));
    return merged;
  }

  static String _normalizedMealName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static Future<String> _cacheKey() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      return _keyPrefix;
    }
    return '${_keyPrefix}_$userId';
  }
}
