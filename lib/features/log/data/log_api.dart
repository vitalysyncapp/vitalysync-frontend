import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/config/api_config.dart';

class LogApi {
  static String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Future<int?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static int parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static double parseDouble(dynamic value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static String? normalizeDateString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  static Future<void> persistStreakSnapshot(Map<String, dynamic>? streak) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStreak = parseInt(streak?['current_streak']);
    final longestStreak = parseInt(streak?['longest_streak']);
    final lastLoggedDate = normalizeDateString(streak?['last_logged_date']);

    await prefs.setInt('log_streak', currentStreak);
    await prefs.setInt('longest_log_streak', longestStreak);

    if (lastLoggedDate != null && lastLoggedDate.isNotEmpty) {
      await prefs.setString('last_log_date', lastLoggedDate);
    } else {
      await prefs.remove('last_log_date');
    }
  }

  static Future<Map<String, dynamic>?> syncStreakFromBackend() async {
    final userId = await getStoredUserId();
    if (userId == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.logs('/streak')}?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync streak');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final streak = data['streak'] as Map<String, dynamic>?;
    await persistStreakSnapshot(streak);
    return streak;
  }

  static Future<Map<String, dynamic>> fetchTodayLog() async {
    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.logs('/today')}?user_id=$userId&log_date=${todayKey()}',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch today log');
    }

    await persistStreakSnapshot(data['streak'] as Map<String, dynamic>?);
    return data;
  }

  static Future<Map<String, dynamic>> saveDailyLog({
    required double sleepHours,
    required int sleepQuality,
    required int moodIndex,
    required int energyLevel,
    required double hydrationLiters,
    required List<String> exerciseNames,
    required List<String> symptomNames,
  }) async {
    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final response = await http.post(
      Uri.parse(ApiConfig.logs('')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'log_date': todayKey(),
        'sleep_hours': sleepHours,
        'sleep_quality': sleepQuality,
        'mood_index': moodIndex,
        'energy_level': energyLevel,
        'hydration_liters': hydrationLiters,
        'exercise_names': exerciseNames,
        'symptom_names': symptomNames,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to save daily log');
    }

    await persistStreakSnapshot(data['streak'] as Map<String, dynamic>?);
    return data;
  }
}
