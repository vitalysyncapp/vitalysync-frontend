import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../offline/fetch_policy.dart';
import 'user_session.dart';

/// API client for server-persisted user privacy settings.
///
/// Currently handles the leaderboard opt-out flag. The server stores this in
/// `user_settings` so the leaderboard query can exclude hidden users globally.
class UserSettingsApi {
  UserSettingsApi._();

  static const Duration _requestTimeout = ApiRequestTimeouts.standard;

  /// Fetches the user's current settings from the server.
  static Future<UserSettingsSnapshot> fetchSettings() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/settings/$userId'),
          headers: await ApiConfig.acceptJsonHeaders(),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final data = _decode(response.body);
      throw Exception(data['message'] ?? 'Failed to fetch settings');
    }

    return UserSettingsSnapshot.fromJson(_decode(response.body));
  }

  /// Updates the leaderboard opt-out flag on the server.
  ///
  /// Returns the updated settings snapshot on success. Throws on error.
  static Future<UserSettingsSnapshot> updateHideFromLeaderboard(
    bool value,
  ) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final response = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/api/settings/$userId'),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({'hide_from_leaderboard': value}),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final data = _decode(response.body);
      throw Exception(data['message'] ?? 'Failed to update settings');
    }

    return UserSettingsSnapshot.fromJson(_decode(response.body));
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Fall through.
    }

    return const <String, dynamic>{};
  }
}

/// Immutable snapshot of the server-side user settings.
@immutable
class UserSettingsSnapshot {
  final bool hideFromLeaderboard;

  const UserSettingsSnapshot({required this.hideFromLeaderboard});

  factory UserSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    return UserSettingsSnapshot(
      hideFromLeaderboard: json['hide_from_leaderboard'] == true,
    );
  }

  static const defaults = UserSettingsSnapshot(hideFromLeaderboard: false);
}
