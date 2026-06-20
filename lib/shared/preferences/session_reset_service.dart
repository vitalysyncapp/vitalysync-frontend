import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/activity/data/activity_service.dart';
import '../../features/exercise/data/exercise_goal_service.dart';
import '../../features/log/data/log_api.dart';
import '../../features/onboarding/services/onboarding_service.dart';
import '../../features/tutorial/services/core_tutorial_service.dart';
import '../assistant/overlay_assistant_controller.dart';
import '../notifications/local_notification_service.dart';
import '../notifications/notification_feed_cache.dart';
import 'app_preferences.dart';
import 'user_session.dart';

class SessionResetService {
  SessionResetService._();

  static final SessionResetService instance = SessionResetService._();

  static const Set<String> _exactLocalAccountKeys = {
    'email',
    'last_login_email',
    'username',
    'user_id',
    'user_type',
    'gender',
    'age',
    'auth_access_token',
    'onboarding_completed',
    'demo_mode_enabled',
    'demo_local_logs',
    'log_streak',
    'longest_log_streak',
    'last_log_date',
    'cached_environment_snapshot',
    'nutrition_last_insight',
    'nutrition_assistant_insight',
    'nutrition_message_history',
    'nutrition_last_push_date',
    'nutrition_assistant_shown_date',
    'nutrition_insight_feedback',
  };

  static const List<String> _localAccountKeyPrefixes = [
    'activity_baseline_date_',
    'activity_baseline_steps_',
    'activity_last_raw_date_',
    'activity_last_raw_steps_',
    'activity_preferred_goal_steps_',
    'assistant_exercise_prefill',
    'assistant_hydration_prefill',
    'cached_daily_activity_',
    'cached_daily_logs',
    'cached_exercise_goal_',
    CoreTutorialService.storageKeyPrefix,
    'first_week_learning_started_at_',
    'local_weekly_pulse',
    'notification_feed_read_ids_v2_',
    'nutrition_manual_meal_suggestions',
    'offline_cache_v1_',
    'offline_pending_logs',
    'onboarding_',
    'overlay_preview_',
    'pending_daily_activity_',
    'profile_',
    'recovery_mode_',
    'synced_log_streak',
  ];

  Future<void> resetForLogout() async {
    await _ignoreCleanupError(
      'assistant overlay',
      OverlayAssistantController.instance.disableForLogout(),
    );
    await _ignoreCleanupError(
      'activity tracking',
      ActivityService.instance.resetForLogout(),
    );
    await _ignoreCleanupError(
      'exercise goal state',
      ExerciseGoalService.instance.resetForLogout(),
    );
    await _ignoreCleanupError(
      'local notifications',
      LocalNotificationService.instance.clearSessionNotifications(),
    );

    await UserSessionController.instance.clearSession();
    await AppPreferencesController.instance.resetToDefaults();
    await LogApi.clearLocalAccountData();
    await OnboardingService.clearDefaults();
    await _clearKnownLocalAccountData();
    await _ignoreCleanupError(
      'notification feed',
      refreshNotificationFeed().timeout(const Duration(milliseconds: 500)),
    );

    await _ignoreCleanupError(
      'assistant overlay preference sync',
      OverlayAssistantController.instance.disableForLogout(),
    );
  }

  Future<void> _clearKnownLocalAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    final accountKeys = prefs
        .getKeys()
        .where(_isLocalAccountKey)
        .toList(growable: false);

    for (final key in accountKeys) {
      await prefs.remove(key);
    }
  }

  bool _isLocalAccountKey(String key) {
    return _exactLocalAccountKeys.contains(key) ||
        _localAccountKeyPrefixes.any(key.startsWith);
  }

  Future<void> _ignoreCleanupError(String label, Future<void> task) async {
    try {
      await task.timeout(const Duration(milliseconds: 500));
    } catch (error, stackTrace) {
      if (error is TimeoutException) {
        return;
      }

      debugPrint('Unable to reset $label during logout: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
