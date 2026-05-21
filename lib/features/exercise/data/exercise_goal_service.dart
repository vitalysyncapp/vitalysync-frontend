import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/preferences/user_session.dart';
import '../../../shared/notifications/notification_feed_cache.dart';
import '../../activity/data/activity_service.dart';
import 'exercise_goal_api.dart';
import 'exercise_goal_model.dart';
import 'exercise_recommendation_model.dart';

class ExerciseGoalState {
  final ExerciseGoalModel? goal;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? completionMessage;
  final int completionEventId;

  const ExerciseGoalState({
    required this.goal,
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
    required this.completionMessage,
    required this.completionEventId,
  });

  factory ExerciseGoalState.initial() {
    return const ExerciseGoalState(
      goal: null,
      isLoading: true,
      isSaving: false,
      errorMessage: null,
      completionMessage: null,
      completionEventId: 0,
    );
  }

  bool get hasSelectedGoal {
    final currentGoal = goal;
    return currentGoal != null && currentGoal.hasSelectedGoal;
  }

  ExerciseGoalState copyWith({
    ExerciseGoalModel? goal,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? completionMessage,
    int? completionEventId,
    bool clearGoal = false,
    bool clearError = false,
    bool clearCompletion = false,
  }) {
    return ExerciseGoalState(
      goal: clearGoal ? null : goal ?? this.goal,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      completionMessage: clearCompletion
          ? null
          : completionMessage ?? this.completionMessage,
      completionEventId: completionEventId ?? this.completionEventId,
    );
  }
}

class ExerciseGoalService {
  ExerciseGoalService._();

  static final ExerciseGoalService instance = ExerciseGoalService._();
  static const String cachedGoalKeyPrefix = 'cached_exercise_goal';

  final ValueNotifier<ExerciseGoalState> notifier =
      ValueNotifier<ExerciseGoalState>(ExerciseGoalState.initial());

  VoidCallback? _activityListener;
  bool _hasStarted = false;
  bool _isCompletingDistanceGoal = false;

  static String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> start() async {
    if (_hasStarted) {
      await refresh();
      return;
    }

    _hasStarted = true;
    _activityListener = () => unawaited(_handleActivityChanged());
    ActivityService.instance.notifier.addListener(_activityListener!);
    await refresh();
  }

  Future<void> refresh() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final cachedGoal = await readCachedGoal(userId);
    final cachedTodayGoal = _todayOrNull(cachedGoal);

    _emit(
      notifier.value.copyWith(
        goal: cachedTodayGoal,
        clearGoal: cachedTodayGoal == null,
        isLoading: false,
      ),
    );

    if (userId <= 0) {
      return;
    }

