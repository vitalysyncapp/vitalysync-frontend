import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/preferences/user_session.dart';
import 'environment_model.dart';

class EnvironmentApi {
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxAttempts = 2;
  static const String _cachedSnapshotKey = 'cached_environment_snapshot';

  static Future<EnvironmentSnapshot> fetchEnvironment({
    required double lat,
    required double lon,
  }) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    final uri = Uri.parse(
      ApiConfig.environment(lat: lat, lon: lon, userId: userId),
    );

    Object? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await http
            .get(uri, headers: await ApiConfig.jsonHeaders())
            .timeout(_requestTimeout);

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

        final snapshot = EnvironmentSnapshot.fromJson(data);
        await cacheSnapshot(snapshot);
        return snapshot;
      } catch (error) {
        lastError = error;
        if (attempt == _maxAttempts) {
          rethrow;
        }
      }
    }

    throw Exception(
      'Failed to fetch environment snapshot from $uri: $lastError',
    );
  }

  static Future<void> cacheSnapshot(EnvironmentSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedSnapshotKey, jsonEncode(snapshot.toJson()));
  }

  static Future<EnvironmentSnapshot?> loadCachedSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSnapshot = prefs.getString(_cachedSnapshotKey);
    if (rawSnapshot == null || rawSnapshot.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSnapshot);
      if (decoded is Map<String, dynamic>) {
        return EnvironmentSnapshot.fromJson(decoded);
      }
    } catch (_) {
      await prefs.remove(_cachedSnapshotKey);
    }

    return null;
  }
}
