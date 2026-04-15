import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/preferences/user_session.dart';

class LogApi {
  static const String _localLogsKey = 'demo_local_logs';

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

  static Future<bool> isDemoMode() async {
    final session = await UserSessionController.instance.load();
    return session.isDemoMode;
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
    if (await isDemoMode()) {
      final localResponse = await _buildLocalLogResponse();
      return localResponse['streak'] as Map<String, dynamic>?;
    }

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
    if (await isDemoMode()) {
      return _buildLocalLogResponse(forToday: true);
    }

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

  static Future<Map<String, dynamic>> fetchLatestLog() async {
    if (await isDemoMode()) {
      return _buildLocalLogResponse();
    }

    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.logs('/latest')}?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch latest log');
    }

    await persistStreakSnapshot(data['streak'] as Map<String, dynamic>?);
    return data;
  }

  static String formatSleepHours(dynamic value) {
    final hours = parseDouble(value);

    if (hours == 0) {
      return '--';
    }

    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}h';
    }

    return '${hours.toStringAsFixed(1)}h';
  }

  static String formatHydrationLiters(dynamic value) {
    final liters = parseDouble(value);

    if (liters == 0) {
      return '--';
    }

    final formatted = liters == liters.roundToDouble()
        ? liters.toInt().toString()
        : liters.toStringAsFixed(1);

    return '${formatted}L';
  }

  static String formatLogDateLabel(dynamic value) {
    final normalized = normalizeDateString(value);

    if (normalized == null) {
      return 'No log yet';
    }

    final parsedDate = DateTime.tryParse(normalized);
    if (parsedDate == null) {
      return 'Last logged';
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final logDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final difference = todayDate.difference(logDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    return DateFormat('MMM d').format(logDate);
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
    if (await isDemoMode()) {
      return _saveLocalDemoLog(
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
        moodIndex: moodIndex,
        energyLevel: energyLevel,
        hydrationLiters: hydrationLiters,
        exerciseNames: exerciseNames,
        symptomNames: symptomNames,
      );
    }

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

  static Future<void> clearLocalDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localLogsKey);
    await prefs.remove('log_streak');
    await prefs.remove('longest_log_streak');
    await prefs.remove('last_log_date');
  }

  static Future<Map<String, dynamic>> _saveLocalDemoLog({
    required double sleepHours,
    required int sleepQuality,
    required int moodIndex,
    required int energyLevel,
    required double hydrationLiters,
    required List<String> exerciseNames,
    required List<String> symptomNames,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await _readLocalLogs();
    final logDate = todayKey();

    final newLog = <String, dynamic>{
      'log_date': logDate,
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'mood_index': moodIndex,
      'energy_level': energyLevel,
      'hydration_liters': hydrationLiters,
      'exercise_names': exerciseNames,
      'symptom_names': symptomNames,
    };

    final existingIndex = logs.indexWhere((item) => item['log_date'] == logDate);
    if (existingIndex >= 0) {
      logs[existingIndex] = newLog;
    } else {
      logs.add(newLog);
    }

    logs.sort(
      (a, b) => (a['log_date'] as String).compareTo(b['log_date'] as String),
    );

    await prefs.setString(_localLogsKey, jsonEncode(logs));

    final streak = _computeLocalStreak(logs);
    await persistStreakSnapshot(streak);

    return {
      'message': 'Daily log saved locally',
      'has_log': true,
      'log': newLog,
      'streak': streak,
    };
  }

  static Future<Map<String, dynamic>> _buildLocalLogResponse({
    bool forToday = false,
  }) async {
    final logs = await _readLocalLogs();
    final streak = _computeLocalStreak(logs);
    await persistStreakSnapshot(streak);

    Map<String, dynamic>? log;
    if (forToday) {
      final today = todayKey();
      for (final item in logs) {
        if (item['log_date'] == today) {
          log = item;
        }
      }
    } else if (logs.isNotEmpty) {
      log = logs.last;
    }

    return {
      'has_log': log != null,
      'log': log,
      'streak': streak,
    };
  }

  static Future<List<Map<String, dynamic>>> _readLocalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localLogsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Map<String, dynamic> _computeLocalStreak(
    List<Map<String, dynamic>> logs,
  ) {
    if (logs.isEmpty) {
      return {
        'current_streak': 0,
        'longest_streak': 0,
        'last_logged_date': null,
      };
    }

    final dates = logs
        .map((log) => DateTime.parse(log['log_date'] as String))
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    int longest = 1;
    int currentRun = 1;

    for (var i = 1; i < dates.length; i++) {
      final gap = dates[i].difference(dates[i - 1]).inDays;
      if (gap == 1) {
        currentRun++;
      } else if (gap > 1) {
        currentRun = 1;
      }
      if (currentRun > longest) {
        longest = currentRun;
      }
    }

    int currentStreak = 1;
    for (var i = dates.length - 1; i > 0; i--) {
      final gap = dates[i].difference(dates[i - 1]).inDays;
      if (gap == 1) {
        currentStreak++;
      } else {
        break;
      }
    }

    final lastLoggedDate = dates.last;
    final normalizedToday = DateTime.now();
    final today = DateTime(
      normalizedToday.year,
      normalizedToday.month,
      normalizedToday.day,
    );
    final daysFromToday = today.difference(lastLoggedDate).inDays;

    if (daysFromToday > 1) {
      currentStreak = 0;
    }

    return {
      'current_streak': currentStreak,
      'longest_streak': longest,
      'last_logged_date': DateFormat('yyyy-MM-dd').format(lastLoggedDate),
    };
  }
}
