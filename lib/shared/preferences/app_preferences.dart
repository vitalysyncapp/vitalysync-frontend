import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, filipino }

enum AppFontSize { small, medium, large }

enum AppLocationPermissionChoice { undecided, allowed, denied }

@immutable
class AppPreferencesState {
  final ThemeMode themeMode;
  final AppLanguage language;
  final AppFontSize fontSize;
  final bool notificationsEnabled;
  final bool bedtimeReminderEnabled;
  final bool hydrationReminderEnabled;
  final bool mealReminderEnabled;
  final String dailyLogReminderTime;
  final String hydrationStartTime;
  final String hydrationEndTime;
  final int hydrationIntervalMinutes;
  final String sleepWindDownTime;
  final bool hideSensitiveContent;
  final bool biometricLockEnabled;
  final AppLocationPermissionChoice locationPermissionChoice;
  final bool assistantOverlayEnabled;
  final bool isLoaded;

  const AppPreferencesState({
    required this.themeMode,
    required this.language,
    required this.fontSize,
    required this.notificationsEnabled,
    required this.bedtimeReminderEnabled,
    required this.hydrationReminderEnabled,
    required this.mealReminderEnabled,
    required this.dailyLogReminderTime,
    required this.hydrationStartTime,
    required this.hydrationEndTime,
    required this.hydrationIntervalMinutes,
    required this.sleepWindDownTime,
    required this.hideSensitiveContent,
    required this.biometricLockEnabled,
    required this.locationPermissionChoice,
    required this.assistantOverlayEnabled,
    required this.isLoaded,
  });

  const AppPreferencesState.defaults()
    : themeMode = ThemeMode.light,
      language = AppLanguage.english,
      fontSize = AppFontSize.medium,
      notificationsEnabled = true,
      bedtimeReminderEnabled = true,
      hydrationReminderEnabled = true,
      mealReminderEnabled = true,
      dailyLogReminderTime = '20:00',
      hydrationStartTime = '07:00',
      hydrationEndTime = '21:00',
      hydrationIntervalMinutes = 120,
      sleepWindDownTime = '21:30',
      hideSensitiveContent = false,
      biometricLockEnabled = false,
      locationPermissionChoice = AppLocationPermissionChoice.undecided,
      assistantOverlayEnabled = false,
      isLoaded = false;

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    AppFontSize? fontSize,
    bool? notificationsEnabled,
    bool? bedtimeReminderEnabled,
    bool? hydrationReminderEnabled,
    bool? mealReminderEnabled,
    String? dailyLogReminderTime,
    String? hydrationStartTime,
    String? hydrationEndTime,
    int? hydrationIntervalMinutes,
    String? sleepWindDownTime,
    bool? hideSensitiveContent,
    bool? biometricLockEnabled,
    AppLocationPermissionChoice? locationPermissionChoice,
    bool? assistantOverlayEnabled,
    bool? isLoaded,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      bedtimeReminderEnabled:
          bedtimeReminderEnabled ?? this.bedtimeReminderEnabled,
      hydrationReminderEnabled:
          hydrationReminderEnabled ?? this.hydrationReminderEnabled,
      mealReminderEnabled: mealReminderEnabled ?? this.mealReminderEnabled,
      dailyLogReminderTime: dailyLogReminderTime ?? this.dailyLogReminderTime,
      hydrationStartTime: hydrationStartTime ?? this.hydrationStartTime,
      hydrationEndTime: hydrationEndTime ?? this.hydrationEndTime,
      hydrationIntervalMinutes:
          hydrationIntervalMinutes ?? this.hydrationIntervalMinutes,
      sleepWindDownTime: sleepWindDownTime ?? this.sleepWindDownTime,
      hideSensitiveContent: hideSensitiveContent ?? this.hideSensitiveContent,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      locationPermissionChoice:
          locationPermissionChoice ?? this.locationPermissionChoice,
      assistantOverlayEnabled:
          assistantOverlayEnabled ?? this.assistantOverlayEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  Locale get locale {
    switch (language) {
      case AppLanguage.filipino:
        return const Locale('fil');
      case AppLanguage.english:
        return const Locale('en');
    }
  }

  double get textScaleFactor {
    switch (fontSize) {
      case AppFontSize.small:
        return 0.93;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.10;
    }
  }

  String get languageLabel {
    switch (language) {
      case AppLanguage.filipino:
        return 'Filipino';
      case AppLanguage.english:
        return 'English';
    }
  }

  String get fontSizeLabel {
    switch (fontSize) {
      case AppFontSize.small:
        return 'Small';
      case AppFontSize.medium:
        return 'Medium';
      case AppFontSize.large:
        return 'Large';
    }
  }

  bool get isLocationAccessEnabled =>
      locationPermissionChoice == AppLocationPermissionChoice.allowed;

