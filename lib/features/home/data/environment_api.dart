import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import '../../../shared/preferences/user_session.dart';
import 'environment_model.dart';

class EnvironmentApi {
  static Future<EnvironmentSnapshot> fetchEnvironment({
    required double lat,
    required double lon,
  }) async {
    final session = await UserSessionController.instance.load();
    final userId = session.isDemoMode ? null : session.userId;
    final uri = Uri.parse(
      ApiConfig.environment(lat: lat, lon: lon, userId: userId),
    );
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    Map<String, dynamic> data = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ??
            'Failed to fetch environment snapshot (${response.statusCode}) from $uri',
      );
    }

    return EnvironmentSnapshot.fromJson(data);
  }
}
