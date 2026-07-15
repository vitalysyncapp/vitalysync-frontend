import 'dart:async';
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
        throw StreakApiException.fromResponse(
          data,
          response.statusCode,
          fallbackMessage: 'Failed to fetch streak overview',
        );
      }

      await OfflineCacheStore.saveJson(
        namespace: _overviewCache,
        scope: userId.toString(),
        data: data,
      );
      return StreakOverview.fromJson(data);
    } catch (error) {
      final cached = await OfflineCacheStore.readLatestJson(
        namespace: _overviewCache,
        scope: userId.toString(),
      );
      if (cached != null && _canUseOfflineFallback(error)) {
        return StreakOverview.fromJson(cached, isOffline: true);
      }

      throw _normalizeError(
        error,
        fallbackMessage: 'Unable to load your streak right now.',
      );
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
        throw StreakApiException.fromResponse(
          data,
          response.statusCode,
          fallbackMessage: 'Failed to fetch leaderboard',
        );
      }

      await OfflineCacheStore.saveJson(
        namespace: _leaderboardCache,
        scope: cacheScope,
        data: data,
      );
      return StreakLeaderboard.fromJson(data);
    } catch (error) {
      final cached = await OfflineCacheStore.readLatestJson(
        namespace: _leaderboardCache,
        scope: cacheScope,
      );
      if (cached != null && _canUseOfflineFallback(error)) {
        return StreakLeaderboard.fromJson(cached);
      }

      throw _normalizeError(
        error,
        fallbackMessage: 'Unable to load streak rankings right now.',
      );
    }
  }

  static bool _canUseOfflineFallback(Object error) {
    if (error is StreakApiException) {
      return error.canUseOfflineFallback;
    }

    return true;
  }

  static StreakApiException _normalizeError(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is StreakApiException) {
      return error;
    }

    if (error is TimeoutException) {
      return StreakApiException(
        'The VitalySync API took too long to respond. Try again in a moment.',
        isNetworkError: true,
      );
    }

    if (error is http.ClientException) {
      return StreakApiException(
        'Unable to reach the VitalySync API right now.',
        isNetworkError: true,
      );
    }

    return StreakApiException(fallbackMessage);
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

class StreakApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const StreakApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  factory StreakApiException.fromResponse(
    Map<String, dynamic> data,
    int statusCode, {
    required String fallbackMessage,
  }) {
    final serverMessage = data['message']?.toString().trim();

    final message = switch (statusCode) {
      401 => 'Your session expired. Please sign in again.',
      403 =>
        'This account cannot access that streak data. Please sign in again.',
      _ => serverMessage?.isNotEmpty == true ? serverMessage! : fallbackMessage,
    };

    return StreakApiException(message, statusCode: statusCode);
  }

  bool get canUseOfflineFallback {
    final status = statusCode;
    if (isNetworkError || status == null) {
      return true;
    }

    return status == 408 || status == 429 || status >= 500;
  }

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}
