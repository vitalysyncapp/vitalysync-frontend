import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/home/data/environment_localization.dart';
import 'package:vitalysync/features/home/data/environment_model.dart';
import 'package:vitalysync/features/settings/presentation/pages/app_preferences_page.dart';
import 'package:vitalysync/l10n/app_localizations.dart';
import 'package:vitalysync/l10n/l10n.dart';
import 'package:vitalysync/shared/config/api_config.dart';
import 'package:vitalysync/shared/localization/language_change_coordinator.dart';
import 'package:vitalysync/shared/localization/locale_sensitive_cache_service.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';
import 'package:vitalysync/shared/preferences/app_preferences.dart';

void main() {
  final preferences = AppPreferencesController.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await preferences.load();
  });

  test('English and Filipino ARB catalogs contain identical resources', () {
    final english =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final filipino =
        jsonDecode(File('lib/l10n/app_fil.arb').readAsStringSync())
            as Map<String, dynamic>;
    final englishKeys = english.keys
        .where((key) => !key.startsWith('@'))
        .toSet();
    final filipinoKeys = filipino.keys
        .where((key) => !key.startsWith('@'))
        .toSet();

    expect(filipinoKeys, englishKeys);
    for (final key in englishKeys) {
      expect((filipino[key] as String).trim(), isNotEmpty, reason: key);
    }
  });

  test(
    'legacy Filipino values migrate to canonical tagalog preference',
    () async {
      for (final legacyValue in ['filipino', 'fil', 'tl']) {
        SharedPreferences.setMockInitialValues({'app_language': legacyValue});
        await preferences.load();

        expect(preferences.notifier.value.language, AppLanguage.tagalog);
        expect(preferences.notifier.value.locale, const Locale('fil'));
        final stored = await SharedPreferences.getInstance();
        expect(stored.getString('app_language'), 'tagalog');
      }
    },
  );

  test(
    'selected language persists and survives session preference cleanup',
    () async {
      await preferences.updateLanguage(AppLanguage.tagalog);
      await preferences.load();
      expect(preferences.notifier.value.language, AppLanguage.tagalog);

      await preferences.resetToDefaults(preserveLanguage: true);
      await preferences.load();
      expect(preferences.notifier.value.language, AppLanguage.tagalog);
    },
  );

  test(
    'API headers use the canonical locale and accept legacy aliases',
    () async {
      for (final value in ['tagalog', 'filipino', 'fil', 'tl']) {
        SharedPreferences.setMockInitialValues({'app_language': value});
        expect((await ApiConfig.authHeaders())['Accept-Language'], 'fil');
      }

      SharedPreferences.setMockInitialValues({'app_language': 'english'});
      expect((await ApiConfig.authHeaders())['Accept-Language'], 'en');
    },
  );

  test('offline API caches are partitioned by locale', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'english'});
    await OfflineCacheStore.saveJson(
      namespace: 'locale_test',
      scope: 'user_1',
      data: {'copy': 'English'},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', 'tagalog');
    expect(
      await OfflineCacheStore.readLatestJson(
        namespace: 'locale_test',
        scope: 'user_1',
      ),
      isNull,
    );
    await OfflineCacheStore.saveJson(
      namespace: 'locale_test',
      scope: 'user_1',
      data: {'copy': 'Tagalog'},
    );

    await prefs.setString('app_language', 'english');
    expect(
      await OfflineCacheStore.readLatestJson(
        namespace: 'locale_test',
        scope: 'user_1',
      ),
      {'copy': 'English'},
    );
  });

  test('locale change invalidates generated copy caches only', () async {
    SharedPreferences.setMockInitialValues({
      'cached_environment_snapshot': 'old-weather',
      'nutrition_last_insight': 'old-insight',
      'overlay_preview_1': 'old-preview',
      'unrelated_preference': 'keep-me',
    });

    await LocaleSensitiveCacheService.invalidate();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('cached_environment_snapshot'), isFalse);
    expect(prefs.containsKey('nutrition_last_insight'), isFalse);
    expect(prefs.containsKey('overlay_preview_1'), isFalse);
    expect(prefs.getString('unrelated_preference'), 'keep-me');
  });

  testWidgets('language control updates its screen immediately', (
    tester,
  ) async {
    var cacheInvalidations = 0;
    var reminderRefreshes = 0;
    final coordinator = LanguageChangeCoordinator(
      invalidateCaches: () async => cacheInvalidations++,
      refreshReminders: () async => reminderRefreshes++,
      restartOverlay: (_) async {},
    );

    await tester.pumpWidget(
      ValueListenableBuilder<AppPreferencesState>(
        valueListenable: preferences.notifier,
        builder: (context, state, _) {
          return MaterialApp(
            locale: state.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: AppPreferencesPage(languageCoordinator: coordinator),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    await tester.tap(find.text('Tagalog'));
    await tester.pumpAndSettle();

    expect(find.text('Itsura'), findsOneWidget);
    expect(find.text('Wika ng app'), findsOneWidget);
    expect(find.text('Kasalukuyan: Tagalog'), findsOneWidget);
    expect(cacheInvalidations, 1);
    expect(reminderRefreshes, 1);
  });

  test(
    'background strings and environment codes localize without provider text',
    () async {
      final strings = await loadAppLocalizations(const Locale('fil'));
      const weather = EnvironmentWeather(
        conditionCode: 501,
        main: 'Rain',
        description: 'provider-owned English rain text',
        icon: '',
        temperatureC: 29,
        feelsLikeC: 31,
        humidity: 70,
        pressure: 1009,
        windSpeed: 2,
      );
      const airQuality = EnvironmentAirQuality(
        aqi: 4,
        aqiLabel: 'Poor',
        components: EnvironmentAirComponents(
          pm25: 1,
          pm10: 1,
          o3: 1,
          no2: 1,
          so2: 1,
          co: 1,
        ),
      );

      expect(strings.dailyCheckInNotificationBody, contains('I-log'));
      expect(weather.localizedDescription(strings), 'maulan');
      expect(airQuality.localizedLabel(strings), 'Mahina');
    },
  );
}
