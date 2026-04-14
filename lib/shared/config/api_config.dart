class ApiConfig {
  static const String baseUrl = 'https://vitalysync-backend.onrender.com';

  static String auth(String path) => '$baseUrl/api/auth$path';

  static String logs(String path) => '$baseUrl/api/logs$path';
}
