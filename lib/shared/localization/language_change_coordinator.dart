import '../assistant/overlay_assistant_controller.dart';
import '../notifications/local_notification_service.dart';
import '../preferences/app_preferences.dart';
import 'locale_sensitive_cache_service.dart';

class LanguageChangeCoordinator {
  LanguageChangeCoordinator({
    Future<void> Function()? invalidateCaches,
    Future<void> Function()? refreshReminders,
    Future<void> Function(AppPreferencesState preferences)? restartOverlay,
  }) : _invalidateCaches =
           invalidateCaches ?? LocaleSensitiveCacheService.invalidate,
       _refreshReminders =
           refreshReminders ??
           LocalNotificationService
               .instance
               .refreshReminderScheduleFromPreferences,
       _restartOverlay = restartOverlay ?? _restartAssistantOverlay;

  static final LanguageChangeCoordinator instance = LanguageChangeCoordinator();

  final Future<void> Function() _invalidateCaches;
  final Future<void> Function() _refreshReminders;
  final Future<void> Function(AppPreferencesState preferences) _restartOverlay;

  Future<void> changeLanguage(AppLanguage language) async {
    final preferences = AppPreferencesController.instance;
    final previous = preferences.notifier.value.language;
    if (previous == language) {
      return;
    }

    await preferences.updateLanguage(language);
    await _invalidateCaches();
    await _refreshReminders();

    final prefs = preferences.notifier.value;
    if (prefs.assistantOverlayEnabled) {
      await _restartOverlay(prefs);
    }
  }

  static Future<void> _restartAssistantOverlay(
    AppPreferencesState preferences,
  ) async {
    await OverlayAssistantController.instance.stopOverlayService();
    await OverlayAssistantController.instance.syncSettings(preferences);
  }
}
