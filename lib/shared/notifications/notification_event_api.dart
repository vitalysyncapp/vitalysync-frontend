import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../offline/fetch_policy.dart';
import '../preferences/user_session.dart';

class NotificationEventRecord {
  final int notificationEventId;
  final int userId;
  final String notificationType;
  final String title;
  final String body;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationEventRecord({
    required this.notificationEventId,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.scheduledFor,
    required this.sentAt,
    required this.status,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationEventRecord.fromJson(Map<String, dynamic> json) {
    return NotificationEventRecord(
      notificationEventId: _parseInt(json['notification_event_id']),
      userId: _parseInt(json['user_id']),
      notificationType: json['notification_type']?.toString() ?? 'reminder',
      title: json['title']?.toString() ?? 'Reminder',
      body: json['body']?.toString() ?? '',
      scheduledFor: _parseNullableDate(json['scheduled_for']),
      sentAt: _parseNullableDate(json['sent_at']),
      status: json['status']?.toString() ?? 'scheduled',
      metadata: _mapFromJson(json['metadata']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class NotificationEventApi {
  static const Duration _requestTimeout = ApiRequestTimeouts.fastRead;

  static Future<void> createEvent({
    required String notificationType,
    required String title,
    required String body,
    DateTime? scheduledFor,
    DateTime? sentAt,
    required String status,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      return;
    }

    final response = await http
        .post(
          Uri.parse(ApiConfig.adaptive('/notification-events')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({
            'user_id': userId,
            'notification_type': notificationType,
            'title': title,
            'body': body,
            'scheduled_for': scheduledFor?.toIso8601String(),
            'sent_at': sentAt?.toIso8601String(),
            'status': status,
            'metadata': metadata,
          }),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 201 && response.statusCode != 200) {
      final data = _decodeResponseMap(response);
      throw Exception(data['message'] ?? 'Failed to save notification event');
    }
  }

  static Future<List<NotificationEventRecord>> listEvents({
    int limit = 30,
  }) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      return const [];
    }

    try {
      final uri = Uri.parse(ApiConfig.adaptive('/notification-events')).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'limit': limit.toString(),
        },
      );
      final response = await http
          .get(uri, headers: await ApiConfig.jsonHeaders())
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);
      if (response.statusCode != 200) {
        return const [];
      }

      return (data['events'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NotificationEventRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Map<String, dynamic> _decodeResponseMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return const {};
    }

    return const {};
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _parseNullableDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

Map<String, dynamic> _mapFromJson(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}
