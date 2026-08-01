import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// Product name; do not translate.
  ///
  /// In en, this message translates to:
  /// **'VitalySync'**
  String get appTitle;

  /// Title of the app display preferences page.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get appPreferencesTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @lightModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Bright surfaces and default daytime look'**
  String get lightModeDescription;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @darkModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Low-light colors for evening use'**
  String get darkModeDescription;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @appLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Changes text, dates, reminders, and generated wellness content throughout VitalySync'**
  String get appLanguageDescription;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @tagalogLanguage.
  ///
  /// In en, this message translates to:
  /// **'Tagalog'**
  String get tagalogLanguage;

  /// No description provided for @displaySection.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySection;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @fontSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Small is a bit smaller, medium matches the default UI, and large is a bit bigger'**
  String get fontSizeDescription;

  /// No description provided for @smallSize.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get smallSize;

  /// No description provided for @mediumSize.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumSize;

  /// No description provided for @largeSize.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get largeSize;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @fontPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'VitalySync will scale text throughout the app using your selected size.'**
  String get fontPreviewDescription;

  /// Shows the currently selected preference.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String currentValue({required String value});

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}.'**
  String languageChanged({required String language});

  /// No description provided for @dailyCheckInNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get dailyCheckInNotificationTitle;

  /// No description provided for @dailyCheckInNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s stress, workload, recovery, and energy.'**
  String get dailyCheckInNotificationBody;

  /// No description provided for @hydrationNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration reset'**
  String get hydrationNotificationTitle;

  /// No description provided for @hydrationNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Take a quick water break before your next task.'**
  String get hydrationNotificationBody;

  /// No description provided for @sleepNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Wind down soon'**
  String get sleepNotificationTitle;

  /// No description provided for @sleepNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Start easing your workload so sleep has room to happen.'**
  String get sleepNotificationBody;

  /// No description provided for @smartNudgeFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep today steady'**
  String get smartNudgeFallbackTitle;

  /// No description provided for @smartNudgeFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'Keep one recovery habit simple today.'**
  String get smartNudgeFallbackBody;

  /// No description provided for @smartNudgeFallbackBodyWithName.
  ///
  /// In en, this message translates to:
  /// **'{name}, keep one recovery habit simple today.'**
  String smartNudgeFallbackBodyWithName({required String name});

  /// No description provided for @keepItSimple.
  ///
  /// In en, this message translates to:
  /// **'Keep it simple'**
  String get keepItSimple;

  /// No description provided for @localFallback.
  ///
  /// In en, this message translates to:
  /// **'Local fallback'**
  String get localFallback;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownValue;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @aqiGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get aqiGood;

  /// No description provided for @aqiFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get aqiFair;

  /// No description provided for @aqiModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get aqiModerate;

  /// No description provided for @aqiPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get aqiPoor;

  /// No description provided for @aqiVeryPoor.
  ///
  /// In en, this message translates to:
  /// **'Very poor'**
  String get aqiVeryPoor;

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'clear skies'**
  String get weatherClear;

  /// No description provided for @weatherClouds.
  ///
  /// In en, this message translates to:
  /// **'cloudy'**
  String get weatherClouds;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'rainy'**
  String get weatherRain;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'light rain'**
  String get weatherDrizzle;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'thunderstorms'**
  String get weatherThunderstorm;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'snowy'**
  String get weatherSnow;

  /// No description provided for @weatherAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'hazy'**
  String get weatherAtmosphere;

  /// No description provided for @weatherUnknown.
  ///
  /// In en, this message translates to:
  /// **'weather unavailable'**
  String get weatherUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
