import 'package:shared_preferences/shared_preferences.dart';

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

  static String burnout(String path) => '$baseUrl/api/burnout$path';

  static String logs(String path) => '$baseUrl/api/logs$path';

  static String nutrition(String path) => '$baseUrl/api/nutrition$path';

  static String onboarding(String path) => '$baseUrl/api/onboarding$path';

  static String profile(String path) => '$baseUrl/api/profile$path';

  static String streaks(String path) => '$baseUrl/api/streaks$path';

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

  static String goals(String path) => '$baseUrl/api/goals$path';

  static Future<Map<String, String>> jsonHeaders() async {
    return {'Content-Type': 'application/json', ...await authHeaders()};
  }

  static Future<Map<String, String>> acceptJsonHeaders() async {
    return {'Accept': 'application/json', ...await authHeaders()};
  }

  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_access_token')?.trim();

    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return {'Authorization': 'Bearer $token'};
  }
}
