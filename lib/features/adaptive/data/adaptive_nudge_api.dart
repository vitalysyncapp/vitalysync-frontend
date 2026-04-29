import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/preferences/user_session.dart';

class AdaptiveNudgeRecommendation {
  final int? nudgeEventId;
  final String nudgeType;
  final String priority;
  final String title;
  final String message;
  final String actionLabel;
  final String triggerReason;
  final String recommendedFocus;
  final String? patternType;
  final String? severity;
  final int confidenceScore;
  final Map<String, dynamic> metadata;

  const AdaptiveNudgeRecommendation({
    required this.nudgeEventId,
    required this.nudgeType,
    required this.priority,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.triggerReason,
    required this.recommendedFocus,
    required this.patternType,
    required this.severity,
    required this.confidenceScore,
    required this.metadata,
  });

  factory AdaptiveNudgeRecommendation.fromJson(Map<String, dynamic> json) {
    return AdaptiveNudgeRecommendation(
      nudgeEventId: _parseNullableInt(json['nudge_event_id']),
      nudgeType: json['nudge_type']?.toString() ?? 'steady_routine',
      priority: json['priority']?.toString() ?? 'low',
      title: json['title']?.toString() ?? 'Smart nudge',
      message: json['message']?.toString() ?? '',
      actionLabel: json['action_label']?.toString() ?? 'Continue',
      triggerReason: json['trigger_reason']?.toString() ?? '',
      recommendedFocus: json['recommended_focus']?.toString() ?? 'maintenance',
      patternType: json['pattern_type']?.toString(),
      severity: json['severity']?.toString(),
      confidenceScore: _parseInt(json['confidence_score']),
      metadata: _parseMetadata(json['metadata']),
    );
  }
}

class AdaptiveNudgeResponse {
  final List<AdaptiveNudgeRecommendation> recommendations;
  final Map<String, dynamic> adaptiveState;
  final List<Map<String, dynamic>> patterns;

  const AdaptiveNudgeResponse({
    required this.recommendations,
    required this.adaptiveState,
    required this.patterns,
  });

  factory AdaptiveNudgeResponse.fromJson(Map<String, dynamic> json) {
    return AdaptiveNudgeResponse(
      recommendations: (json['recommendations'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AdaptiveNudgeRecommendation.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      adaptiveState: json['adaptive_state'] is Map
          ? Map<String, dynamic>.from(json['adaptive_state'] as Map)
          : const <String, dynamic>{},
      patterns: (json['patterns'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }
}

class AdaptiveNudgeApi {
  static const Duration _requestTimeout = Duration(seconds: 8);

  static Future<AdaptiveNudgeResponse> fetchRecommendations({
    int limit = 3,
    bool record = true,
  }) async {
    if (await _isDemoMode()) {
      return _demoResponse();
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return _fallbackResponse();
    }

    final uri = Uri.parse(ApiConfig.adaptive('/nudges/recommendations'))
        .replace(
          queryParameters: {
            'user_id': userId.toString(),
            'limit': limit.toString(),
            'record': record.toString(),
          },
        );
    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(_requestTimeout);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200) {
      return _fallbackResponse();
    }

    return AdaptiveNudgeResponse.fromJson(data);
  }

  static Future<void> updateNudgeStatus({
    required int eventId,
    required String status,
  }) async {
    if (await _isDemoMode()) {
      return;
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return;
    }

    final response = await http
        .put(
          Uri.parse(ApiConfig.adaptive('/nudge-events/$eventId/status')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'status': status}),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final data = _decodeResponseMap(response);
      throw Exception(data['message'] ?? 'Failed to update nudge status');
    }
  }

  static Future<int?> _storedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<bool> _isDemoMode() async {
    final session = await UserSessionController.instance.load();
    return session.isDemoMode;
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

  static AdaptiveNudgeResponse _fallbackResponse() {
    return const AdaptiveNudgeResponse(
      recommendations: [
        AdaptiveNudgeRecommendation(
          nudgeEventId: null,
          nudgeType: 'steady_routine',
          priority: 'low',
          title: 'Keep today steady',
          message:
              'Use one small reset today: hydrate, pause briefly, and keep a clear stop time.',
          actionLabel: 'Continue',
          triggerReason: 'Local fallback',
          recommendedFocus: 'maintenance',
          patternType: null,
          severity: 'low',
          confidenceScore: 0,
          metadata: <String, dynamic>{},
        ),
      ],
      adaptiveState: <String, dynamic>{},
      patterns: <Map<String, dynamic>>[],
    );
  }

  static AdaptiveNudgeResponse _demoResponse() {
    return const AdaptiveNudgeResponse(
      recommendations: [
        AdaptiveNudgeRecommendation(
          nudgeEventId: null,
          nudgeType: 'recovery_break',
          priority: 'medium',
          title: 'Balance load with recovery',
          message:
              'Demo patterns suggest a short recovery break before the next demanding task.',
          actionLabel: 'Schedule break',
          triggerReason: 'Demo adaptive pattern',
          recommendedFocus: 'recovery',
          patternType: 'workload_recovery_mismatch',
          severity: 'moderate',
          confidenceScore: 76,
          metadata: <String, dynamic>{},
        ),
      ],
      adaptiveState: <String, dynamic>{},
      patterns: <Map<String, dynamic>>[],
    );
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

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  final parsed = _parseInt(value);
  return parsed > 0 ? parsed : null;
}

Map<String, dynamic> _parseMetadata(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}
