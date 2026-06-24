import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/offline_cache_store.dart';
import '../../../shared/preferences/user_session.dart';
import 'streak_models.dart';

class StreakApi {
  StreakApi._();

  static const Duration _requestTimeout = Duration(seconds: 12);
  static const String _overviewCache = 'streak_overview';
  static const String _leaderboardCache = 'streak_leaderboard';

  static Future<StreakOverview> fetchOverview() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.streaks('/$userId')),
            headers: await ApiConfig.acceptJsonHeaders(),
          )
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to fetch streak overview');
      }

      await OfflineCacheStore.saveJson(
        namespace: _overviewCache,
        scope: userId.toString(),
        data: data,
      );
      return StreakOverview.fromJson(data);
    } catch (_) {
      final cached = await OfflineCacheStore.readLatestJson(
        namespace: _overviewCache,
        scope: userId.toString(),
      );
      if (cached != null) {
        return StreakOverview.fromJson(cached, isOffline: true);
      }

      rethrow;
    }
  }

  static Future<StreakLeaderboard> fetchLeaderboard({
    required String section,
    required String metric,
  }) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null) {
      throw Exception('Missing logged-in user');
    }

    final cacheScope = '$userId-$section-$metric';

    try {
      final uri = Uri.parse(ApiConfig.streaks('/$userId/leaderboard')).replace(
        queryParameters: {'section': section, 'metric': metric, 'limit': '50'},
      );
      final response = await http
          .get(uri, headers: await ApiConfig.acceptJsonHeaders())
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to fetch leaderboard');
      }

      await OfflineCacheStore.saveJson(
        namespace: _leaderboardCache,
        scope: cacheScope,
        data: data,
      );
      return StreakLeaderboard.fromJson(data);
    } catch (_) {
      final cached = await OfflineCacheStore.readLatestJson(
        namespace: _leaderboardCache,
        scope: cacheScope,
      );
      if (cached != null) {
        return StreakLeaderboard.fromJson(cached);
      }

      rethrow;
    }
  }

  static Map<String, dynamic> _decodeResponseMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Fall through to readable fallback.
    }

    return {'message': response.reasonPhrase ?? 'Unexpected server response'};
  }
}
