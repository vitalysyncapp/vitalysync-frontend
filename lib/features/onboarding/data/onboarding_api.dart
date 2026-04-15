import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';

class OnboardingApi {
  static Future<Map<String, dynamic>> fetchSummary(int userId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.onboarding('/$userId')),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch onboarding summary');
    }

    return data;
  }

  static Future<Map<String, dynamic>> upsertOnboarding({
    required int userId,
    required Map<String, dynamic> onboarding,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.onboarding('/$userId')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(onboarding),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to save onboarding');
    }

    return data;
  }

  static Future<Map<String, dynamic>> upsertPreferences({
    required int userId,
    required Map<String, dynamic> preferences,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.onboarding('/$userId/preferences')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(preferences),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to save preferences');
    }

    return data;
  }
}
