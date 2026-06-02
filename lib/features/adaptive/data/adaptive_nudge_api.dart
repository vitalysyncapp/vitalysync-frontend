import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/offline_cache_store.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'nudge_event_id': nudgeEventId,
      'nudge_type': nudgeType,
      'priority': priority,
      'title': title,
      'message': message,
      'action_label': actionLabel,
      'trigger_reason': triggerReason,
      'recommended_focus': recommendedFocus,
      'pattern_type': patternType,
      'severity': severity,
      'confidence_score': confidenceScore,
      'metadata': metadata,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations
          .map((recommendation) => recommendation.toJson())
          .toList(),
      'adaptive_state': adaptiveState,
      'patterns': patterns,
    };
  }
}

class AdaptiveNudgeEvent {
  final int nudgeEventId;
  final int userId;
  final String nudgeType;
  final String? triggerReason;
  final String message;
  final String? actionLabel;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime? actedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdaptiveNudgeEvent({
    required this.nudgeEventId,
    required this.userId,
    required this.nudgeType,
    required this.triggerReason,
    required this.message,
    required this.actionLabel,
    required this.status,
    required this.metadata,
    required this.actedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdaptiveNudgeEvent.fromJson(Map<String, dynamic> json) {
    return AdaptiveNudgeEvent(
      nudgeEventId: _parseInt(json['nudge_event_id']),
      userId: _parseInt(json['user_id']),
      nudgeType: json['nudge_type']?.toString() ?? 'smart_nudge',
      triggerReason: json['trigger_reason']?.toString(),
      message: json['message']?.toString() ?? '',
      actionLabel: json['action_label']?.toString(),
      status: json['status']?.toString() ?? 'shown',
      metadata: _parseMetadata(json['metadata']),
      actedAt: _parseNullableDate(json['acted_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get title {
    final rawTitle = metadata['title']?.toString().trim() ?? '';
    if (rawTitle.isNotEmpty) {
      return rawTitle;
    }

    return 'Smart nudge';
  }
}

class AdaptiveNudgeApi {
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Duration _aiRequestTimeout = Duration(seconds: 25);
  static const Duration _assistantCacheMaxAge = Duration(minutes: 30);
  static const String _recommendationsCache = 'adaptive_nudge_recommendations';
  static const String _assistantRecommendationsCache =
      'assistant_nudge_recommendations';
  static const String _nudgeFeedbackCache = 'assistant_nudge_feedback';

  static Future<AdaptiveNudgeResponse> fetchRecommendations({
    int limit = 3,
    bool record = true,
    bool ai = true,
  }) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return await _fallbackResponse();
    }

    try {
      final uri = Uri.parse(ApiConfig.adaptive('/nudges/recommendations'))
          .replace(
            queryParameters: {
              'user_id': userId.toString(),
              'limit': limit.toString(),
              'record': record.toString(),
              'ai': ai.toString(),
            },
          );
      final response = await http
          .get(uri, headers: await ApiConfig.jsonHeaders())
          .timeout(ai ? _aiRequestTimeout : _requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        final fallback = await _fallbackResponse();
        return await _readCachedRecommendations(userId, ai: ai) ??
            (ai ? await _readCachedRecommendations(userId, ai: false) : null) ??
            fallback;
      }

      final parsedResponse = AdaptiveNudgeResponse.fromJson(data);
      if (ai && !_hasAiEnhancedRecommendation(parsedResponse)) {
        final cachedAi = await _readCachedRecommendations(userId, ai: true);
        if (cachedAi != null && _hasAiEnhancedRecommendation(cachedAi)) {
          await OfflineCacheStore.saveJson(
            namespace: _recommendationsCache,
            scope: _cacheScope(userId, ai: false),
            data: data,
          );
          return cachedAi;
        }
      }

      await OfflineCacheStore.saveJson(
        namespace: _recommendationsCache,
        scope: _cacheScope(
          userId,
          ai: ai && _hasAiEnhancedRecommendation(parsedResponse),
        ),
        data: data,
      );
      return parsedResponse;
    } catch (_) {
      final fallback = await _fallbackResponse();
      return await _readCachedRecommendations(userId, ai: ai) ??
          (ai ? await _readCachedRecommendations(userId, ai: false) : null) ??
          fallback;
    }
  }

  static Future<AdaptiveNudgeResponse> fetchAssistantRecommendations({
    int limit = 3,
    bool forceRefresh = false,
  }) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return await _fallbackResponse();
    }

    final scope = _assistantCacheScope(userId);
    OfflineCachedJson? cachedSnapshot;
    if (!forceRefresh) {
      cachedSnapshot = await OfflineCacheStore.readLatestJsonSnapshot(
        namespace: _assistantRecommendationsCache,
        scope: scope,
      );
      if (cachedSnapshot != null &&
          cachedSnapshot.isFresh(_assistantCacheMaxAge)) {
        return AdaptiveNudgeResponse.fromJson(cachedSnapshot.data);
      }
    }

    final response = await fetchRecommendations(limit: limit);
    if (!forceRefresh &&
        cachedSnapshot != null &&
        _isLocalFallbackResponse(response)) {
      return AdaptiveNudgeResponse.fromJson(cachedSnapshot.data);
    }

    await OfflineCacheStore.saveJson(
      namespace: _assistantRecommendationsCache,
      scope: scope,
      data: response.toJson(),
    );
    return response;
  }

  static Future<void> updateNudgeStatus({
    required int eventId,
    required String status,
  }) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return;
    }

