class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    return 'https://vitalysync-backend.onrender.com';
  }

  static String auth(String path) => '$baseUrl/api/auth$path';

  static String activity(String path) => '$baseUrl/api/activity$path';

  static String adaptive(String path) => '$baseUrl/api/adaptive$path';

  static String logs(String path) => '$baseUrl/api/logs$path';

  static String nutrition(String path) => '$baseUrl/api/nutrition$path';

  static String onboarding(String path) => '$baseUrl/api/onboarding$path';

  static String profile(String path) => '$baseUrl/api/profile$path';

  static String environment({
    required double lat,
    required double lon,
    int? userId,
  }) {
    final userIdQuery = userId == null ? '' : '&user_id=$userId';
    return '$baseUrl/api/environment?lat=$lat&lon=$lon$userIdQuery';
  }

  static String exerciseGoals(String path) {
    return '$baseUrl/api/exercise-goals$path';
  }
}
