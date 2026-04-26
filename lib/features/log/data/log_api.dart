import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/preferences/user_session.dart';
import '../../exercise/data/exercise_goal_service.dart';

class HydrationStatus {
  final String level;
  final String shortLabel;
  final int colorValue;

  const HydrationStatus({
    required this.level,
    required this.shortLabel,
    required this.colorValue,
  });
}

class LogApi {
  static const String _localLogsKey = 'demo_local_logs';
  static const String _pendingLogsKeyPrefix = 'offline_pending_logs';
  static const String _cachedLogsKeyPrefix = 'cached_daily_logs';
  static const String _syncedStreakKeyPrefix = 'synced_log_streak';
  static const Duration _requestTimeout = Duration(seconds: 8);

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

  static Future<void> persistStreakSnapshot(
    Map<String, dynamic>? streak,
  ) async {
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

  static Future<void> persistServerStreakSnapshot(
    Map<String, dynamic>? streak,
  ) async {
    await persistStreakSnapshot(streak);

    final userId = await getStoredUserId();
    if (userId != null) {
      await _persistSyncedStreakSnapshot(userId, streak);
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

    try {
      await syncPendingLogs();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.logs('/streak')}?user_id=$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        throw _LogApiException(
          data['message']?.toString() ?? 'Failed to sync streak',
          response.statusCode,
        );
      }

      final streak = data['streak'] as Map<String, dynamic>?;
      await _persistSyncedStreakSnapshot(userId, streak);
      return _refreshOptimisticStreak(userId, baseStreak: streak);
    } on _LogApiException catch (error) {
      if (!error.canUseOfflineFallback) {
        rethrow;
      }

      final fallback = await _buildOfflineUserLogResponse(userId);
      return fallback['streak'] as Map<String, dynamic>?;
    } catch (_) {
      final fallback = await _buildOfflineUserLogResponse(userId);
      return fallback['streak'] as Map<String, dynamic>?;
    }
  }

  static Future<Map<String, dynamic>> fetchTodayLog() async {
    if (await isDemoMode()) {
      return _buildLocalLogResponse(forToday: true);
    }

    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    try {
      await syncPendingLogs();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.logs('/today')}?user_id=$userId&log_date=${todayKey()}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        throw _LogApiException(
          data['message']?.toString() ?? 'Failed to fetch today log',
          response.statusCode,
        );
      }

      final log = data['log'] as Map<String, dynamic>?;
      if (log != null) {
        await _upsertCachedLog(userId, log);
      }

      final streak = data['streak'] as Map<String, dynamic>?;
      await _persistSyncedStreakSnapshot(userId, streak);
      data['streak'] = await _refreshOptimisticStreak(
        userId,
        baseStreak: streak,
      );
      data['is_offline'] = false;
      data['pending_sync_count'] = await pendingLogCount();