    final response = await http
        .put(
          Uri.parse(ApiConfig.adaptive('/nudge-events/$eventId/status')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({'user_id': userId, 'status': status}),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final data = _decodeResponseMap(response);
      throw Exception(data['message'] ?? 'Failed to update nudge status');
    }
  }

  static Future<void> saveNudgeFeedback({
    required AdaptiveNudgeRecommendation recommendation,
    required String status,
  }) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return;
    }

    await _cacheNudgeFeedback(userId, recommendation, status);
    await _updateCachedRecommendationStatus(userId, recommendation, status);

    final eventId = recommendation.nudgeEventId;
    if (eventId != null) {
      await updateNudgeStatus(eventId: eventId, status: status);
      return;
    }

    await createInsightFeedback(
      nudgeType: recommendation.nudgeType,
      title: recommendation.title,
      message: recommendation.message,
      status: status,
      triggerReason: recommendation.triggerReason,
      actionLabel: recommendation.actionLabel,
      metadata: {
        ...recommendation.metadata,
        'assistant_feedback_status': status,
      },
    );
  }

  static Future<void> createInsightFeedback({
    required String nudgeType,
    required String title,
    required String message,
    required String status,
    String? triggerReason,
    String? actionLabel,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return;
    }

    final response = await http
        .post(
          Uri.parse(ApiConfig.adaptive('/nudge-events')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({
            'user_id': userId,
            'nudge_type': nudgeType,
            'trigger_reason': triggerReason,
            'message': message,
            'action_label': actionLabel,
            'status': status,
            'metadata': {
              ...metadata,
              'title': title,
              'assistant_feedback_status': status,
            },
          }),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = _decodeResponseMap(response);
      throw Exception(data['message'] ?? 'Failed to save insight feedback');
    }
  }

  static Future<List<AdaptiveNudgeEvent>> listNudgeEvents({
    int limit = 30,
  }) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return const [];
    }

    try {
      final uri = Uri.parse(ApiConfig.adaptive('/nudge-events')).replace(
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
            (item) =>
                AdaptiveNudgeEvent.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> readNudgeFeedbackStatus(
    AdaptiveNudgeRecommendation recommendation,
  ) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return null;
    }

    final data = await OfflineCacheStore.readLatestJson(
      namespace: _nudgeFeedbackCache,
      scope: _feedbackScope(userId, recommendation),
    );
    return data?['status']?.toString();
  }

  static Future<int?> _storedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
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

  static Future<AdaptiveNudgeResponse?> _readCachedRecommendations(
    int userId, {
    bool ai = true,
  }) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _recommendationsCache,
      scope: _cacheScope(userId, ai: ai),
    );
    if (data == null) {
      return null;
    }

    return AdaptiveNudgeResponse.fromJson(data);
  }

  static String _cacheScope(int userId, {required bool ai}) {
    return '${userId}_${ai ? 'ai' : 'rules'}';
  }

  static String _assistantCacheScope(int userId) {
    return '${userId}_${_dateKey(DateTime.now())}';
  }

  static String _feedbackScope(
    int userId,
    AdaptiveNudgeRecommendation recommendation,
  ) {
    return '${userId}_${_recommendationKey(recommendation)}';
  }

  static String _recommendationKey(AdaptiveNudgeRecommendation recommendation) {
    final raw = recommendation.nudgeEventId != null
        ? 'event_${recommendation.nudgeEventId}'
        : [
            recommendation.nudgeType,
            recommendation.title,
            recommendation.message,
          ].join('_');
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static Future<void> _cacheNudgeFeedback(
    int userId,
    AdaptiveNudgeRecommendation recommendation,
    String status,
  ) {
    return OfflineCacheStore.saveJson(
      namespace: _nudgeFeedbackCache,
      scope: _feedbackScope(userId, recommendation),
      data: {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        'nudge_event_id': recommendation.nudgeEventId,
        'nudge_type': recommendation.nudgeType,
      },
    );
  }

  static Future<void> _updateCachedRecommendationStatus(
    int userId,
    AdaptiveNudgeRecommendation recommendation,
    String status,
  ) async {
    final scopes = [
      _cacheScope(userId, ai: true),
      _cacheScope(userId, ai: false),
      _assistantCacheScope(userId),
    ];

    for (final scope in scopes) {
      final namespace = scope == _assistantCacheScope(userId)
          ? _assistantRecommendationsCache
          : _recommendationsCache;
      final data = await OfflineCacheStore.readLatestJson(
        namespace: namespace,
        scope: scope,
      );
      if (data == null || data['recommendations'] is! List) {
        continue;
      }

      final recommendations = (data['recommendations'] as List)
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : item)
          .toList();
      var changed = false;

      for (var index = 0; index < recommendations.length; index++) {
        final item = recommendations[index];
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final cachedRecommendation = AdaptiveNudgeRecommendation.fromJson(item);
        if (_recommendationKey(cachedRecommendation) !=
            _recommendationKey(recommendation)) {
          continue;
        }

        final metadata = _parseMetadata(item['metadata']);
        item['metadata'] = {...metadata, 'assistant_feedback_status': status};
        recommendations[index] = item;
        changed = true;
      }

      if (!changed) {
        continue;
      }

      await OfflineCacheStore.saveJson(
        namespace: namespace,
        scope: scope,
        data: {...data, 'recommendations': recommendations},
      );
    }
  }

  static bool _hasAiEnhancedRecommendation(AdaptiveNudgeResponse response) {
    return response.recommendations.any(
      (recommendation) => recommendation.metadata['ai_enhanced'] == true,
    );
  }

  static bool _isLocalFallbackResponse(AdaptiveNudgeResponse response) {
    return response.recommendations.isNotEmpty &&
        response.recommendations.every(
          (recommendation) =>
              recommendation.metadata['local_fallback'] == true ||
              recommendation.triggerReason == 'Local fallback',
        );
  }

  static Future<AdaptiveNudgeResponse> _fallbackResponse() async {
    final username = await _storedUsername();
    final displayName = username == null ? null : _displayName(username);
    final prefix = displayName == null ? '' : '$displayName, ';
    final metadata = <String, dynamic>{
      'local_fallback': true,
      'ai_fallback': true,
    };
    if (displayName != null) {
      metadata['user_display_name'] = displayName;
    }

    return AdaptiveNudgeResponse(
      recommendations: [
        AdaptiveNudgeRecommendation(
          nudgeEventId: null,
          nudgeType: 'steady_routine',
          priority: 'low',
          title: 'Keep today steady',
          message:
              '${prefix}use one small reset today: hydrate, pause briefly, and keep a clear stop time.',
          actionLabel: 'Continue',
          triggerReason: 'Local fallback',
          recommendedFocus: 'maintenance',
          patternType: null,
          severity: 'low',
          confidenceScore: 0,
          metadata: metadata,
        ),
      ],
      adaptiveState: <String, dynamic>{},
      patterns: <Map<String, dynamic>>[],
    );
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Future<String?> _storedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username')?.trim();
    return username?.isNotEmpty == true ? username : null;
  }

  static String _displayName(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length <= 36 ? normalized : normalized.substring(0, 36);
  }
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
