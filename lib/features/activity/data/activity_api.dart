import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import 'activity_log.dart';

class ActivityApi {
  static const Duration _requestTimeout = Duration(seconds: 8);

  static Future<ActivityLog?> fetchToday({
    required int userId,
    required String logDate,
  }) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.activity('/today/$userId')}?date=$logDate'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(_requestTimeout);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200) {
      throw ActivityApiException(
        data['message']?.toString() ?? 'Failed to fetch activity log',
        response.statusCode,
      );
    }

    final log = data['log'];
    if (log is Map) {
      return ActivityLog.fromJson(Map<String, dynamic>.from(log));
    }

    return null;
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
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.activity('/history/$userId')}?start=$startDate&end=$endDate',
          ),
          headers: {'Accept': 'application/json'},
        )
        .timeout(_requestTimeout);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200) {
      throw ActivityApiException(
        data['message']?.toString() ?? 'Failed to fetch activity history',
        response.statusCode,
      );
    }

    final logs = data['logs'];
    if (logs is! List) {
      return const [];
    }

    return logs
        .whereType<Map>()
        .map((item) => ActivityLog.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<ActivityLog> _upsert({
    required String method,
    required String url,
    required int userId,
    required ActivityLog log,
  }) async {
    final request = http.Request(method, Uri.parse(url))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      })
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
    if (savedLog is Map) {
      return ActivityLog.fromJson(Map<String, dynamic>.from(savedLog));
    }

    return log;
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
