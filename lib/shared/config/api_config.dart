import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:3000';
      }

      return 'http://127.0.0.1:3000';
    }

    return 'https://vitalysync-backend.onrender.com';
  }

  static String auth(String path) => '$baseUrl/api/auth$path';

  static String logs(String path) => '$baseUrl/api/logs$path';

  static String onboarding(String path) => '$baseUrl/api/onboarding$path';

  static String environment({
    required double lat,
    required double lon,
    int? userId,
  }) {
    final userIdQuery = userId == null ? '' : '&user_id=$userId';
    return '$baseUrl/api/environment?lat=$lat&lon=$lon$userIdQuery';
  }
}
