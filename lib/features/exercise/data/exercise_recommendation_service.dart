import '../../activity/data/activity_service.dart';
import '../../home/data/environment_api.dart';
import '../../home/data/environment_model.dart';
import '../../log/data/log_api.dart';
import '../../onboarding/services/onboarding_service.dart';
import 'exercise_recommendation_model.dart';

class ExerciseRecommendationService {
  const ExerciseRecommendationService();

  Future<List<ExerciseRecommendationModel>> loadRecommendations() async {
    final defaults = await OnboardingService.loadDefaults();
    final activity = ActivityService.instance.notifier.value.log;
    final environment = await EnvironmentApi.loadCachedSnapshot();
    final latestLog = await _safeLatestLog();
    final latestSleep = LogApi.parseDouble(latestLog?['sleep_hours']);
    final sleepHours = latestSleep > 0 ? latestSleep : defaults.sleepHours();
    final highStress =
        defaults.initialBurnoutLevel == 'High' ||
        defaults.burnoutScoreForDisplay >= 70 ||
        (defaults.workloadLevel ?? 0) >= 4;
    final weatherSafe = _isWeatherSafe(environment);
    final airSafe = _isAirSafe(environment);
    final steps = activity.steps;

    final recommendations = <ExerciseRecommendationModel>[];

    if (!weatherSafe || !airSafe) {
      recommendations.addAll(_indoorRecommendations());
    } else if (sleepHours < 6 || highStress) {
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

  bool _isWeatherSafe(EnvironmentSnapshot? snapshot) {
    if (snapshot == null) {
      return true;
    }

    final main = snapshot.weather.main.toLowerCase();
    final windSpeed = snapshot.weather.windSpeed;
    final temp = snapshot.weather.temperatureC;
    final badWeather =
        main.contains('rain') ||
        main.contains('thunder') ||
        main.contains('storm') ||
        main.contains('snow');

    return !badWeather && windSpeed < 10 && temp >= 18 && temp <= 34;
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

  List<ExerciseRecommendationModel> _indoorRecommendations() {
    return const [
      ExerciseRecommendationModel(
        exerciseName: 'Indoor bodyweight',
        exerciseCategory: 'bodyweight',
        targetDistanceMeters: null,
        targetMinutes: 12,
        targetReps: 20,
        completionMethod: 'manual',
        reason: 'Weather or air quality suggests staying indoors.',
      ),
      ExerciseRecommendationModel(
        exerciseName: 'Yoga flow',
        exerciseCategory: 'yoga',
        targetDistanceMeters: null,
        targetMinutes: 12,
        targetReps: null,
        completionMethod: 'manual',
        reason: 'A joint-friendly indoor movement session.',
      ),
      ExerciseRecommendationModel(
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
