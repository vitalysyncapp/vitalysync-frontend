import 'package:flutter/material.dart';

import '../shared/preferences/app_preferences.dart';
import 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension PreferenceLocalization on AppLocalizations {
  String languageLabel(AppLanguage language) {
    return switch (language) {
      AppLanguage.english => englishLanguage,
      AppLanguage.tagalog => tagalogLanguage,
    };
  }

  String fontSizeLabel(AppFontSize size) {
    return switch (size) {
      AppFontSize.small => smallSize,
      AppFontSize.medium => mediumSize,
      AppFontSize.large => largeSize,
    };
  }
}

Future<AppLocalizations> loadAppLocalizations(Locale locale) {
  return AppLocalizations.delegate.load(locale);
}
