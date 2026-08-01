// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VitalySync';

  @override
  String get appPreferencesTitle => 'App preferences';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get lightMode => 'Light mode';

  @override
  String get lightModeDescription => 'Bright surfaces and default daytime look';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeDescription => 'Low-light colors for evening use';

  @override
  String get languageSection => 'Language';

  @override
  String get appLanguage => 'App language';

  @override
  String get appLanguageDescription =>
      'Changes text, dates, reminders, and generated wellness content throughout VitalySync';

  @override
  String get englishLanguage => 'English';

  @override
  String get tagalogLanguage => 'Tagalog';

  @override
  String get displaySection => 'Display';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontSizeDescription =>
      'Small is a bit smaller, medium matches the default UI, and large is a bit bigger';

  @override
  String get smallSize => 'Small';

  @override
  String get mediumSize => 'Medium';

  @override
  String get largeSize => 'Large';

  @override
  String get preview => 'Preview';

  @override
  String get fontPreviewDescription =>
      'VitalySync will scale text throughout the app using your selected size.';

  @override
  String currentValue({required String value}) {
    return 'Current: $value';
  }

  @override
  String languageChanged({required String language}) {
    return 'Language changed to $language.';
  }

  @override
  String get dailyCheckInNotificationTitle => 'Daily check-in';

  @override
  String get dailyCheckInNotificationBody =>
      'Log today\'s stress, workload, recovery, and energy.';

  @override
  String get hydrationNotificationTitle => 'Hydration reset';

  @override
  String get hydrationNotificationBody =>
      'Take a quick water break before your next task.';

  @override
  String get sleepNotificationTitle => 'Wind down soon';

  @override
  String get sleepNotificationBody =>
      'Start easing your workload so sleep has room to happen.';

  @override
  String get smartNudgeFallbackTitle => 'Keep today steady';

  @override
  String get smartNudgeFallbackBody => 'Keep one recovery habit simple today.';

  @override
  String smartNudgeFallbackBodyWithName({required String name}) {
    return '$name, keep one recovery habit simple today.';
  }

  @override
  String get keepItSimple => 'Keep it simple';

  @override
  String get localFallback => 'Local fallback';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get noDescriptionAvailable => 'No description available';

  @override
  String get aqiGood => 'Good';

  @override
  String get aqiFair => 'Fair';

  @override
  String get aqiModerate => 'Moderate';

  @override
  String get aqiPoor => 'Poor';

  @override
  String get aqiVeryPoor => 'Very poor';

  @override
  String get weatherClear => 'clear skies';

  @override
  String get weatherClouds => 'cloudy';

  @override
  String get weatherRain => 'rainy';

  @override
  String get weatherDrizzle => 'light rain';

  @override
  String get weatherThunderstorm => 'thunderstorms';

  @override
  String get weatherSnow => 'snowy';

  @override
  String get weatherAtmosphere => 'hazy';

  @override
  String get weatherUnknown => 'weather unavailable';
}
