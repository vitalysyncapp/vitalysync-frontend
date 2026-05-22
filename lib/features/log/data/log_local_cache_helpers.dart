part of 'log_api.dart';

Future<Map<String, dynamic>> _buildOfflineUserLogResponse(
  int userId, {
  bool forToday = false,
}) async {
  final logs = await _readMergedUserLogs(userId);
  final streak = await _refreshOptimisticStreak(userId);
  final pendingCount = (await _readPendingLogs(userId)).length;

  Map<String, dynamic>? log;
  if (forToday) {
    final today = LogApi.todayKey();
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

Future<Map<String, dynamic>> _saveOfflineLog(
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
  await _clearHydrationPrefillForUser(userId);
  await _clearExercisePrefillForUser(userId);

  final streak = await _refreshOptimisticStreak(userId);
  await invalidateNotificationFeedCache();

  return {
    'message': 'Daily log saved locally and will sync when online',
    'has_log': true,
    'log': localLog,
    'streak': streak,
    'is_offline': true,
    'pending_sync_count': pendingLogs.length,
  };
}

Future<Map<String, dynamic>> _postDailyLog(
  int userId,
  Map<String, dynamic> log,
) async {
  final response = await http
      .post(
        Uri.parse(ApiConfig.logs('')),
        headers: await ApiConfig.jsonHeaders(),
        body: jsonEncode(_buildLogRequestBody(userId, log)),
      )
      .timeout(LogApi._requestTimeout);

  final data = _decodeResponseMap(response);

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw _LogApiException(
      data['message']?.toString() ?? 'Failed to save daily log',
      response.statusCode,
    );
  }

  return data;
}

Future<void> _refreshBurnoutCacheAfterInputChange(
  Map<String, dynamic> data,
) async {
  final burnoutScore = data['burnout_score'];
  await BurnoutScoreApi.markInputsChanged(
    latestScore: burnoutScore is Map
        ? Map<String, dynamic>.from(burnoutScore)
        : null,
  );
}

Map<String, dynamic> _buildLogRequestBody(
  int userId,
  Map<String, dynamic> log,
) {
  return {
    'user_id': userId,
    'log_date':
        LogApi.normalizeDateString(log['log_date']) ?? LogApi.todayKey(),
    'sleep_hours': LogApi.parseDouble(log['sleep_hours']),
    'sleep_quality': LogApi.parseInt(log['sleep_quality']),
    'mood_index': LogApi.parseInt(log['mood_index']),
    'energy_level': LogApi.parseInt(log['energy_level']),
    'hydration_liters': LogApi.parseDouble(log['hydration_liters']),
    'workload_hours_band':
        LogApi.normalizeWorkloadHoursBand(log['workload_hours_band']) ?? 'None',
    'perceived_stress_level': LogApi.parseLikert(log['perceived_stress_level']),
    'break_quality_level': LogApi.parseLikert(log['break_quality_level']),
    'exercise_names': _stringList(log['exercise_names']),
    'symptom_names': _stringList(log['symptom_names']),
    'habit_names': _stringList(log['habit_names']),
    'exercise_goal_name': _nullableString(log['exercise_goal_name']),
    'exercise_goal_completed': _nullableBool(log['exercise_goal_completed']),
    'exercise_goal_source': _nullableString(log['exercise_goal_source']),
    'exercise_goal_status': _nullableString(log['exercise_goal_status']),
  };
}

Map<String, dynamic> _decodeResponseMap(http.Response response) {
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

Future<void> _upsertCachedLog(int userId, Map<String, dynamic> log) async {
  final logs = await _readCachedLogs(userId);
  _upsertLogByDate(logs, _normalizeLog(log));
  await _writeCachedLogs(userId, logs);
}

Future<List<Map<String, dynamic>>> _readMergedUserLogs(int userId) async {
  final cachedLogs = await _readCachedLogs(userId);
  final pendingLogs = await _readPendingLogs(userId);
  final logs = [...cachedLogs];

  for (final pendingLog in pendingLogs) {
    _upsertLogByDate(logs, pendingLog);
  }

  logs.sort(_compareLogsByDate);
  return logs;
}

Future<List<Map<String, dynamic>>> _readPendingLogs(int userId) {
  return _readLogList(_pendingLogsKey(userId));
}

Future<void> _writePendingLogs(int userId, List<Map<String, dynamic>> logs) {
  return _writeLogList(_pendingLogsKey(userId), logs);
}

Future<List<Map<String, dynamic>>> _readCachedLogs(int userId) {
  return _readLogList(_cachedLogsKey(userId));
}

Future<void> _writeCachedLogs(int userId, List<Map<String, dynamic>> logs) {
  return _writeLogList(_cachedLogsKey(userId), logs);
}

Future<List<Map<String, dynamic>>> _readLogList(String key) async {
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

Future<void> _writeLogList(String key, List<Map<String, dynamic>> logs) async {
  final prefs = await SharedPreferences.getInstance();
  final normalizedLogs = logs.map(_normalizeLog).toList()
    ..sort(_compareLogsByDate);
  await prefs.setString(key, jsonEncode(normalizedLogs));
}

Future<Map<String, dynamic>> _refreshOptimisticStreak(
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

  await LogApi.persistStreakSnapshot(streak);
  return streak;
}

Future<void> _ensureSyncedStreakSnapshot(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _syncedStreakKey(userId);
  if (prefs.getString(key) != null) {
    return;
  }

  final snapshot = await _readPrefsStreakSnapshot();
  await prefs.setString(key, jsonEncode(snapshot));
}

Future<void> _persistSyncedStreakSnapshot(
  int userId,
  Map<String, dynamic>? streak,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _syncedStreakKey(userId),
    jsonEncode(_normalizeStreak(streak)),
  );
}

Future<Map<String, dynamic>?> _readSyncedStreakSnapshot(int userId) async {
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

Future<Map<String, dynamic>> _readPrefsStreakSnapshot() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'current_streak': prefs.getInt('log_streak') ?? 0,
    'longest_streak': prefs.getInt('longest_log_streak') ?? 0,
    'last_logged_date': LogApi.normalizeDateString(
      prefs.getString('last_log_date'),
    ),
  };
}

Map<String, dynamic> _normalizeStreak(Map<String, dynamic>? streak) {
  return {
    'current_streak': LogApi.parseInt(streak?['current_streak']),
    'longest_streak': LogApi.parseInt(streak?['longest_streak']),
    'last_logged_date': LogApi.normalizeDateString(streak?['last_logged_date']),
  };
}

Map<String, dynamic> _applyPendingLogsToStreak(
  Map<String, dynamic> baseStreak,
  List<Map<String, dynamic>> pendingLogs,
) {
  final logs = [...pendingLogs]..sort(_compareLogsByDate);
  var currentStreak = LogApi.parseInt(baseStreak['current_streak']);
  var longestStreak = LogApi.parseInt(baseStreak['longest_streak']);
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

Map<String, dynamic> _normalizeLog(Map<String, dynamic> log) {
  final normalized = Map<String, dynamic>.from(log);
  normalized['log_date'] =
      LogApi.normalizeDateString(log['log_date']) ?? LogApi.todayKey();
  normalized['sleep_hours'] = LogApi.parseDouble(log['sleep_hours']);
  normalized['sleep_quality'] = LogApi.parseInt(log['sleep_quality']);
  normalized['mood_index'] = LogApi.parseInt(log['mood_index']);
  normalized['energy_level'] = LogApi.parseInt(log['energy_level']);
  normalized['hydration_liters'] = LogApi.parseDouble(log['hydration_liters']);
  normalized['workload_hours_band'] =
      LogApi.normalizeWorkloadHoursBand(log['workload_hours_band']) ?? 'None';
  normalized['perceived_stress_level'] = LogApi.parseLikert(
    log['perceived_stress_level'],
  );
  normalized['break_quality_level'] = LogApi.parseLikert(
    log['break_quality_level'],
  );
  normalized['exercise_names'] = _stringList(log['exercise_names']);
  normalized['symptom_names'] = _stringList(log['symptom_names']);
  normalized['habit_names'] = _stringList(log['habit_names']);
  normalized['exercise_goal_name'] = _nullableString(log['exercise_goal_name']);
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

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return [];
}

List<Map<String, dynamic>> _filterLogsByDate(
  List<Map<String, dynamic>> logs, {
  required String startDate,
  required String endDate,
}) {
  return logs.where((log) {
    final logDate = LogApi.normalizeDateString(log['log_date']);
    if (logDate == null) {
      return false;
    }
    return logDate.compareTo(startDate) >= 0 && logDate.compareTo(endDate) <= 0;
  }).toList()..sort(_compareLogsByDate);
}

String? _nullableString(dynamic value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

bool? _nullableBool(dynamic value) {
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

void _upsertLogByDate(
  List<Map<String, dynamic>> logs,
  Map<String, dynamic> log,
) {
  final normalizedLog = _normalizeLog(log);
  final logDate = normalizedLog['log_date'];
  final existingIndex = logs.indexWhere(
    (item) => LogApi.normalizeDateString(item['log_date']) == logDate,
  );

  if (existingIndex >= 0) {
    logs[existingIndex] = normalizedLog;
  } else {
    logs.add(normalizedLog);
  }

  logs.sort(_compareLogsByDate);
}

int _compareLogsByDate(Map<String, dynamic> a, Map<String, dynamic> b) {
  final first = LogApi.normalizeDateString(a['log_date']) ?? '';
  final second = LogApi.normalizeDateString(b['log_date']) ?? '';
  return first.compareTo(second);
}

DateTime? _parseDateOnly(dynamic value) {
  final normalized = LogApi.normalizeDateString(value);
  if (normalized == null) {
    return null;
  }

  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    return null;
  }

  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _formatDateOnly(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String _pendingLogsKey(int userId) {
  return '${LogApi._pendingLogsKeyPrefix}_$userId';
}

String _cachedLogsKey(int userId) {
  return '${LogApi._cachedLogsKeyPrefix}_$userId';
}

String _syncedStreakKey(int userId) {
  return '${LogApi._syncedStreakKeyPrefix}_$userId';
}

String _hydrationPrefillKey(int userId) {
  return '${LogApi._hydrationPrefillKeyPrefix}_$userId';
}

String _exercisePrefillKey(int userId) {
  return '${LogApi._exercisePrefillKeyPrefix}_$userId';
}

Future<double> _readHydrationPrefillForUser(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(_hydrationPrefillKey(userId)) ?? 0;
}

Future<void> _clearHydrationPrefillForUser(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_hydrationPrefillKey(userId));
}

Future<Map<String, dynamic>?> _readExercisePrefillForUser(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_exercisePrefillKey(userId));
  if (raw == null || raw.isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }

    final data = Map<String, dynamic>.from(decoded);
    if (data['date']?.toString() != LogApi.todayKey()) {
      await _clearExercisePrefillForUser(userId);
      return null;
    }

    return data;
  } catch (_) {
    return null;
  }
}

Future<void> _clearExercisePrefillForUser(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_exercisePrefillKey(userId));
}

Future<Map<String, dynamic>> _saveOfflineWeeklyPulse({
  required int userId,
  required String weekStart,
  required Map<String, dynamic> body,
}) async {
  final status = _weeklyPulseStatusFromSave(
    const <String, dynamic>{},
    userId: userId,
    weekStart: weekStart,
    body: body,
    isOffline: true,
  );

  await _cacheWeeklyPulseStatus(userId, weekStart, status);
  await OfflineCacheStore.saveJson(
    namespace: LogApi._weeklyPulsePendingCache,
    scope: _weeklyPulseScope(userId, weekStart),
    data: {'week_start_date': weekStart, 'body': body},
  );
  await invalidateNotificationFeedCache();

  return {
    'message': 'Weekly pulse saved locally and will sync when online',
    'week_start_date': weekStart,
    'response': status['response'],
    'is_offline': true,
    'pending_sync': true,
  };
}

Map<String, dynamic> _weeklyPulseStatusFromSave(
  Map<String, dynamic> data, {
  required int userId,
  required String weekStart,
  required Map<String, dynamic> body,
  required bool isOffline,
}) {
  final rawResponse = data['response'];
  final response = rawResponse is Map
      ? Map<String, dynamic>.from(rawResponse)
      : _weeklyPulseResponseFromBody(
          userId: userId,
          weekStart: weekStart,
          body: body,
        );

  return {
    'week_start_date': data['week_start_date']?.toString() ?? weekStart,
    'has_response': true,
    'response': response,
    'is_offline': isOffline,
    'pending_sync': isOffline,
  };
}

Map<String, dynamic> _weeklyPulseResponseFromBody({
  required int userId,
  required String weekStart,
  required Map<String, dynamic> body,
}) {
  final now = DateTime.now().toIso8601String();
  return {
    'pulse_id': 0,
    'user_id': userId,
    'week_start_date': weekStart,
    'productivity_focus_level': LogApi.parseInt(
      body['productivity_focus_level'],
    ),
    'recovery_rest_level': LogApi.parseInt(body['recovery_rest_level']),
    'detachment_level': LogApi.parseInt(body['detachment_level']),
    'accomplishment_level': LogApi.parseInt(body['accomplishment_level']),
    'created_at': now,
    'updated_at': now,
  };
}

Future<void> _cacheWeeklyPulseStatus(
  int userId,
  String weekStart,
  Map<String, dynamic> data,
) {
  return OfflineCacheStore.saveJson(
    namespace: LogApi._weeklyPulseStatusCache,
    scope: _weeklyPulseScope(userId, weekStart),
    data: {
      'week_start_date': data['week_start_date']?.toString() ?? weekStart,
      'has_response': data['has_response'] == true || data['response'] is Map,
      'response': data['response'],
      'is_offline': data['is_offline'] == true,
      'pending_sync': data['pending_sync'] == true,
    },
  );
}

Future<Map<String, dynamic>?> _readCachedWeeklyPulseStatus(
  int userId,
  String weekStart,
) {
  return OfflineCacheStore.readLatestJson(
    namespace: LogApi._weeklyPulseStatusCache,
    scope: _weeklyPulseScope(userId, weekStart),
  );
}

Future<void> _syncCachedWeeklyPulse(int userId, String weekStart) async {
  final pending = await OfflineCacheStore.readLatestJson(
    namespace: LogApi._weeklyPulsePendingCache,
    scope: _weeklyPulseScope(userId, weekStart),
  );
  final body = pending?['body'];
  if (body is! Map) {
    return;
  }

  final data = await LogApi._postWeeklyPulse(
    userId,
    Map<String, dynamic>.from(body),
  );
  await _cacheWeeklyPulseStatus(
    userId,
    weekStart,
    _weeklyPulseStatusFromSave(
      data,
      userId: userId,
      weekStart: weekStart,
      body: Map<String, dynamic>.from(body),
      isOffline: false,
    ),
  );
  await OfflineCacheStore.remove(
    namespace: LogApi._weeklyPulsePendingCache,
    scope: _weeklyPulseScope(userId, weekStart),
  );
  await invalidateNotificationFeedCache();
}

String _weeklyPulseScope(int userId, String weekStart) {
  return '${userId}_$weekStart';
}