      return data;
    } on _LogApiException catch (error) {
      if (!error.canUseOfflineFallback) {
        throw Exception(error.message);
      }

      return _buildOfflineUserLogResponse(userId, forToday: true);
    } catch (_) {
      return _buildOfflineUserLogResponse(userId, forToday: true);
    }
  }

  static Future<Map<String, dynamic>> fetchLatestLog() async {
    if (await isDemoMode()) {
      return _buildLocalLogResponse();
    }

    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    try {
      await syncPendingLogs();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.logs('/latest')}?user_id=$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        throw _LogApiException(
          data['message']?.toString() ?? 'Failed to fetch latest log',
          response.statusCode,
        );
      }

      final log = data['log'] as Map<String, dynamic>?;
      if (log != null) {
        await _upsertCachedLog(userId, log);
      }

      final streak = data['streak'] as Map<String, dynamic>?;
      await _persistSyncedStreakSnapshot(userId, streak);
      data['streak'] = await _refreshOptimisticStreak(
        userId,
        baseStreak: streak,
      );
      data['is_offline'] = false;
      data['pending_sync_count'] = await pendingLogCount();

      return data;
    } on _LogApiException catch (error) {
      if (!error.canUseOfflineFallback) {
        throw Exception(error.message);
      }

      return _buildOfflineUserLogResponse(userId);
    } catch (_) {
      return _buildOfflineUserLogResponse(userId);
    }
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

  static HydrationStatus getHydrationStatus(
    dynamic value, {
    bool dangerousByRate = false,
  }) {
    final liters = parseDouble(value);

    if (dangerousByRate || liters >= 7) {
      return const HydrationStatus(
        level: 'Dangerous Level',
        shortLabel: 'Danger',
        colorValue: 0xFFDC2626,
      );
    }

    if (liters >= 5) {
      return const HydrationStatus(
        level: 'Overhydration Risk',
        shortLabel: 'Overhydration Risk',
        colorValue: 0xFFF97316,
      );
    }

    if (liters >= 3.5) {
      return const HydrationStatus(
        level: 'High Intake Warning',
        shortLabel: 'High Intake',
        colorValue: 0xFFEAB308,
      );
    }

    return const HydrationStatus(
      level: 'Normal Zone',
      shortLabel: 'Normal',
      colorValue: 0xFF16A34A,
    );
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
    final exerciseGoalMetadata = await ExerciseGoalService.instance
        .goalMetadataForDailyLog();

    if (await isDemoMode()) {
      return _saveLocalDemoLog(
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
        moodIndex: moodIndex,
        energyLevel: energyLevel,
        hydrationLiters: hydrationLiters,
        exerciseNames: exerciseNames,
        symptomNames: symptomNames,
        exerciseGoalMetadata: exerciseGoalMetadata,
      );
    }

    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final log = _normalizeLog({
      'log_date': todayKey(),
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'mood_index': moodIndex,
      'energy_level': energyLevel,
      'hydration_liters': hydrationLiters,
      'exercise_names': exerciseNames,
      'symptom_names': symptomNames,
      ...exerciseGoalMetadata,
    });

    try {
      await syncPendingLogs();
    } catch (_) {
      // A failed background sync should not block today's offline save.
    }

    try {
      final data = await _postDailyLog(userId, log);
      final savedLog = data['log'] as Map<String, dynamic>?;
      await _upsertCachedLog(userId, savedLog ?? log);

      final streak = data['streak'] as Map<String, dynamic>?;
      await _persistSyncedStreakSnapshot(userId, streak);
      data['streak'] = await _refreshOptimisticStreak(
        userId,
        baseStreak: streak,
      );
      data['is_offline'] = false;
      data['pending_sync_count'] = await pendingLogCount();

      return data;
    } on _LogApiException catch (error) {
      if (!error.canQueueForLater) {
        throw Exception(error.message);
      }

      return _saveOfflineLog(userId, log);
    } catch (_) {
      return _saveOfflineLog(userId, log);
    }
  }

  static Future<void> clearLocalDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    final logKeys = prefs.getKeys().where(
      (key) =>
          key == _localLogsKey ||
          key.startsWith(_pendingLogsKeyPrefix) ||
          key.startsWith(_cachedLogsKeyPrefix) ||
          key.startsWith(_syncedStreakKeyPrefix),
    );

    for (final key in logKeys.toList()) {
      await prefs.remove(key);
    }

    await prefs.remove('log_streak');
    await prefs.remove('longest_log_streak');
    await prefs.remove('last_log_date');
  }

  static Future<int> pendingLogCount() async {
    if (await isDemoMode()) {
      return 0;
    }

    final userId = await getStoredUserId();
    if (userId == null) {
      return 0;
    }

    final pendingLogs = await _readPendingLogs(userId);
    return pendingLogs.length;
  }

  static Future<int> syncPendingLogs() async {
    if (await isDemoMode()) {
      return 0;
    }

    final userId = await getStoredUserId();
    if (userId == null) {
      return 0;
    }

    final pendingLogs = await _readPendingLogs(userId);
    if (pendingLogs.isEmpty) {
      await _refreshOptimisticStreak(userId);
      return 0;
    }

    final sortedLogs = [...pendingLogs]..sort(_compareLogsByDate);
    final remainingLogs = [...pendingLogs];
    var syncedCount = 0;

    for (final log in sortedLogs) {
      final data = await _postDailyLog(userId, log);
      final savedLog = data['log'] as Map<String, dynamic>?;

      await _upsertCachedLog(userId, savedLog ?? log);
      await _persistSyncedStreakSnapshot(
        userId,
        data['streak'] as Map<String, dynamic>?,
      );

      remainingLogs.removeWhere(
        (item) => normalizeDateString(item['log_date']) == log['log_date'],
      );
      await _writePendingLogs(userId, remainingLogs);
      syncedCount++;
    }

    await _refreshOptimisticStreak(userId);
    return syncedCount;
  }

  static Future<Map<String, dynamic>> _saveLocalDemoLog({
    required double sleepHours,
    required int sleepQuality,
    required int moodIndex,
    required int energyLevel,
    required double hydrationLiters,
    required List<String> exerciseNames,
    required List<String> symptomNames,
    required Map<String, dynamic> exerciseGoalMetadata,
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
      ...exerciseGoalMetadata,
    };

    final existingIndex = logs.indexWhere(
      (item) => item['log_date'] == logDate,
    );
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

    return {'has_log': log != null, 'log': log, 'streak': streak};
  }

  static Future<Map<String, dynamic>> _buildOfflineUserLogResponse(
    int userId, {
    bool forToday = false,
  }) async {
    final logs = await _readMergedUserLogs(userId);
    final streak = await _refreshOptimisticStreak(userId);
    final pendingCount = (await _readPendingLogs(userId)).length;

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
      'is_offline': true,
      'pending_sync_count': pendingCount,
    };
  }

  static Future<Map<String, dynamic>> _saveOfflineLog(
    int userId,
    Map<String, dynamic> log,
  ) async {
    await _ensureSyncedStreakSnapshot(userId);

    final pendingLogs = await _readPendingLogs(userId);
    final localLog = _normalizeLog({
      ...log,
      'pending_since': DateTime.now().toIso8601String(),
    });

    _upsertLogByDate(pendingLogs, localLog);
    await _writePendingLogs(userId, pendingLogs);
    await _upsertCachedLog(userId, localLog);

    final streak = await _refreshOptimisticStreak(userId);

    return {
      'message': 'Daily log saved locally and will sync when online',
      'has_log': true,
      'log': localLog,
      'streak': streak,
      'is_offline': true,
      'pending_sync_count': pendingLogs.length,
    };
  }

  static Future<Map<String, dynamic>> _postDailyLog(
    int userId,
    Map<String, dynamic> log,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.logs('')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_buildLogRequestBody(userId, log)),
        )
        .timeout(_requestTimeout);

    final data = _decodeResponseMap(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _LogApiException(
        data['message']?.toString() ?? 'Failed to save daily log',
        response.statusCode,
      );
    }

    return data;
  }

  static Map<String, dynamic> _buildLogRequestBody(
    int userId,
    Map<String, dynamic> log,
  ) {
    return {
      'user_id': userId,
      'log_date': normalizeDateString(log['log_date']) ?? todayKey(),
      'sleep_hours': parseDouble(log['sleep_hours']),
      'sleep_quality': parseInt(log['sleep_quality']),
      'mood_index': parseInt(log['mood_index']),
      'energy_level': parseInt(log['energy_level']),
      'hydration_liters': parseDouble(log['hydration_liters']),
      'exercise_names': _stringList(log['exercise_names']),
      'symptom_names': _stringList(log['symptom_names']),
      'exercise_goal_name': _nullableString(log['exercise_goal_name']),
      'exercise_goal_completed': _nullableBool(log['exercise_goal_completed']),
      'exercise_goal_source': _nullableString(log['exercise_goal_source']),
      'exercise_goal_status': _nullableString(log['exercise_goal_status']),
    };
  }

  static Map<String, dynamic> _decodeResponseMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Fall through to a readable fallback message.
    }

    return {'message': response.reasonPhrase ?? 'Unexpected server response'};
  }

  static Future<void> _upsertCachedLog(
    int userId,
    Map<String, dynamic> log,
  ) async {
    final logs = await _readCachedLogs(userId);
    _upsertLogByDate(logs, _normalizeLog(log));
    await _writeCachedLogs(userId, logs);
  }

  static Future<List<Map<String, dynamic>>> _readMergedUserLogs(
    int userId,
  ) async {
    final cachedLogs = await _readCachedLogs(userId);
    final pendingLogs = await _readPendingLogs(userId);
    final logs = [...cachedLogs];

    for (final pendingLog in pendingLogs) {
      _upsertLogByDate(logs, pendingLog);
    }

    logs.sort(_compareLogsByDate);
    return logs;
  }

  static Future<List<Map<String, dynamic>>> _readPendingLogs(int userId) {
    return _readLogList(_pendingLogsKey(userId));
  }

  static Future<void> _writePendingLogs(
    int userId,
    List<Map<String, dynamic>> logs,
  ) {
    return _writeLogList(_pendingLogsKey(userId), logs);
  }

  static Future<List<Map<String, dynamic>>> _readCachedLogs(int userId) {
    return _readLogList(_cachedLogsKey(userId));
  }

  static Future<void> _writeCachedLogs(
    int userId,
    List<Map<String, dynamic>> logs,
  ) {
    return _writeLogList(_cachedLogsKey(userId), logs);
  }

  static Future<List<Map<String, dynamic>>> _readLogList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => _normalizeLog(Map<String, dynamic>.from(item)))
          .toList()
        ..sort(_compareLogsByDate);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeLogList(
    String key,
    List<Map<String, dynamic>> logs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedLogs = logs.map(_normalizeLog).toList()
      ..sort(_compareLogsByDate);
    await prefs.setString(key, jsonEncode(normalizedLogs));
  }

  static Future<Map<String, dynamic>> _refreshOptimisticStreak(
    int userId, {
    Map<String, dynamic>? baseStreak,
  }) async {
    final pendingLogs = await _readPendingLogs(userId);
    final base = _normalizeStreak(
      baseStreak ??
          await _readSyncedStreakSnapshot(userId) ??
          await _readPrefsStreakSnapshot(),
    );

    final streak = pendingLogs.isEmpty
        ? base
        : _applyPendingLogsToStreak(base, pendingLogs);

    await persistStreakSnapshot(streak);
    return streak;
  }

  static Future<void> _ensureSyncedStreakSnapshot(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _syncedStreakKey(userId);
    if (prefs.getString(key) != null) {
      return;
    }

    final snapshot = await _readPrefsStreakSnapshot();
    await prefs.setString(key, jsonEncode(snapshot));
  }

  static Future<void> _persistSyncedStreakSnapshot(
    int userId,
    Map<String, dynamic>? streak,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _syncedStreakKey(userId),
      jsonEncode(_normalizeStreak(streak)),
    );
  }

  static Future<Map<String, dynamic>?> _readSyncedStreakSnapshot(
    int userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_syncedStreakKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _normalizeStreak(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Future<Map<String, dynamic>> _readPrefsStreakSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'current_streak': prefs.getInt('log_streak') ?? 0,
      'longest_streak': prefs.getInt('longest_log_streak') ?? 0,
      'last_logged_date': normalizeDateString(prefs.getString('last_log_date')),
    };
  }

  static Map<String, dynamic> _normalizeStreak(Map<String, dynamic>? streak) {
    return {
      'current_streak': parseInt(streak?['current_streak']),
      'longest_streak': parseInt(streak?['longest_streak']),
      'last_logged_date': normalizeDateString(streak?['last_logged_date']),
    };
  }

  static Map<String, dynamic> _applyPendingLogsToStreak(
    Map<String, dynamic> baseStreak,
    List<Map<String, dynamic>> pendingLogs,
  ) {
    final logs = [...pendingLogs]..sort(_compareLogsByDate);
    var currentStreak = parseInt(baseStreak['current_streak']);
    var longestStreak = parseInt(baseStreak['longest_streak']);
    var lastLoggedDate = _parseDateOnly(baseStreak['last_logged_date']);

    for (final log in logs) {
      final logDate = _parseDateOnly(log['log_date']);
      if (logDate == null) {
        continue;
      }

      if (lastLoggedDate == null) {
        currentStreak = 1;
        lastLoggedDate = logDate;
      } else {
        final dayDifference = logDate.difference(lastLoggedDate).inDays;

        if (dayDifference == 0) {
          // Updating an already-counted day should keep the streak unchanged.
        } else if (dayDifference == 1) {
          currentStreak++;
          lastLoggedDate = logDate;
        } else if (dayDifference > 1) {
          currentStreak = 1;
          lastLoggedDate = logDate;
        }
      }

      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }

    if (lastLoggedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (today.difference(lastLoggedDate).inDays > 1) {
        currentStreak = 0;
      }
    }

    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_logged_date': lastLoggedDate == null
          ? null
          : _formatDateOnly(lastLoggedDate),
    };
  }

  static Map<String, dynamic> _normalizeLog(Map<String, dynamic> log) {
    final normalized = Map<String, dynamic>.from(log);
    normalized['log_date'] = normalizeDateString(log['log_date']) ?? todayKey();
    normalized['sleep_hours'] = parseDouble(log['sleep_hours']);
    normalized['sleep_quality'] = parseInt(log['sleep_quality']);
    normalized['mood_index'] = parseInt(log['mood_index']);
    normalized['energy_level'] = parseInt(log['energy_level']);
    normalized['hydration_liters'] = parseDouble(log['hydration_liters']);
    normalized['exercise_names'] = _stringList(log['exercise_names']);
    normalized['symptom_names'] = _stringList(log['symptom_names']);
    normalized['exercise_goal_name'] = _nullableString(
      log['exercise_goal_name'],
    );
    normalized['exercise_goal_completed'] = _nullableBool(
      log['exercise_goal_completed'],
    );
    normalized['exercise_goal_source'] = _nullableString(
      log['exercise_goal_source'],
    );
    normalized['exercise_goal_status'] = _nullableString(
      log['exercise_goal_status'],
    );
    return normalized;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  static String? _nullableString(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static bool? _nullableBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }

    return null;
  }

  static void _upsertLogByDate(
    List<Map<String, dynamic>> logs,
    Map<String, dynamic> log,
  ) {
    final normalizedLog = _normalizeLog(log);
    final logDate = normalizedLog['log_date'];
    final existingIndex = logs.indexWhere(
      (item) => normalizeDateString(item['log_date']) == logDate,
    );

    if (existingIndex >= 0) {
      logs[existingIndex] = normalizedLog;
    } else {
      logs.add(normalizedLog);
    }

    logs.sort(_compareLogsByDate);
  }

  static int _compareLogsByDate(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final first = normalizeDateString(a['log_date']) ?? '';
    final second = normalizeDateString(b['log_date']) ?? '';
    return first.compareTo(second);
  }

  static DateTime? _parseDateOnly(dynamic value) {
    final normalized = normalizeDateString(value);
    if (normalized == null) {
      return null;
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      return null;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _formatDateOnly(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String _pendingLogsKey(int userId) {
    return '${_pendingLogsKeyPrefix}_$userId';
  }

  static String _cachedLogsKey(int userId) {
    return '${_cachedLogsKeyPrefix}_$userId';
  }

  static String _syncedStreakKey(int userId) {
    return '${_syncedStreakKeyPrefix}_$userId';
  }

  static Future<List<Map<String, dynamic>>> _readLocalLogs() async {
    return _readLogList(_localLogsKey);
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

    final dates =
        logs
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

class _LogApiException implements Exception {
  final String message;
  final int statusCode;

  const _LogApiException(this.message, this.statusCode);

  bool get canQueueForLater => statusCode >= 500;

  bool get canUseOfflineFallback => statusCode >= 500;

  @override
  String toString() => message;
}