  String get locationPermissionLabel {
    switch (locationPermissionChoice) {
      case AppLocationPermissionChoice.allowed:
        return 'Allowed';
      case AppLocationPermissionChoice.denied:
        return 'Denied';
      case AppLocationPermissionChoice.undecided:
        return 'Ask next time';
    }
  }
}

class AppPreferencesController {
  AppPreferencesController._();

  static final AppPreferencesController instance = AppPreferencesController._();

  static const String _themeModeKey = 'app_theme_mode';
  static const String _languageKey = 'app_language';
  static const String _fontSizeKey = 'app_font_size';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _bedtimeReminderKey = 'bedtime_reminder_enabled';
  static const String _hydrationReminderKey = 'hydration_reminder_enabled';
  static const String _mealReminderKey = 'meal_reminder_enabled';
  static const String _dailyLogReminderTimeKey = 'daily_log_reminder_time';
  static const String _hydrationStartTimeKey = 'hydration_start_time';
  static const String _hydrationEndTimeKey = 'hydration_end_time';
  static const String _hydrationIntervalMinutesKey =
      'hydration_interval_minutes';
  static const String _sleepWindDownTimeKey = 'sleep_wind_down_time';
  static const String _hideSensitiveContentKey = 'hide_sensitive_content';
  static const String _biometricLockKey = 'biometric_lock_enabled';
  static const String _locationPermissionChoiceKey =
      'location_permission_choice';
  static const String _assistantOverlayEnabledKey = 'assistant_overlay_enabled';

  final ValueNotifier<AppPreferencesState> notifier =
      ValueNotifier<AppPreferencesState>(const AppPreferencesState.defaults());

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeName = prefs.getString(_themeModeKey);
      final languageName = prefs.getString(_languageKey);
      final fontSizeName = prefs.getString(_fontSizeKey);
      final notificationsEnabled = prefs.getBool(_notificationsEnabledKey);
      final bedtimeReminderEnabled = prefs.getBool(_bedtimeReminderKey);
      final hydrationReminderEnabled = prefs.getBool(_hydrationReminderKey);
      final mealReminderEnabled = prefs.getBool(_mealReminderKey);
      final dailyLogReminderTime = prefs.getString(_dailyLogReminderTimeKey);
      final hydrationStartTime = prefs.getString(_hydrationStartTimeKey);
      final hydrationEndTime = prefs.getString(_hydrationEndTimeKey);
      final hydrationIntervalMinutes = prefs.getInt(
        _hydrationIntervalMinutesKey,
      );
      final sleepWindDownTime = prefs.getString(_sleepWindDownTimeKey);
      final hideSensitiveContent = prefs.getBool(_hideSensitiveContentKey);
      final biometricLockEnabled = prefs.getBool(_biometricLockKey);
      final locationPermissionChoice = prefs.getString(
        _locationPermissionChoiceKey,
      );
      final assistantOverlayEnabled = prefs.getBool(
        _assistantOverlayEnabledKey,
      );

