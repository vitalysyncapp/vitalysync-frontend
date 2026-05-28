import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/notifications/notification_feed_cache.dart';
import '../../../shared/offline/offline_cache_store.dart';
import '../../dashboard/data/burnout_score_api.dart';
import '../../exercise/data/exercise_goal_model.dart';
import '../../exercise/data/exercise_goal_service.dart';

part 'log_local_cache_helpers.dart';

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
  static const List<String> workloadHoursBandOptions = [
    'None',
    '1-2 hours',
    '3-4 hours',
    '5-6 hours',
    '6-7 hours',
    '8-9 hours',
    '10-12 hours',
  ];

  static const String _legacyLocalLogsKey = 'demo_local_logs';
  static const String _legacyLocalWeeklyPulseKeyPrefix = 'local_weekly_pulse';
  static const String _pendingLogsKeyPrefix = 'offline_pending_logs';
  static const String _cachedLogsKeyPrefix = 'cached_daily_logs';
  static const String _syncedStreakKeyPrefix = 'synced_log_streak';
  static const String _energyScaleMigrationKeyPrefix =
      'daily_log_energy_scale_v2_migrated';
  static const String _hydrationPrefillKeyPrefix =
      'assistant_hydration_prefill';
  static const String _exercisePrefillKeyPrefix = 'assistant_exercise_prefill';
  static const String _weeklyPulseStatusCache = 'weekly_pulse_status';
  static const String _weeklyPulsePendingCache = 'weekly_pulse_pending';
  static const Duration _requestTimeout = Duration(seconds: 8);

  static const List<String> exerciseOptions = [
    'Walking',
    'Jogging',
    'Running',
    'Bodyweight',
    'Stretching',
    'Breathing',
    'Yoga',
    'Gym',
    'Cycling',
    'Swimming',
    'None',
  ];

  static String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static String weekStartKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    final normalized = DateTime(value.year, value.month, value.day);
    final weekStart = normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
    final month = weekStart.month.toString().padLeft(2, '0');
    final day = weekStart.day.toString().padLeft(2, '0');
    return '${weekStart.year}-$month-$day';
  }

  static Future<int?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<void> _trySyncPendingLogs() async {
    try {
      await syncPendingLogs();
    } catch (_) {
      // A stuck pending offline log should not block live read requests.
    }
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

  static String? normalizeWorkloadHoursBand(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return workloadHoursBandOptions.contains(normalized) ? normalized : null;
  }

  static String normalizeExerciseNameForLog(String value) {
    final normalized = value.trim();
    final lower = normalized.toLowerCase();

    if (normalized.isEmpty || lower.contains('none')) {
      return 'None';
    }
    if (lower.contains('walk')) {
      return 'Walking';
    }
    if (lower.contains('jog')) {
      return 'Jogging';
    }
    if (lower.contains('run')) {
      return 'Running';
    }
    if (lower.contains('bodyweight') || lower.contains('circuit')) {
      return 'Bodyweight';
    }
    if (lower.contains('stretch')) {
      return 'Stretching';
    }
    if (lower.contains('breath')) {
      return 'Breathing';
    }
    if (lower.contains('yoga')) {
      return 'Yoga';
    }
    if (lower.contains('gym') || lower.contains('strength')) {
      return 'Gym';
    }
    if (lower.contains('cycl')) {
      return 'Cycling';
    }
    if (lower.contains('swim')) {
      return 'Swimming';
    }

    return exerciseOptions.contains(normalized) ? normalized : normalized;
  }

  static int? parseLikert(dynamic value) {
    final parsed = parseInt(value, fallback: 0);
    return parsed >= 1 && parsed <= 5 ? parsed : null;
  }

  static int? parseEnergyLevel(dynamic value) {
    return parseLikert(value);
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
    final userId = await getStoredUserId();
    if (userId == null) {
      return null;
    }

    try {
      await _trySyncPendingLogs();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.logs('/streak')}?user_id=$userId'),
            headers: await ApiConfig.jsonHeaders(),
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
    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    try {
      await _trySyncPendingLogs();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.logs('/today')}?user_id=$userId&log_date=${todayKey()}',
            ),
            headers: await ApiConfig.jsonHeaders(),
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
    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    try {
      await _trySyncPendingLogs();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.logs('/latest')}?user_id=$userId'),
            headers: await ApiConfig.jsonHeaders(),
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

  static Future<List<Map<String, dynamic>>> fetchHistory({
    required String startDate,
    required String endDate,
    int limit = 30,
  }) async {
    final userId = await getStoredUserId();
    if (userId == null) {
      return const [];
    }

    try {
      await _trySyncPendingLogs();

      final uri = Uri.parse(ApiConfig.logs('/history')).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'start': startDate,
          'end': endDate,
          'limit': limit.toString(),
        },
      );
      final response = await http
          .get(uri, headers: await ApiConfig.jsonHeaders())
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        throw _LogApiException(
          data['message']?.toString() ?? 'Failed to fetch log history',
          response.statusCode,
        );
      }

      final logs =
          (data['logs'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => _normalizeLog(Map<String, dynamic>.from(item)))
              .toList()
            ..sort(_compareLogsByDate);

      for (final log in logs) {
        await _upsertCachedLog(userId, log);
      }

      return logs;
    } on _LogApiException catch (error) {
      if (!error.canUseOfflineFallback) {
        rethrow;
      }

      final logs = await _readMergedUserLogs(userId);
      return _filterLogsByDate(
        logs,
        startDate: startDate,
        endDate: endDate,
      ).take(limit).toList();
    } catch (_) {
      final logs = await _readMergedUserLogs(userId);
      return _filterLogsByDate(
        logs,
        startDate: startDate,
        endDate: endDate,
      ).take(limit).toList();
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
    required String workloadHoursBand,
    required int perceivedStressLevel,
    int? breakQualityLevel,
    required List<String> exerciseNames,
    required List<String> symptomNames,
    required List<String> habitNames,
  }) async {
    final exerciseGoalMetadata = await ExerciseGoalService.instance
        .goalMetadataForDailyLog();

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
      'workload_hours_band': workloadHoursBand,
      'perceived_stress_level': perceivedStressLevel,
      'break_quality_level': breakQualityLevel,
      'exercise_names': exerciseNames,
      'symptom_names': symptomNames,
      'habit_names': habitNames,
      ...exerciseGoalMetadata,
    });

    return _savePreparedDailyLog(userId, log);
  }

  static Future<Map<String, dynamic>> _savePreparedDailyLog(
    int userId,
    Map<String, dynamic> log,
  ) async {
    try {
      await syncPendingLogs();
    } catch (_) {
      // A failed background sync should not block today's offline save.
    }

    try {
      final data = await _postDailyLog(userId, log);
      final savedLog = data['log'] as Map<String, dynamic>?;
      await _upsertCachedLog(userId, savedLog ?? log);
      await _clearHydrationPrefillForUser(userId);
      await _clearExercisePrefillForUser(userId);
      await _refreshBurnoutCacheAfterInputChange(data);

      final streak = data['streak'] as Map<String, dynamic>?;
      await _persistSyncedStreakSnapshot(userId, streak);
      data['streak'] = await _refreshOptimisticStreak(
        userId,
        baseStreak: streak,
      );
      data['is_offline'] = false;
      data['pending_sync_count'] = await pendingLogCount();
      await invalidateNotificationFeedCache();

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

  static Future<Map<String, dynamic>> quickAddHydration({
    required double amountLiters,
  }) async {
    final amount = amountLiters.clamp(0.0, 10.0).toDouble();
    if (amount <= 0) {
      throw Exception('Hydration amount must be greater than 0.');
    }

    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final data = await fetchTodayLog();
    final rawLog = data['log'];
    if (data['has_log'] == true && rawLog is Map) {
      final log = Map<String, dynamic>.from(rawLog);
      final updatedHydration = (parseDouble(log['hydration_liters']) + amount)
          .clamp(0.0, 10.0)
          .toDouble();
      final saved = await _savePreparedDailyLog(
        userId,
        _normalizeLog({...log, 'hydration_liters': updatedHydration}),
      );

      return {
        ...saved,
        'quick_hydration_saved': true,
        'hydration_liters': updatedHydration,
      };
    }

    final queuedTotal = await queueHydrationPrefill(amount);
    return {
      'has_log': false,
      'quick_hydration_saved': false,
      'queued_hydration_liters': queuedTotal,
    };
  }

  static Future<double> queueHydrationPrefill(double amountLiters) async {
    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final current = await _readHydrationPrefillForUser(userId);
    final total = (current + amountLiters).clamp(0.0, 10.0).toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_hydrationPrefillKey(userId), total);
    return total;
  }

  static Future<double> readHydrationPrefill() async {
    final userId = await getStoredUserId();
    if (userId == null) {
      return 0;
    }

    return _readHydrationPrefillForUser(userId);
  }

  static Future<void> clearHydrationPrefill() async {
    final userId = await getStoredUserId();
    if (userId == null) {
      return;
    }

    await _clearHydrationPrefillForUser(userId);
  }

  static Future<Map<String, dynamic>> applyExerciseGoalSelection(
    ExerciseGoalModel goal,
  ) async {
    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final exerciseName = normalizeExerciseNameForLog(goal.exerciseName);
    final goalMetadata = goal.toDailyLogMetadata();
    final data = await fetchTodayLog();
    final rawLog = data['log'];

    if (data['has_log'] == true && rawLog is Map) {
      final updatedLog = _normalizeLog({
        ...Map<String, dynamic>.from(rawLog),
        'exercise_names': [exerciseName],
        ...goalMetadata,
      });
      final saved = await _savePreparedDailyLog(userId, updatedLog);
      return {
        ...saved,
        'exercise_applied_to_log': true,
        'exercise_name': exerciseName,
      };
    }

    await queueExercisePrefill(goal);
    return {
      'has_log': false,
      'exercise_applied_to_log': false,
      'exercise_name': exerciseName,
    };
  }

  static Future<void> queueExercisePrefill(ExerciseGoalModel goal) async {
    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _exercisePrefillKey(userId),
      jsonEncode({
        'date': todayKey(),
        'exercise_name': normalizeExerciseNameForLog(goal.exerciseName),
        'goal': goal.toJson(),
      }),
    );
  }

  static Future<String?> readExercisePrefill() async {
    final userId = await getStoredUserId();
    if (userId == null) {
      return null;
    }

    final data = await _readExercisePrefillForUser(userId);
    return data?['exercise_name']?.toString();
  }

  static Future<void> clearExercisePrefill() async {
    final userId = await getStoredUserId();
    if (userId == null) {
      return;
    }

    await _clearExercisePrefillForUser(userId);
  }

  static Future<Map<String, dynamic>> fetchWeeklyPulseStatus() async {
    final weekStart = weekStartKey();

    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    try {
      await _syncCachedWeeklyPulse(userId, weekStart);
    } catch (_) {
      // A pending weekly pulse should not block reading the cached status.
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.logs('/weekly-pulse/status')}?user_id=$userId&date=${todayKey()}',
            ),
            headers: await ApiConfig.jsonHeaders(),
          )
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        final error = _LogApiException(
          data['message']?.toString() ?? 'Failed to fetch weekly pulse',
          response.statusCode,
        );

        if (!error.canUseOfflineFallback) {
          throw error;
        }

        return await _readCachedWeeklyPulseStatus(userId, weekStart) ??
            (throw error);
      }

      await _cacheWeeklyPulseStatus(userId, weekStart, data);
      return data;
    } on _LogApiException catch (error) {
      if (!error.canUseOfflineFallback) {
        throw Exception(error.message);
      }

      final cached = await _readCachedWeeklyPulseStatus(userId, weekStart);
      if (cached != null) {
        return cached;
      }

      throw Exception(error.message);
    } catch (_) {
      final cached = await _readCachedWeeklyPulseStatus(userId, weekStart);
      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _postWeeklyPulse(
    int userId,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.logs('/weekly-pulse')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({'user_id': userId, ...body}),
        )
        .timeout(_requestTimeout);

    final data = _decodeResponseMap(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _LogApiException(
        data['message']?.toString() ?? 'Failed to save weekly pulse',
        response.statusCode,
      );
    }

    return data;
  }

  static Future<Map<String, dynamic>> saveWeeklyPulse({
    required int productivityFocusLevel,
    required int recoveryRestLevel,
    required int detachmentLevel,
    required int accomplishmentLevel,
  }) async {
    if (parseLikert(productivityFocusLevel) == null ||
        parseLikert(recoveryRestLevel) == null ||
        parseLikert(detachmentLevel) == null ||
        parseLikert(accomplishmentLevel) == null) {
      throw Exception('Weekly pulse answers must be from 1 to 5');
    }

    final weekStart = weekStartKey();

    final userId = await getStoredUserId();
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final body = {
      'response_date': todayKey(),
      'productivity_focus_level': productivityFocusLevel,
      'recovery_rest_level': recoveryRestLevel,
      'detachment_level': detachmentLevel,
      'accomplishment_level': accomplishmentLevel,
    };

    try {
      final data = await _postWeeklyPulse(userId, body);
      await BurnoutScoreApi.markInputsChanged(clearLatestScore: true);
      await _cacheWeeklyPulseStatus(
        userId,
        weekStart,
        _weeklyPulseStatusFromSave(
          data,
          userId: userId,
          weekStart: weekStart,
          body: body,
          isOffline: false,
        ),
      );
      await invalidateNotificationFeedCache();
      return data;
    } on _LogApiException catch (error) {
      if (!error.canQueueForLater) {
        throw Exception(error.message);
      }

      return _saveOfflineWeeklyPulse(
        userId: userId,
        weekStart: weekStart,
        body: body,
      );
    } catch (_) {
      return _saveOfflineWeeklyPulse(
        userId: userId,
        weekStart: weekStart,
        body: body,
      );
    }
  }

  static Future<void> clearLocalAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    final logKeys = prefs.getKeys().where(
      (key) =>
          key == _legacyLocalLogsKey ||
          key.startsWith(_legacyLocalWeeklyPulseKeyPrefix) ||
          key.startsWith(_pendingLogsKeyPrefix) ||
          key.startsWith(_cachedLogsKeyPrefix) ||
          key.startsWith(_energyScaleMigrationKeyPrefix) ||
          key.startsWith(_hydrationPrefillKeyPrefix) ||
          key.startsWith(_exercisePrefillKeyPrefix) ||
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
    final userId = await getStoredUserId();
    if (userId == null) {
      return 0;
    }

    final pendingLogs = await _readPendingLogs(userId);
    return pendingLogs.length;
  }

  static Future<int> syncPendingLogs() async {
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
      await _refreshBurnoutCacheAfterInputChange(data);
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
    if (syncedCount > 0) {
      await invalidateNotificationFeedCache();
    }
    return syncedCount;
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
