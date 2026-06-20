import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';

class OnboardingApi {
  static Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  static Future<Map<String, dynamic>> fetchSummary(int userId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.onboarding('/$userId')),
      headers: await ApiConfig.jsonHeaders(),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch onboarding summary');
    }

    return data;
  }

  static Future<Map<String, dynamic>> fetchStatus(int userId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.onboarding('/status/$userId')),
      headers: await ApiConfig.jsonHeaders(),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch onboarding status');
    }

    return data;
  }

  static Future<Map<String, dynamic>> submitRequiredOnboarding({
    required int userId,
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> burnoutAnswers,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.onboarding('/submit')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({
        'user_id': userId,
        'profile': profile,
        'burnout_answers': burnoutAnswers,
      }),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to submit onboarding');
    }

    return data;
  }

  static Future<Map<String, dynamic>> fetchProfile(int userId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.profile('/$userId')),
      headers: await ApiConfig.jsonHeaders(),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch profile');
    }

    return data;
  }

  static Future<Map<String, dynamic>> upsertOnboarding({
    required int userId,
    required Map<String, dynamic> onboarding,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.onboarding('/$userId')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode(onboarding),
    );

    final data = _decodeMap(response);
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
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode(preferences),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to save preferences');
    }

    return data;
  }

  static Future<Map<String, dynamic>> updateWellnessProfile({
    required int userId,
    required Map<String, dynamic> profile,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.onboarding('/$userId/wellness-profile')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode(profile),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to save wellness profile');
    }

    return data;
  }

  static Future<Map<String, dynamic>> updateBurnoutBaseline({
    required int userId,
    required List<Map<String, dynamic>> burnoutAnswers,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.onboarding('/$userId/burnout-baseline')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({'burnout_answers': burnoutAnswers}),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to save burnout baseline');
    }

    return data;
  }
}
