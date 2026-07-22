import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/fetch_policy.dart';
import '../../../shared/offline/offline_cache_store.dart';
import '../../dashboard/data/burnout_score_api.dart';
import 'activity_log.dart';

class ActivityApi {
  static const Duration _requestTimeout = ApiRequestTimeouts.fastRead;
  static const String _todayCache = 'activity_today';
  static const String _historyCache = 'activity_history';

  static Future<ActivityLog?> fetchToday({
    required int userId,
    required String logDate,
    bool forceRefresh = false,
  }) async {
    final cachedSnapshot = await OfflineCacheStore.readLatestJsonSnapshot(
      namespace: _todayCache,
      scope: _todayScope(userId, logDate),
    );
    final cachedLog = cachedSnapshot?.data['log'];
    if (!forceRefresh &&
        cachedLog is Map &&
        cachedSnapshot?.isFresh(FetchPolicy.perMinute.maxAge) == true) {
      return ActivityLog.fromJson(Map<String, dynamic>.from(cachedLog));
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.activity('/today/$userId')}?date=$logDate'),
            headers: await ApiConfig.acceptJsonHeaders(),
          )
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        return await _readCachedToday(userId, logDate) ??
            (throw ActivityApiException(
              data['message']?.toString() ?? 'Failed to fetch activity log',
              response.statusCode,
            ));
      }

      final log = data['log'];
      if (log is Map) {
        final logMap = Map<String, dynamic>.from(log);
        await OfflineCacheStore.saveJson(
          namespace: _todayCache,
          scope: _todayScope(userId, logDate),
          data: {'log': logMap},
        );
        return ActivityLog.fromJson(logMap);
      }

      return null;
    } catch (_) {
      return _readCachedToday(userId, logDate);
    }
  }

  static Future<ActivityLog> save({
    required int userId,
    required ActivityLog log,
  }) {
    return _upsert(
      method: 'POST',
      url: ApiConfig.activity('/save'),
      userId: userId,
      log: log,
    );
  }

  static Future<ActivityLog> update({
    required int userId,
    required ActivityLog log,
  }) {
    return _upsert(
      method: 'PUT',
      url: ApiConfig.activity('/update'),
      userId: userId,
      log: log,
    );
  }

  static Future<List<ActivityLog>> fetchHistory({
    required int userId,
    required String startDate,
    required String endDate,
    bool forceRefresh = false,
  }) async {
    final cachedSnapshot = await OfflineCacheStore.readLatestJsonSnapshot(
      namespace: _historyCache,
      scope: _historyScope(userId, startDate, endDate),
    );
    if (!forceRefresh &&
        cachedSnapshot?.isFresh(FetchPolicy.fiveMinutes.maxAge) == true) {
      return _parseLogs(
        cachedSnapshot!.data['logs'] as List<dynamic>? ?? const [],
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.activity('/history/$userId')}?start=$startDate&end=$endDate',
            ),
            headers: await ApiConfig.acceptJsonHeaders(),
          )
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        return await _readCachedHistory(userId, startDate, endDate);
      }

      final logs = data['logs'];
      if (logs is! List) {
        return const [];
      }

      await OfflineCacheStore.saveJson(
        namespace: _historyCache,
        scope: _historyScope(userId, startDate, endDate),
        data: {'logs': logs},
      );
      return _parseLogs(logs);
    } catch (_) {
      return _readCachedHistory(userId, startDate, endDate);
    }
  }

  static Future<ActivityLog> _upsert({
    required String method,
    required String url,
    required int userId,
    required ActivityLog log,
  }) async {
    final request = http.Request(method, Uri.parse(url))
      ..headers.addAll(await ApiConfig.jsonHeaders())
      ..body = jsonEncode({'user_id': userId, ...log.toJson()});

    final streamedResponse = await request.send().timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ActivityApiException(
        data['message']?.toString() ?? 'Failed to save activity log',
        response.statusCode,
      );
    }

    final savedLog = data['log'];
    final burnoutScore = data['burnout_score'];
    if (burnoutScore is Map) {
      await BurnoutScoreApi.markInputsChanged(
        latestScore: Map<String, dynamic>.from(burnoutScore),
      );
    }

    if (savedLog is Map) {
      final logMap = Map<String, dynamic>.from(savedLog);
      await OfflineCacheStore.saveJson(
        namespace: _todayCache,
        scope: _todayScope(userId, log.logDate),
        data: {'log': logMap},
      );
      await OfflineCacheStore.removeNamespace(namespace: _historyCache);
      return ActivityLog.fromJson(logMap);
    }

    await OfflineCacheStore.saveJson(
      namespace: _todayCache,
      scope: _todayScope(userId, log.logDate),
      data: {'log': log.toJson()},
    );
    await OfflineCacheStore.removeNamespace(namespace: _historyCache);
    return log;
  }

  static Future<ActivityLog?> _readCachedToday(
    int userId,
    String logDate,
  ) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _todayCache,
      scope: _todayScope(userId, logDate),
    );
    final log = data?['log'];
    if (log is! Map) {
      return null;
    }

    return ActivityLog.fromJson(Map<String, dynamic>.from(log));
  }

  static Future<List<ActivityLog>> _readCachedHistory(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _historyCache,
      scope: _historyScope(userId, startDate, endDate),
    );
    final logs = data?['logs'];
    if (logs is! List) {
      return const [];
    }

    return _parseLogs(logs);
  }

  static List<ActivityLog> _parseLogs(List<dynamic> logs) {
    return logs
        .whereType<Map>()
        .map((item) => ActivityLog.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static String _todayScope(int userId, String logDate) {
    return '${userId}_$logDate';
  }

  static String _historyScope(int userId, String startDate, String endDate) {
    return '${userId}_${startDate}_$endDate';
  }

  static Map<String, dynamic> _decodeResponseMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Fall through to a readable fallback message.
    }

    return {'message': response.reasonPhrase ?? 'Unexpected server response'};
  }
}

class ActivityApiException implements Exception {
  final String message;
  final int statusCode;

  const ActivityApiException(this.message, this.statusCode);

  bool get canQueueForLater => statusCode >= 500;

  bool get canUseOfflineFallback => statusCode >= 500;

  @override
  String toString() => message;
}
