// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'VitalySync';

  @override
  String get appPreferencesTitle => 'App preferences';

  @override
  String get appearanceSection => 'Itsura';

  @override
  String get lightMode => 'Light mode';

  @override
  String get lightModeDescription => 'Maliwanag na display para sa daytime use';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeDescription => 'Mas komportableng colors kapag madilim';

  @override
  String get languageSection => 'Wika';

  @override
  String get appLanguage => 'Wika ng app';

  @override
  String get appLanguageDescription =>
      'Binabago ang text, dates, reminders, at generated wellness content sa buong VitalySync';

  @override
  String get englishLanguage => 'English';

  @override
  String get tagalogLanguage => 'Tagalog';

  @override
  String get displaySection => 'Display';

  @override
  String get fontSize => 'Laki ng text';

  @override
  String get fontSizeDescription =>
      'Mas maliit ang small, default ang medium, at mas malaki nang kaunti ang large';

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
      'Ia-adjust ng VitalySync ang text sa buong app ayon sa pinili mong size.';

  @override
  String currentValue({required String value}) {
    return 'Kasalukuyan: $value';
  }

  @override
  String languageChanged({required String language}) {
    return 'Napalitan na ang wika sa $language.';
  }

  @override
  String get dailyCheckInNotificationTitle => 'Daily check-in';

  @override
  String get dailyCheckInNotificationBody =>
      'I-log ang stress, workload, recovery, at energy mo today.';

  @override
  String get hydrationNotificationTitle => 'Water break muna';

  @override
  String get hydrationNotificationBody =>
      'Uminom muna ng tubig bago ang next task mo.';

  @override
  String get sleepNotificationTitle => 'Time to wind down';

  @override
  String get sleepNotificationBody =>
      'Dahan-dahan nang bawasan ang workload para may space ang tulog.';

  @override
  String get smartNudgeFallbackTitle => 'Keep today steady';

  @override
  String get smartNudgeFallbackBody =>
      'Panatilihing simple ang isang recovery habit today.';

  @override
  String smartNudgeFallbackBodyWithName({required String name}) {
    return '$name, panatilihing simple ang isang recovery habit today.';
  }

  @override
  String get keepItSimple => 'Keep it simple';

  @override
  String get localFallback => 'Local fallback';

  @override
  String get unknownLocation => 'Hindi matukoy ang location';

  @override
  String get unknownValue => 'Hindi matukoy';

  @override
  String get noDescriptionAvailable => 'Walang available na description';

  @override
  String get aqiGood => 'Maganda';

  @override
  String get aqiFair => 'Okay';

  @override
  String get aqiModerate => 'Katamtaman';

  @override
  String get aqiPoor => 'Mahina';

  @override
  String get aqiVeryPoor => 'Napakahina';

  @override
  String get weatherClear => 'maaliwalas';

  @override
  String get weatherClouds => 'maulap';

  @override
  String get weatherRain => 'maulan';

  @override
  String get weatherDrizzle => 'may mahinang ulan';

  @override
  String get weatherThunderstorm => 'may thunderstorm';

  @override
  String get weatherSnow => 'may snow';

  @override
  String get weatherAtmosphere => 'maalinsangan o mahamog';

  @override
  String get weatherUnknown => 'walang weather data';
}
