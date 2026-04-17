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
  final bool hideSensitiveContent;
  final bool biometricLockEnabled;
  final AppLocationPermissionChoice locationPermissionChoice;
  final bool isLoaded;

  const AppPreferencesState({
    required this.themeMode,
    required this.language,
    required this.fontSize,
    required this.notificationsEnabled,
    required this.bedtimeReminderEnabled,
    required this.hydrationReminderEnabled,
    required this.hideSensitiveContent,
    required this.biometricLockEnabled,
    required this.locationPermissionChoice,
    required this.isLoaded,
  });

  const AppPreferencesState.defaults()
      : themeMode = ThemeMode.light,
        language = AppLanguage.english,
        fontSize = AppFontSize.medium,
        notificationsEnabled = true,
        bedtimeReminderEnabled = true,
        hydrationReminderEnabled = true,
        hideSensitiveContent = false,
        biometricLockEnabled = false,
        locationPermissionChoice = AppLocationPermissionChoice.undecided,
        isLoaded = false;

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    AppFontSize? fontSize,
    bool? notificationsEnabled,
    bool? bedtimeReminderEnabled,
    bool? hydrationReminderEnabled,
    bool? hideSensitiveContent,
    bool? biometricLockEnabled,
    AppLocationPermissionChoice? locationPermissionChoice,
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
      hideSensitiveContent:
          hideSensitiveContent ?? this.hideSensitiveContent,
      biometricLockEnabled:
          biometricLockEnabled ?? this.biometricLockEnabled,
      locationPermissionChoice:
          locationPermissionChoice ?? this.locationPermissionChoice,
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

  static final AppPreferencesController instance =
      AppPreferencesController._();

  static const String _themeModeKey = 'app_theme_mode';
  static const String _languageKey = 'app_language';
  static const String _fontSizeKey = 'app_font_size';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _bedtimeReminderKey = 'bedtime_reminder_enabled';
  static const String _hydrationReminderKey = 'hydration_reminder_enabled';
  static const String _hideSensitiveContentKey = 'hide_sensitive_content';
  static const String _biometricLockKey = 'biometric_lock_enabled';
  static const String _locationPermissionChoiceKey =
      'location_permission_choice';

  final ValueNotifier<AppPreferencesState> notifier =
      ValueNotifier<AppPreferencesState>(
    const AppPreferencesState.defaults(),
  );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeName = prefs.getString(_themeModeKey);
    final languageName = prefs.getString(_languageKey);
    final fontSizeName = prefs.getString(_fontSizeKey);
    final notificationsEnabled = prefs.getBool(_notificationsEnabledKey);
    final bedtimeReminderEnabled = prefs.getBool(_bedtimeReminderKey);
    final hydrationReminderEnabled = prefs.getBool(_hydrationReminderKey);
    final hideSensitiveContent = prefs.getBool(_hideSensitiveContentKey);
    final biometricLockEnabled = prefs.getBool(_biometricLockKey);
    final locationPermissionChoice =
        prefs.getString(_locationPermissionChoiceKey);

    notifier.value = AppPreferencesState(
      themeMode: _themeModeFromString(themeModeName),
      language: _languageFromString(languageName),
      fontSize: _fontSizeFromString(fontSizeName),
      notificationsEnabled: notificationsEnabled ?? true,
      bedtimeReminderEnabled: bedtimeReminderEnabled ?? true,
      hydrationReminderEnabled: hydrationReminderEnabled ?? true,
      hideSensitiveContent: hideSensitiveContent ?? false,
      biometricLockEnabled: biometricLockEnabled ?? false,
      locationPermissionChoice:
          _locationPermissionChoiceFromString(locationPermissionChoice),
      isLoaded: true,
    );
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
    notifier.value =
        notifier.value.copyWith(hydrationReminderEnabled: value);
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

  Future<void> syncNotificationPreferences({
    required bool notificationsEnabled,
    required bool bedtimeReminderEnabled,
    required bool hydrationReminderEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, notificationsEnabled);
    await prefs.setBool(_bedtimeReminderKey, bedtimeReminderEnabled);
    await prefs.setBool(_hydrationReminderKey, hydrationReminderEnabled);
    notifier.value = notifier.value.copyWith(
      notificationsEnabled: notificationsEnabled,
      bedtimeReminderEnabled: bedtimeReminderEnabled,
      hydrationReminderEnabled: hydrationReminderEnabled,
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
    await prefs.remove(_hideSensitiveContentKey);
    await prefs.remove(_biometricLockKey);
    await prefs.remove(_locationPermissionChoiceKey);
    notifier.value = AppPreferencesState.defaults().copyWith(
      isLoaded: true,
    );
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
