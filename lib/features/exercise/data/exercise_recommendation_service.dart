import '../../activity/data/activity_service.dart';
import '../../adaptive/data/adaptive_nudge_api.dart';
import '../../dashboard/data/burnout_score_api.dart';
import '../../home/data/device_location_service.dart';
import '../../home/data/environment_api.dart';
import '../../home/data/environment_model.dart';
import '../../log/data/log_api.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../../../shared/offline/offline_cache_store.dart';
import 'exercise_goal_api.dart';
import 'exercise_goal_model.dart';
import 'exercise_recommendation_policy.dart';
import 'exercise_recommendation_model.dart';

class ExerciseRecommendationService {
  const ExerciseRecommendationService();
  static const String _recommendationsCache = 'exercise_recommendations';
  static const double _fallbackLatitude = 9.65;
  static const double _fallbackLongitude = 123.85;
  static const Duration _freshEnvironmentWindow = Duration(minutes: 45);

  Future<List<ExerciseRecommendationModel>> loadRecommendations() async {
    try {
      final recommendations = await _buildRecommendations();
      await _cacheRecommendations(recommendations);
      return recommendations;
    } catch (_) {
      final cached = await _readCachedRecommendations();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<EnvironmentSnapshot?> loadEnvironmentSnapshot() async {
    final cached = await EnvironmentApi.loadCachedSnapshot();
    final now = DateTime.now();
    if (cached != null) {
      final age = now.difference(cached.fetchedAt.toLocal());
      if (!age.isNegative && age < _freshEnvironmentWindow) {
        return cached;
      }
    }

    try {
      final coordinates = await DeviceLocationService.getCurrentCoordinates();
      return await EnvironmentApi.fetchEnvironment(
        lat: coordinates?.latitude ?? _fallbackLatitude,
        lon: coordinates?.longitude ?? _fallbackLongitude,
      );
    } catch (_) {
      return cached;
    }
  }

  Future<List<ExerciseRecommendationModel>> _buildRecommendations() async {
    final defaults = await OnboardingService.loadDefaults();
    final environment = await loadEnvironmentSnapshot();
    final activity = ActivityService.instance.notifier.value.log;
    final burnoutSummary = await _safeBurnoutPatternSummary();
    final adaptiveNudges = await _safeAdaptiveNudges();
    final latestLog = await _safeLatestLog();
    final goalHistory = await _safeExerciseGoalHistory();
    final latestSleep = LogApi.parseDouble(latestLog?['sleep_hours']);
    final sleepHours = latestSleep > 0 ? latestSleep : defaults.sleepHours();
    final recommendedFocus = _recommendedFocus(
      burnoutSummary: burnoutSummary,
      adaptiveNudges: adaptiveNudges,
    );
    final baselineLevel = defaults.initialBurnoutLevel?.trim().toLowerCase();
    final highStress =
        baselineLevel == 'high' ||
        baselineLevel == 'very high' ||
        defaults.burnoutScoreForDisplay >= 45 ||
        (defaults.workloadLevel ?? 0) >= 4 ||
        _hasHighBurnoutRisk(burnoutSummary) ||
        _hasHighPriorityNudge(adaptiveNudges);
    final weatherCondition = _outdoorCondition(environment);
    final airSafe = _isAirSafe(environment);
    final weatherReason = airSafe
        ? weatherCondition.reason
        : 'Air quality is elevated; indoor movement is safer today.';
    final needsRecovery =
        sleepHours < 6 ||
        highStress ||
        _focusSuggestsRecovery(recommendedFocus);
    final steps = activity.steps;

    final policyResult = ExerciseRecommendationPolicy.buildRecommendations(
      ExerciseRecommendationPolicyContext(
        lifestyleType: defaults.lifestyleType,
        exerciseGoalDays: defaults.exerciseGoalDays,
        steps: steps,
        needsRecovery: needsRecovery,
        outdoorSafe: weatherCondition.isOutdoorSafe,
        gentleOutdoor: weatherCondition.needsGentleOutdoor,
        airSafe: airSafe,
        weatherReason: weatherReason,
        history: ExerciseRecommendationPolicy.summarizeGoalHistory(goalHistory),
      ),
    );

    return policyResult.recommendations;
  }

  Future<void> _cacheRecommendations(
    List<ExerciseRecommendationModel> recommendations,
  ) async {
    await OfflineCacheStore.saveJson(
      namespace: _recommendationsCache,
      scope: await _cacheScope(),
      data: {
        'recommendations': recommendations
            .map((item) => item.toJson())
            .toList(),
      },
    );
  }

  Future<List<ExerciseRecommendationModel>> _readCachedRecommendations() async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _recommendationsCache,
      scope: await _cacheScope(),
    );
    final rawRecommendations = data?['recommendations'];
    if (rawRecommendations is! List) {
      return const [];
    }

    return rawRecommendations
        .whereType<Map>()
        .map(
          (item) => ExerciseRecommendationModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<String> _cacheScope() async {
    return (await LogApi.getStoredUserId())?.toString() ?? 'guest';
  }

  Future<BurnoutPatternSummary?> _safeBurnoutPatternSummary() async {
    try {
      return await BurnoutScoreApi.fetchPatternSummary();
    } catch (_) {
      return null;
    }
  }

  Future<List<AdaptiveNudgeRecommendation>> _safeAdaptiveNudges() async {
    try {
      final response = await AdaptiveNudgeApi.fetchRecommendations(
        limit: 2,
        record: false,
        ai: false,
      );
      return response.recommendations;
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _safeLatestLog() async {
    try {
      final response = await LogApi.fetchLatestLog();
      final log = response['log'];
      return log is Map ? Map<String, dynamic>.from(log) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ExerciseGoalModel>> _safeExerciseGoalHistory() async {
    try {
      final userId = await LogApi.getStoredUserId();
      if (userId == null || userId <= 0) {
        return const [];
      }

      final today = _dateKey(DateTime.now());
      final start = _dateKey(DateTime.now().subtract(const Duration(days: 28)));
      return await ExerciseGoalApi.fetchHistory(
        userId: userId,
        startDate: start,
        endDate: today,
      );
    } catch (_) {
      return const [];
    }
  }

  bool _isAirSafe(EnvironmentSnapshot? snapshot) {
    if (snapshot == null) {
      return true;
    }

    final aqi = snapshot.airQuality.aqi;
    return aqi == 0 || aqi <= 3;
  }

  _OutdoorCondition _outdoorCondition(EnvironmentSnapshot? snapshot) {
    if (snapshot == null) {
      return const _OutdoorCondition(
        isOutdoorSafe: true,
        needsGentleOutdoor: false,
        reason: 'No live weather snapshot is available yet.',
      );
    }

    final main = snapshot.weather.main.toLowerCase();
    final windSpeed = snapshot.weather.windSpeed;
    final temp = snapshot.weather.temperatureC;
    final badWeather =
        main.contains('rain') ||
        main.contains('thunder') ||
        main.contains('storm') ||
        main.contains('snow');
    if (badWeather) {
      return _OutdoorCondition(
        isOutdoorSafe: false,
        needsGentleOutdoor: false,
        reason:
            'Weather shows ${snapshot.weather.description}; indoor movement is safer today.',
      );
    }

    if (windSpeed >= 10 || temp < 18 || temp > 34) {
      return _OutdoorCondition(
        isOutdoorSafe: false,
        needsGentleOutdoor: false,
        reason:
            'Temperature or wind is outside the safe outdoor range right now.',
      );
    }

    final needsGentleOutdoor =
        windSpeed >= 7 || temp < 20 || temp > 31 || main.contains('cloud');
    return _OutdoorCondition(
      isOutdoorSafe: true,
      needsGentleOutdoor: needsGentleOutdoor,
      reason: needsGentleOutdoor
          ? 'Outdoor conditions are usable, but better for light movement.'
          : 'Weather looks safe for outdoor movement.',
    );
  }

  bool _hasHighBurnoutRisk(BurnoutPatternSummary? summary) {
    final risk = summary?.latestScore?.riskLevel.toLowerCase() ?? '';
    final priority = summary?.adaptiveState.priority.toLowerCase() ?? '';
    return risk == 'high' || priority == 'high' || priority == 'urgent';
  }

  bool _hasHighPriorityNudge(List<AdaptiveNudgeRecommendation> nudges) {
    return nudges.any((nudge) {
      final priority = nudge.priority.toLowerCase();
      return priority == 'high' || priority == 'urgent';
    });
  }

  String _recommendedFocus({
    required BurnoutPatternSummary? burnoutSummary,
    required List<AdaptiveNudgeRecommendation> adaptiveNudges,
  }) {
    if (adaptiveNudges.isNotEmpty) {
      return adaptiveNudges.first.recommendedFocus.toLowerCase();
    }

    return burnoutSummary?.adaptiveState.recommendedFocus.toLowerCase() ?? '';
  }

  bool _focusSuggestsRecovery(String focus) {
    return focus.contains('recovery') ||
        focus.contains('load_reduction') ||
        focus.contains('stabilize') ||
        focus.contains('support');
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _OutdoorCondition {
  final bool isOutdoorSafe;
  final bool needsGentleOutdoor;
  final String reason;

  const _OutdoorCondition({
    required this.isOutdoorSafe,
    required this.needsGentleOutdoor,
    required this.reason,
  });
}