      notifier.value = AppPreferencesState(
        themeMode: _themeModeFromString(themeModeName),
        language: _languageFromString(languageName),
        fontSize: _fontSizeFromString(fontSizeName),
        notificationsEnabled: notificationsEnabled ?? true,
        bedtimeReminderEnabled: bedtimeReminderEnabled ?? true,
        hydrationReminderEnabled: hydrationReminderEnabled ?? true,
        mealReminderEnabled: mealReminderEnabled ?? true,
        dailyLogReminderTime: dailyLogReminderTime ?? '20:00',
        hydrationStartTime: hydrationStartTime ?? '07:00',
        hydrationEndTime: hydrationEndTime ?? '21:00',
        hydrationIntervalMinutes: hydrationIntervalMinutes ?? 120,
        sleepWindDownTime: sleepWindDownTime ?? '21:30',
        hideSensitiveContent: hideSensitiveContent ?? false,
        biometricLockEnabled: biometricLockEnabled ?? false,
        locationPermissionChoice: _locationPermissionChoiceFromString(
          locationPermissionChoice,
        ),
        assistantOverlayEnabled: assistantOverlayEnabled ?? false,
        isLoaded: true,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to load app preferences: $error');
      debugPrintStack(stackTrace: stackTrace);
      notifier.value = const AppPreferencesState.defaults().copyWith(
        isLoaded: true,
      );
    }
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.name);
    notifier.value = notifier.value.copyWith(themeMode: themeMode);
  }

  Future<void> updateLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
    notifier.value = notifier.value.copyWith(language: language);
  }

  Future<void> updateFontSize(AppFontSize fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, fontSize.name);
    notifier.value = notifier.value.copyWith(fontSize: fontSize);
  }

  Future<void> updateNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
    notifier.value = notifier.value.copyWith(notificationsEnabled: value);
  }

  Future<void> updateBedtimeReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bedtimeReminderKey, value);
    notifier.value = notifier.value.copyWith(bedtimeReminderEnabled: value);
  }

  Future<void> updateHydrationReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hydrationReminderKey, value);
    notifier.value = notifier.value.copyWith(hydrationReminderEnabled: value);
  }

  Future<void> updateMealReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mealReminderKey, value);
    notifier.value = notifier.value.copyWith(mealReminderEnabled: value);
  }

  Future<void> updateHideSensitiveContent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideSensitiveContentKey, value);
    notifier.value = notifier.value.copyWith(hideSensitiveContent: value);
  }

  Future<void> updateBiometricLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricLockKey, value);
    notifier.value = notifier.value.copyWith(biometricLockEnabled: value);
  }

  Future<void> updateLocationPermissionChoice(
    AppLocationPermissionChoice choice,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (choice == AppLocationPermissionChoice.undecided) {
      await prefs.remove(_locationPermissionChoiceKey);
    } else {
      await prefs.setString(_locationPermissionChoiceKey, choice.name);
    }

    notifier.value = notifier.value.copyWith(locationPermissionChoice: choice);
  }

  Future<void> updateAssistantOverlayEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_assistantOverlayEnabledKey, value);
    notifier.value = notifier.value.copyWith(assistantOverlayEnabled: value);
  }

  Future<void> syncNotificationPreferences({
    required bool notificationsEnabled,
    required bool bedtimeReminderEnabled,
    required bool hydrationReminderEnabled,
    bool? mealReminderEnabled,
    String? dailyLogReminderTime,
    String? hydrationStartTime,
    String? hydrationEndTime,
    int? hydrationIntervalMinutes,
    String? sleepWindDownTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, notificationsEnabled);
    await prefs.setBool(_bedtimeReminderKey, bedtimeReminderEnabled);
    await prefs.setBool(_hydrationReminderKey, hydrationReminderEnabled);
    if (mealReminderEnabled != null) {
      await prefs.setBool(_mealReminderKey, mealReminderEnabled);
    }
    if (dailyLogReminderTime != null) {
      await prefs.setString(_dailyLogReminderTimeKey, dailyLogReminderTime);
    }
    if (hydrationStartTime != null) {
      await prefs.setString(_hydrationStartTimeKey, hydrationStartTime);
    }
    if (hydrationEndTime != null) {
      await prefs.setString(_hydrationEndTimeKey, hydrationEndTime);
    }
    if (hydrationIntervalMinutes != null) {
      await prefs.setInt(
        _hydrationIntervalMinutesKey,
        hydrationIntervalMinutes,
      );
    }
    if (sleepWindDownTime != null) {
      await prefs.setString(_sleepWindDownTimeKey, sleepWindDownTime);
    }
    notifier.value = notifier.value.copyWith(
      notificationsEnabled: notificationsEnabled,
      bedtimeReminderEnabled: bedtimeReminderEnabled,
      hydrationReminderEnabled: hydrationReminderEnabled,
      mealReminderEnabled: mealReminderEnabled,
      dailyLogReminderTime: dailyLogReminderTime,
      hydrationStartTime: hydrationStartTime,
      hydrationEndTime: hydrationEndTime,
      hydrationIntervalMinutes: hydrationIntervalMinutes,
      sleepWindDownTime: sleepWindDownTime,
    );
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_fontSizeKey);
    await prefs.remove(_notificationsEnabledKey);
    await prefs.remove(_bedtimeReminderKey);
    await prefs.remove(_hydrationReminderKey);
    await prefs.remove(_mealReminderKey);
    await prefs.remove(_dailyLogReminderTimeKey);
    await prefs.remove(_hydrationStartTimeKey);
    await prefs.remove(_hydrationEndTimeKey);
    await prefs.remove(_hydrationIntervalMinutesKey);
    await prefs.remove(_sleepWindDownTimeKey);
    await prefs.remove(_hideSensitiveContentKey);
    await prefs.remove(_biometricLockKey);
    await prefs.remove(_locationPermissionChoiceKey);
    await prefs.remove(_assistantOverlayEnabledKey);
    notifier.value = AppPreferencesState.defaults().copyWith(isLoaded: true);
  }

  ThemeMode _themeModeFromString(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.light,
    );
  }

  AppLanguage _languageFromString(String? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.english,
    );
  }

  AppFontSize _fontSizeFromString(String? value) {
    return AppFontSize.values.firstWhere(
      (fontSize) => fontSize.name == value,
      orElse: () => AppFontSize.medium,
    );
  }

  AppLocationPermissionChoice _locationPermissionChoiceFromString(
    String? value,
  ) {
    return AppLocationPermissionChoice.values.firstWhere(
      (choice) => choice.name == value,
      orElse: () => AppLocationPermissionChoice.undecided,
    );
  }
}
