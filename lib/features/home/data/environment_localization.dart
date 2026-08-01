import '../../../l10n/app_localizations.dart';
import 'environment_model.dart';

extension EnvironmentWeatherLocalization on EnvironmentWeather {
  String localizedDescription(AppLocalizations l10n) {
    final code = conditionCode;
    if (code >= 200 && code < 300) return l10n.weatherThunderstorm;
    if (code >= 300 && code < 400) return l10n.weatherDrizzle;
    if (code >= 500 && code < 600) return l10n.weatherRain;
    if (code >= 600 && code < 700) return l10n.weatherSnow;
    if (code >= 700 && code < 800) return l10n.weatherAtmosphere;
    if (code == 800) return l10n.weatherClear;
    if (code > 800 && code < 900) return l10n.weatherClouds;

    return switch (main.toLowerCase()) {
      'clear' => l10n.weatherClear,
      'clouds' => l10n.weatherClouds,
      'rain' => l10n.weatherRain,
      'drizzle' => l10n.weatherDrizzle,
      'thunderstorm' => l10n.weatherThunderstorm,
      'snow' => l10n.weatherSnow,
      'mist' ||
      'smoke' ||
      'haze' ||
      'dust' ||
      'fog' ||
      'sand' ||
      'ash' => l10n.weatherAtmosphere,
      _ => l10n.weatherUnknown,
    };
  }
}

extension EnvironmentAirQualityLocalization on EnvironmentAirQuality {
  String localizedLabel(AppLocalizations l10n) {
    return switch (aqi) {
      1 => l10n.aqiGood,
      2 => l10n.aqiFair,
      3 => l10n.aqiModerate,
      4 => l10n.aqiPoor,
      5 => l10n.aqiVeryPoor,
      _ => l10n.unknownValue,
    };
  }
}
