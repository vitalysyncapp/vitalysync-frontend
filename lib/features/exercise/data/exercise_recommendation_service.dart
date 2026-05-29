import '../../activity/data/activity_service.dart';
import '../../adaptive/data/adaptive_nudge_api.dart';
import '../../dashboard/data/burnout_score_api.dart';
import '../../home/data/device_location_service.dart';
import '../../home/data/environment_api.dart';
import '../../home/data/environment_model.dart';
import '../../log/data/log_api.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../../../shared/offline/offline_cache_store.dart';
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
    final needsRecovery =
        sleepHours < 6 ||
        highStress ||
        _focusSuggestsRecovery(recommendedFocus);
    final steps = activity.steps;

    final recommendations = <ExerciseRecommendationModel>[];

    if (!weatherCondition.isOutdoorSafe || !airSafe) {
      recommendations.addAll(
        _indoorRecommendations(reason: weatherCondition.reason),
      );
    } else if (weatherCondition.needsGentleOutdoor) {
      recommendations.addAll(_gentleWeatherRecommendations());
      if (needsRecovery) {
        recommendations.addAll(_recoveryRecommendations());
      }
    } else if (needsRecovery) {
      recommendations.addAll(_recoveryRecommendations());
    } else if (steps < 3500) {
      recommendations.addAll(_lowStepRecommendations());
    } else if (steps >= 9000) {
      recommendations.addAll(_highStepRecommendations());
    } else {
      recommendations.addAll(_balancedRecommendations());
    }

    final unique = <String, ExerciseRecommendationModel>{};
    for (final item in recommendations) {
      unique[item.exerciseName] = item;
    }

    unique['None today'] = const ExerciseRecommendationModel(
      exerciseName: 'None today',
      exerciseCategory: 'none',
      targetDistanceMeters: null,
      targetMinutes: null,
      targetReps: null,
      completionMethod: 'none',
      reason: 'Save an intentional rest day instead of skipping by accident.',
    );

    return unique.values.take(5).toList();
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

  List<ExerciseRecommendationModel> _recoveryRecommendations() {
    return const [
      ExerciseRecommendationModel(
        exerciseName: 'Light stretching',
        exerciseCategory: 'stretching',
        targetDistanceMeters: null,
        targetMinutes: 10,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'A low-pressure reset when sleep or stress needs gentleness.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Breathing exercise',
        exerciseCategory: 'breathing',
        targetDistanceMeters: null,
        targetMinutes: 5,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'Helps downshift stress without adding physical load.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Short walk',
        exerciseCategory: 'walking',
        targetDistanceMeters: 800,
        targetMinutes: 10,
        targetReps: null,
        completionMethod: 'distance',
        reason: 'A light walk can support mood without pushing too hard.',
      ),
    ];
  }

  List<ExerciseRecommendationModel> _lowStepRecommendations() {
    return const [
      ExerciseRecommendationModel(
        exerciseName: 'Walk',
        exerciseCategory: 'walking',
        targetDistanceMeters: 1200,
        targetMinutes: 15,
        targetReps: null,
        completionMethod: 'distance',
        reason: 'Your steps are low, and conditions look safe for movement.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Easy jog',
        exerciseCategory: 'jogging',
        targetDistanceMeters: 1000,
        targetMinutes: 10,
        targetReps: null,
        completionMethod: 'distance',
        reason: 'A short jog can lift energy when the day has been still.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Light run',
        exerciseCategory: 'running',
        targetDistanceMeters: 1200,
        targetMinutes: 10,
        targetReps: null,
        completionMethod: 'distance',
        reason:
            'A short run fits when weather, stress, and recovery look okay.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Yoga flow',
        exerciseCategory: 'yoga',
        targetDistanceMeters: null,
        targetMinutes: 12,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'A calm indoor option if you want less impact.',
      ),
    ];
  }

  List<ExerciseRecommendationModel> _highStepRecommendations() {
    return const [
      ExerciseRecommendationModel(
        exerciseName: 'Recovery stretching',
        exerciseCategory: 'stretching',
        targetDistanceMeters: null,
        targetMinutes: 8,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'You already moved a lot today; recovery keeps it sustainable.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Breathing exercise',
        exerciseCategory: 'breathing',
        targetDistanceMeters: null,
        targetMinutes: 5,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'Finish the day with a short nervous-system reset.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Gentle yoga',
        exerciseCategory: 'yoga',
        targetDistanceMeters: null,
        targetMinutes: 10,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'Mobility work balances a high-step day.',
      ),
    ];
  }

  List<ExerciseRecommendationModel> _indoorRecommendations({String? reason}) {
    return [
      ExerciseRecommendationModel(
        exerciseName: 'Indoor bodyweight',
        exerciseCategory: 'bodyweight',
        targetDistanceMeters: null,
        targetMinutes: 12,
        targetReps: 20,
        completionMethod: 'manual',
        reason: reason ?? 'Weather or air quality suggests staying indoors.',
      ),
      const ExerciseRecommendationModel(
        exerciseName: 'Yoga flow',
        exerciseCategory: 'yoga',
        targetDistanceMeters: null,
        targetMinutes: 12,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'A joint-friendly indoor movement session.',
      ),
      const ExerciseRecommendationModel(
        exerciseName: 'Breathing exercise',
        exerciseCategory: 'breathing',
        targetDistanceMeters: null,
        targetMinutes: 5,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'A safe indoor option when outdoor conditions are poor.',
      ),
    ];
  }

  List<ExerciseRecommendationModel> _gentleWeatherRecommendations() {
    return const [
      ExerciseRecommendationModel(
        exerciseName: 'Short walk',
        exerciseCategory: 'walking',
        targetDistanceMeters: 700,
        targetMinutes: 8,
        targetReps: null,
        completionMethod: 'distance',
        reason: 'Weather is acceptable, but light movement is the better fit.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Light stretching',
        exerciseCategory: 'stretching',
        targetDistanceMeters: null,
        targetMinutes: 10,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'Keeps the plan gentle when conditions are not ideal.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Yoga flow',
        exerciseCategory: 'yoga',
        targetDistanceMeters: null,
        targetMinutes: 12,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'A controlled indoor option if outdoor movement feels off.',
      ),
    ];
  }

  List<ExerciseRecommendationModel> _balancedRecommendations() {
    return const [
      ExerciseRecommendationModel(
        exerciseName: 'Walk',
        exerciseCategory: 'walking',
        targetDistanceMeters: 1000,
        targetMinutes: 12,
        targetReps: null,
        completionMethod: 'distance',
        reason: 'A moderate walk keeps your rhythm steady.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Light stretching',
        exerciseCategory: 'stretching',
        targetDistanceMeters: null,
        targetMinutes: 10,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'Good for recovery and posture after a normal day.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Bodyweight circuit',
        exerciseCategory: 'bodyweight',
        targetDistanceMeters: null,
        targetMinutes: 10,
        targetReps: 20,
        completionMethod: 'manual',
        reason: 'A compact strength option without equipment.',
      ),
    ];
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