    try {
      final serverGoal = await ExerciseGoalApi.fetchToday(
        userId: userId,
        logDate: todayKey(),
      );
      if (serverGoal != null) {
        await cacheGoal(userId, serverGoal);
      }
      final todayGoal = _todayOrNull(serverGoal) ?? cachedTodayGoal;

      _emit(
        notifier.value.copyWith(
          goal: todayGoal,
          clearGoal: todayGoal == null,
          isLoading: false,
          clearError: true,
        ),
      );

      await _handleActivityChanged();
    } catch (error) {
      _emit(
        notifier.value.copyWith(
          isLoading: false,
          errorMessage:
              'Exercise goal will sync when the service is available.',
        ),
      );
    }
  }

  Future<ExerciseGoalModel> chooseExercise(
    ExerciseRecommendationModel recommendation,
  ) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final localGoal = ExerciseGoalModel.fromRecommendation(
      recommendation: recommendation,
      logDate: todayKey(),
      userId: userId,
    );

    _emit(notifier.value.copyWith(isSaving: true, clearError: true));

    try {
      final savedGoal = userId <= 0
          ? localGoal
          : await ExerciseGoalApi.choose(userId: userId, goal: localGoal);
      await cacheGoal(userId, savedGoal);
      _emit(
        notifier.value.copyWith(
          goal: savedGoal,
          isSaving: false,
          clearError: true,
        ),
      );
      await _handleActivityChanged();
      await invalidateNotificationFeedCache();
      return savedGoal;
    } catch (error) {
      await cacheGoal(userId, localGoal);
      _emit(
        notifier.value.copyWith(
          goal: localGoal,
          isSaving: false,
          errorMessage:
              'Saved on this device. It will be included with today\'s log.',
        ),
      );
      await invalidateNotificationFeedCache();
      return localGoal;
    }
  }

  Future<void> completeGoal({bool automatic = false}) async {
    final currentGoal = notifier.value.goal;
    if (currentGoal == null ||
        currentGoal.isCompleted ||
        currentGoal.isCanceled ||
        currentGoal.isNoneToday) {
      return;
    }

    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final completedGoal = currentGoal.copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
    );

    _emit(notifier.value.copyWith(isSaving: true, clearError: true));

    try {
      final savedGoal = userId <= 0
          ? completedGoal
          : await ExerciseGoalApi.complete(
              userId: userId,
              logDate: currentGoal.logDate,
            );
      await _saveCompletedGoal(userId, savedGoal, automatic: automatic);
    } catch (_) {
      await _saveCompletedGoal(userId, completedGoal, automatic: automatic);
    }
  }

  Future<void> cancelGoal() async {
    final currentGoal = notifier.value.goal;
    if (currentGoal == null || currentGoal.isCanceled) {
      return;
    }

    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final canceledGoal = currentGoal.copyWith(
      status: 'canceled',
      clearCompletedAt: true,
    );

    _emit(notifier.value.copyWith(isSaving: true, clearError: true));

    try {
      final savedGoal = userId <= 0
          ? canceledGoal
          : await ExerciseGoalApi.cancel(
              userId: userId,
              logDate: currentGoal.logDate,
            );
      await cacheGoal(userId, savedGoal);
      _emit(
        notifier.value.copyWith(
          goal: savedGoal,
          isSaving: false,
          clearError: true,
        ),
      );
      await invalidateNotificationFeedCache();
    } catch (_) {
      await cacheGoal(userId, canceledGoal);
      _emit(
        notifier.value.copyWith(
          goal: canceledGoal,
          isSaving: false,
          errorMessage: 'Canceled locally. The server will update later.',
        ),
      );
      await invalidateNotificationFeedCache();
    }
  }

  Future<Map<String, dynamic>> goalMetadataForDailyLog() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    final currentGoal =
        _todayOrNull(notifier.value.goal) ??
        _todayOrNull(await readCachedGoal(userId));

    if (currentGoal == null || currentGoal.isCanceled) {
      return const {};
    }

    return currentGoal.toDailyLogMetadata();
  }

  Future<ExerciseGoalModel?> readCachedGoal(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cachedGoalKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return ExerciseGoalModel.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> cacheGoal(int userId, ExerciseGoalModel goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cachedGoalKey(userId), jsonEncode(goal.toJson()));
  }

  static String cachedGoalKey(int userId) {
    return '${cachedGoalKeyPrefix}_$userId';
  }

  Future<void> _handleActivityChanged() async {
    if (_isCompletingDistanceGoal) {
      return;
    }

    final goal = notifier.value.goal;
    if (goal == null ||
        !goal.isActive ||
        !goal.isStepTrackedMovement ||
        (goal.targetDistanceMeters ?? 0) <= 0) {
      return;
    }

    final distanceMeters =
        ActivityService.instance.notifier.value.log.distanceMeters;
    if (distanceMeters < (goal.targetDistanceMeters ?? 0)) {
      return;
    }

    final session = await UserSessionController.instance.load();
    final userId = session.userId ?? 0;
    _isCompletingDistanceGoal = true;

    try {
      final savedGoal = userId <= 0
          ? goal.copyWith(status: 'completed', completedAt: DateTime.now())
          : await ExerciseGoalApi.updateProgress(
              userId: userId,
              logDate: goal.logDate,
              distanceMeters: distanceMeters,
            );

      if (savedGoal.isCompleted) {
        await _saveCompletedGoal(userId, savedGoal, automatic: true);
      }
    } finally {
      _isCompletingDistanceGoal = false;
    }
  }

  Future<void> _saveCompletedGoal(
    int userId,
    ExerciseGoalModel goal, {
    required bool automatic,
  }) async {
    await cacheGoal(userId, goal);
    final eventId = notifier.value.completionEventId + 1;
    _emit(
      notifier.value.copyWith(
        goal: goal,
        isSaving: false,
        completionEventId: eventId,
        completionMessage: automatic
            ? '${goal.exerciseName} goal completed automatically.'
            : '${goal.exerciseName} goal marked done.',
        clearError: true,
      ),
    );
    await invalidateNotificationFeedCache();
  }

  ExerciseGoalModel? _todayOrNull(ExerciseGoalModel? goal) {
    if (goal == null || goal.logDate != todayKey()) {
      return null;
    }

    return goal;
  }

  void _emit(ExerciseGoalState state) {
    notifier.value = state;
  }
}
