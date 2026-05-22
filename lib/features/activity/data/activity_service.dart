import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/preferences/user_session.dart';
import '../../../shared/notifications/notification_feed_cache.dart';
import 'activity_api.dart';
import 'activity_log.dart';

class ActivityTrackingState {
  final ActivityLog log;
  final bool isLoading;
  final bool isOffline;
  final bool permissionGranted;
  final bool isTracking;
  final int pendingSyncCount;
  final String? errorMessage;

  const ActivityTrackingState({
    required this.log,
    required this.isLoading,
    required this.isOffline,
    required this.permissionGranted,
    required this.isTracking,
    required this.pendingSyncCount,
    required this.errorMessage,
  });

  factory ActivityTrackingState.initial() {
    return ActivityTrackingState(
      log: ActivityLog.empty(logDate: ActivityService.todayKey()),
      isLoading: true,
      isOffline: false,
      permissionGranted: false,
      isTracking: false,
      pendingSyncCount: 0,
      errorMessage: null,
    );
  }

  ActivityTrackingState copyWith({
    ActivityLog? log,
    bool? isLoading,
    bool? isOffline,
    bool? permissionGranted,
    bool? isTracking,
    int? pendingSyncCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActivityTrackingState(
      log: log ?? this.log,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isTracking: isTracking ?? this.isTracking,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ActivityService {
  ActivityService._();

  static final ActivityService instance = ActivityService._();
  static const Duration _syncDebounce = Duration(seconds: 20);
  static const String _cachedActivityKeyPrefix = 'cached_daily_activity';
  static const String _pendingActivityKeyPrefix = 'pending_daily_activity';
  static const String _baselineDateKeyPrefix = 'activity_baseline_date';
  static const String _baselineStepsKeyPrefix = 'activity_baseline_steps';
  static const String _lastRawDateKeyPrefix = 'activity_last_raw_date';
  static const String _lastRawStepsKeyPrefix = 'activity_last_raw_steps';
  static const String _preferredGoalStepsKeyPrefix =
      'activity_preferred_goal_steps';

  final ValueNotifier<ActivityTrackingState> notifier =
      ValueNotifier<ActivityTrackingState>(ActivityTrackingState.initial());

  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _dayBoundaryTimer;
  DateTime? _lastSyncAttempt;
  bool _hasStarted = false;
  bool _isStarting = false;
  bool _isSyncing = false;

  static String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> startTracking({bool refreshFromBackend = true}) async {
    if (_hasStarted || _isStarting) {
      await _loadCachedActivity(markLoading: false);
      _scheduleDayBoundaryRefresh();
      if (refreshFromBackend) {
        unawaited(refresh());
      }
      return;
    }

    _isStarting = true;
    try {
      await _loadCachedActivity();
      _scheduleDayBoundaryRefresh();

      if (refreshFromBackend) {
        unawaited(refresh());
      }

      if (!_canUsePhoneSensors) {
        _emit(
          notifier.value.copyWith(
            isLoading: false,
            isTracking: false,
            permissionGranted: false,
            errorMessage: 'Phone step sensor is available on Android and iOS.',
          ),
        );
        return;
      }

      final hasPermission = await requestActivityRecognitionPermission();
      if (!hasPermission) {
        _emit(
          notifier.value.copyWith(
            isLoading: false,
            isTracking: false,
            permissionGranted: false,
            errorMessage: 'Activity permission is needed to track steps.',
          ),
        );
        return;
      }

      await _listenToStepCount();
      _scheduleDayBoundaryRefresh();
      _hasStarted = true;
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> requestActivityRecognitionPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    final status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      return false;
    }

    final requestedStatus = await Permission.activityRecognition.request();
    return requestedStatus.isGranted;
  }

  Future<void> refresh() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final today = todayKey();
    final preferredGoalSteps = await _preferredGoalStepsForUser(userId);

    await _loadCachedActivity(markLoading: false);

    if (userId <= 0) {
      _emit(
        notifier.value.copyWith(
          isLoading: false,
          isOffline: false,
          pendingSyncCount: 0,
          clearError: true,
        ),
      );
      return;
    }

    try {
      await syncPendingActivityLogs();
      final serverLog = await ActivityApi.fetchToday(
        userId: userId,
        logDate: today,
      );
      final localLog = await _readCachedActivity(userId);
      final log = _preferLatestTodayLog(
        localLog: localLog,
        serverLog: serverLog,
        today: today,
        defaultGoalSteps: preferredGoalSteps,
      );

      await _cacheActivity(userId, log);
      _emit(
        notifier.value.copyWith(
          log: log,
          isLoading: false,
          isOffline: false,
          pendingSyncCount: await pendingActivityCount(),
          clearError: true,
        ),
      );
    } catch (_) {
      _emit(
        notifier.value.copyWith(
          isLoading: false,
          isOffline: true,
          pendingSyncCount: await pendingActivityCount(),
        ),
      );
    }
  }

  Future<int> pendingActivityCount() async {
    final session = await UserSessionController.instance.load();
    if (session.userId == null || session.userId! <= 0) {
      return 0;
    }

    return (await _readPendingActivities(session.userId!)).length;
  }

  Future<int> syncPendingActivityLogs() async {
    if (_isSyncing) {
      return 0;
    }

    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      return 0;
    }

    final pendingLogs = await _readPendingActivities(userId);
    if (pendingLogs.isEmpty) {
      _emit(notifier.value.copyWith(pendingSyncCount: 0, isOffline: false));
      return 0;
    }

    _isSyncing = true;
    var syncedCount = 0;
    final remainingLogs = [...pendingLogs];
    final sortedLogs = [...pendingLogs]
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    try {
      for (final log in sortedLogs) {
        final savedLog = await ActivityApi.save(userId: userId, log: log);
        await _cacheActivity(userId, savedLog);
        remainingLogs.removeWhere((item) => item.logDate == log.logDate);
        await _writePendingActivities(userId, remainingLogs);
        syncedCount++;
      }

      _emit(
        notifier.value.copyWith(
          pendingSyncCount: remainingLogs.length,
          isOffline: false,
          clearError: true,
        ),
      );
      if (syncedCount > 0) {
        await invalidateNotificationFeedCache();
      }
      return syncedCount;
    } catch (_) {
      _emit(
        notifier.value.copyWith(
          pendingSyncCount: remainingLogs.length,
          isOffline: true,
        ),
      );
      return syncedCount;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> disposeTracking() async {
    await _stepSubscription?.cancel();
    _dayBoundaryTimer?.cancel();
    _stepSubscription = null;
    _dayBoundaryTimer = null;
    _hasStarted = false;
  }

  bool get _canUsePhoneSensors {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> _listenToStepCount() async {
    await _stepSubscription?.cancel();

    try {
      final stepStream = Pedometer.stepCountStream;
      _stepSubscription = stepStream.listen(
        (event) => unawaited(_handleStepCount(event)),
        onError: _handleStepCountError,
      );

      _emit(
        notifier.value.copyWith(
          isLoading: false,
          isTracking: true,
          permissionGranted: true,
          clearError: true,
        ),
      );
    } catch (error) {
      _handleStepCountError(error);
    }
  }

  Future<void> _handleStepCount(StepCount event) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final today = todayKey();
    final preferredGoalSteps = await _preferredGoalStepsForUser(userId);
    final cachedLog = await _readCachedActivity(userId);
    final cachedTodaySteps = cachedLog?.logDate == today ? cachedLog!.steps : 0;
    final rawSteps = max(0, event.steps);
    var baselineDate = prefs.getString(_baselineDateKey(userId));
    var baselineSteps = prefs.getInt(_baselineStepsKey(userId));
    final lastRawDate = prefs.getString(_lastRawDateKey(userId));
    final lastRawSteps = prefs.getInt(_lastRawStepsKey(userId));

    if (baselineDate != today || baselineSteps == null) {
      baselineSteps =
          lastRawDate != null &&
              lastRawDate != today &&
              lastRawSteps != null &&
              rawSteps >= lastRawSteps
          ? max(0, lastRawSteps)
          : max(0, rawSteps - cachedTodaySteps);
      baselineDate = today;
      await prefs.setString(_baselineDateKey(userId), baselineDate);
      await prefs.setInt(_baselineStepsKey(userId), baselineSteps);
    }

    if (rawSteps < baselineSteps) {
      baselineSteps = max(0, rawSteps - cachedTodaySteps);
      await prefs.setInt(_baselineStepsKey(userId), baselineSteps);
    }

    final trackedSteps = max(cachedTodaySteps, rawSteps - baselineSteps);
    final log = ActivityLog.fromSteps(
      logDate: today,
      steps: trackedSteps,
      goalSteps: cachedLog?.goalSteps ?? preferredGoalSteps,
    );

    await _cacheActivity(userId, log);
    await prefs.setString(_lastRawDateKey(userId), today);
    await prefs.setInt(_lastRawStepsKey(userId), rawSteps);
    await _queuePendingActivity(session, log);

    _emit(
      notifier.value.copyWith(
        log: log,
        isLoading: false,
        isTracking: true,
        permissionGranted: true,
        pendingSyncCount: await pendingActivityCount(),
        clearError: true,
      ),
    );

    if (_shouldAttemptBackgroundSync(session)) {
      _lastSyncAttempt = DateTime.now();
      unawaited(syncPendingActivityLogs());
    }
  }

  void _scheduleDayBoundaryRefresh() {
    _dayBoundaryTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final delay = tomorrow.difference(now) + const Duration(minutes: 1);
    _dayBoundaryTimer = Timer(delay, () {
      unawaited(_loadCachedActivity(markLoading: false));
      _scheduleDayBoundaryRefresh();
    });
  }

  void _handleStepCountError(Object error) {
    _emit(
      notifier.value.copyWith(
        isLoading: false,
        isTracking: false,
        errorMessage: 'Step sensor is unavailable on this device.',
      ),
    );
  }

  bool _shouldAttemptBackgroundSync(UserSessionSnapshot session) {
    if (session.userId == null || session.userId! <= 0) {
      return false;
    }

    final lastAttempt = _lastSyncAttempt;
    return lastAttempt == null ||
        DateTime.now().difference(lastAttempt) >= _syncDebounce;
  }

  ActivityLog _preferLatestTodayLog({
    required ActivityLog? localLog,
    required ActivityLog? serverLog,
    required String today,
    required int defaultGoalSteps,
  }) {
    final localTodayLog = localLog?.logDate == today ? localLog : null;
    final serverTodayLog = serverLog?.logDate == today ? serverLog : null;

    if (localTodayLog == null && serverTodayLog == null) {
      return ActivityLog.fromSteps(
        logDate: today,
        steps: 0,
        goalSteps: defaultGoalSteps,
      );
    }

    if (localTodayLog == null) {
      return serverTodayLog!;
    }

    if (serverTodayLog == null) {
      return localTodayLog;
    }

    return localTodayLog.steps >= serverTodayLog.steps
        ? localTodayLog
        : serverTodayLog;
  }

  Future<void> _loadCachedActivity({bool markLoading = true}) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final today = todayKey();
    final preferredGoalSteps = await _preferredGoalStepsForUser(userId);
    final cachedLog = await _readCachedActivity(userId);
    final pendingCount = await pendingActivityCount();
    final log = cachedLog?.logDate == today
        ? cachedLog!
        : ActivityLog.fromSteps(
            logDate: today,
            steps: 0,
            goalSteps: preferredGoalSteps,
          );

    _emit(
      notifier.value.copyWith(
        log: log,
        isLoading: markLoading,
        pendingSyncCount: pendingCount,
      ),
    );
  }

  Future<void> _queuePendingActivity(
    UserSessionSnapshot session,
    ActivityLog log,
  ) async {
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      return;
    }

    final pendingLogs = await _readPendingActivities(userId);
    _upsertActivityByDate(pendingLogs, log);
    await _writePendingActivities(userId, pendingLogs);
  }

  Future<ActivityLog?> _readCachedActivity(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedActivityKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return ActivityLog.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> _cacheActivity(int userId, ActivityLog log) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedActivityKey(userId), jsonEncode(log.toJson()));
    await _savePreferredGoalSteps(userId, log.goalSteps);
  }

  Future<void> updateGoalSteps(int goalSteps) async {
    final normalizedGoalSteps = max(1, goalSteps);
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final today = todayKey();
    final currentLog = notifier.value.log;
    final baseLog = currentLog.logDate == today
        ? currentLog
        : ActivityLog.fromSteps(
            logDate: today,
            steps: 0,
            goalSteps: await _preferredGoalStepsForUser(userId),
          );
    final updatedLog =
        ActivityLog.fromSteps(
          logDate: baseLog.logDate,
          steps: baseLog.steps,
          goalSteps: normalizedGoalSteps,
          source: baseLog.source,
        ).copyWith(
          activeMinutes: baseLog.activeMinutes,
          caloriesBurned: baseLog.caloriesBurned,
          exerciseType: baseLog.exerciseType,
        );

    await _cacheActivity(userId, updatedLog);
    if (userId > 0) {
      await _queuePendingActivity(session, updatedLog);
    }

    _emit(
      notifier.value.copyWith(
        log: updatedLog,
        pendingSyncCount: await pendingActivityCount(),
        clearError: true,
      ),
    );
    await invalidateNotificationFeedCache();

    if (_shouldAttemptBackgroundSync(session)) {
      _lastSyncAttempt = DateTime.now();
      unawaited(syncPendingActivityLogs());
    }
  }

  Future<List<ActivityLog>> _readPendingActivities(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingActivityKey(userId));
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
          .map((item) => ActivityLog.fromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => a.logDate.compareTo(b.logDate));
    } catch (_) {
      return [];
    }
  }

  Future<void> _writePendingActivities(
    int userId,
    List<ActivityLog> logs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final sortedLogs = [...logs]
      ..sort((a, b) => a.logDate.compareTo(b.logDate));
    await prefs.setString(
      _pendingActivityKey(userId),
      jsonEncode(sortedLogs.map((log) => log.toJson()).toList()),
    );
  }

  void _upsertActivityByDate(List<ActivityLog> logs, ActivityLog log) {
    final existingIndex = logs.indexWhere(
      (item) => item.logDate == log.logDate,
    );
    if (existingIndex >= 0) {
      logs[existingIndex] = log;
    } else {
      logs.add(log);
    }
  }

  String _cachedActivityKey(int userId) {
    return '${_cachedActivityKeyPrefix}_$userId';
  }

  String _pendingActivityKey(int userId) {
    return '${_pendingActivityKeyPrefix}_$userId';
  }

  String _baselineDateKey(int userId) {
    return '${_baselineDateKeyPrefix}_$userId';
  }

  String _baselineStepsKey(int userId) {
    return '${_baselineStepsKeyPrefix}_$userId';
  }

  String _lastRawDateKey(int userId) {
    return '${_lastRawDateKeyPrefix}_$userId';
  }

  String _lastRawStepsKey(int userId) {
    return '${_lastRawStepsKeyPrefix}_$userId';
  }

  String _preferredGoalStepsKey(int userId) {
    return '${_preferredGoalStepsKeyPrefix}_$userId';
  }

  Future<int> _preferredGoalStepsForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedGoalSteps = prefs.getInt(_preferredGoalStepsKey(userId));
    if (savedGoalSteps == null || savedGoalSteps <= 0) {
      return ActivityLog.defaultGoalSteps;
    }

    return savedGoalSteps;
  }

  Future<void> _savePreferredGoalSteps(int userId, int goalSteps) async {
    if (goalSteps <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_preferredGoalStepsKey(userId), goalSteps);
  }

  void _emit(ActivityTrackingState state) {
    notifier.value = state;
  }
}
