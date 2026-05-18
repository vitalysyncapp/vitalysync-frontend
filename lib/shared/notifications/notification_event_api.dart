import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../preferences/user_session.dart';

class NotificationEventApi {
  static const Duration _requestTimeout = Duration(seconds: 8);

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
