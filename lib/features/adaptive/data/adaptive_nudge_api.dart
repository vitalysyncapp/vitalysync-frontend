import 'dart:async';
import 'nudge_selection.dart';
import '../../../shared/notifications/smart_nudge_delivery_service.dart';
import 'dart:convert';
import 'wellness_content_api.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/config/api_config.dart';
import '../../../shared/preferences/app_preferences.dart';
import '../../../shared/offline/fetch_policy.dart';
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

  String get userFacingSeverity {
    final value = (severity ?? priority).trim().toLowerCase().replaceAll(
      RegExp(r'[-\s]+'),
      '_',
    );
    switch (value) {
      case 'critical':
      case 'urgent':
      case 'needs_support':
        return 'needs support';
      case 'high_risk':
      case 'high':
        return 'high';
      case 'watch':
      case 'moderate':
      case 'medium':
        return 'watch';
      default:
        return 'steady';
    }
  }

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
  final Map<String, dynamic> selection;

  const AdaptiveNudgeResponse({
    required this.recommendations,
    required this.adaptiveState,
    required this.patterns,
    this.selection = const {},
  });

  factory AdaptiveNudgeResponse.fromJson(Map<String, dynamic> json) {
    return AdaptiveNudgeResponse(
      selection: Map<String, dynamic>.from(json['selection'] as Map? ?? {}),
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
      'selection': selection,
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
  static final Map<String, Future<AdaptiveNudgeResponse>> _assistantRequests =
      {};
  static const Duration _requestTimeout = ApiRequestTimeouts.fastRead;
  static const Duration _aiRequestTimeout = ApiRequestTimeouts.coldStart;
  static const String _recommendationsCache = 'adaptive_nudge_recommendations';
  static const String _assistantRecommendationsCache =
      'assistant_nudge_recommendations';
  static const String _nudgeFeedbackCache = 'assistant_nudge_feedback';

  static Future<AdaptiveNudgeResponse> fetchRecommendations({
    int limit = 3,
    bool record = false,
    bool ai = true,
    bool strict = false,
    bool delivery = false,
    String selectionMode = 'default',
    List<String> excludeActionIds = const [],
  }) async {
    final revision = WellnessContentApi.revision;
    final sessionKey = await WellnessContentApi.sessionKey();
    final userId = await _storedUserId();
    if (userId == null) {
      if (strict) throw Exception('Please sign in to request another idea');
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
              'delivery': delivery.toString(),
              'selection_mode': selectionMode,
              'exclude_action_ids': excludeActionIds.join(','),
            },
          );
      final response = await http
          .get(uri, headers: await ApiConfig.jsonHeaders())
          .timeout(ai ? _aiRequestTimeout : _requestTimeout);
      final data = _decodeResponseMap(response);
      await OfflineCacheStore.reload();
      if (await WellnessContentApi.sessionKey() != sessionKey) {
        if (strict) throw Exception('The active account or language changed');
        return const AdaptiveNudgeResponse(
          recommendations: [],
          adaptiveState: {},
          patterns: [],
        );
      }
      if (revision != WellnessContentApi.revision) {
        throw Exception('Guidance changed during this request');
      }

      if (response.statusCode != 200) {
        if (strict) throw Exception('Unable to load another idea');
        final fallback = await _fallbackResponse();
        return await _readCachedRecommendations(userId, ai: ai) ??
            (ai ? await _readCachedRecommendations(userId, ai: false) : null) ??
            fallback;
      }

      final parsedResponse = AdaptiveNudgeResponse.fromJson(data);
      await OfflineCacheStore.saveJson(
        namespace: _recommendationsCache,
        scope: _cacheScope(userId, ai: ai),
        data: data,
      );
      return parsedResponse;
    } catch (_) {
      if (strict) rethrow;
      if (await WellnessContentApi.sessionKey() != sessionKey ||
          revision != WellnessContentApi.revision) {
        return const AdaptiveNudgeResponse(
          recommendations: [],
          adaptiveState: {},
          patterns: [],
        );
      }
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
    await OfflineCacheStore.reload();
    final key =
        '${await WellnessContentApi.sessionKey()}_${WellnessContentApi.revision}_${limit}_$forceRefresh';
    final pending = _assistantRequests[key];
    if (pending != null) return pending;
    final request = _fetchAssistantRecommendations(
      limit: limit,
      forceRefresh: forceRefresh,
    );
    _assistantRequests[key] = request;
    try {
      return await request;
    } finally {
      _assistantRequests.remove(key);
    }
  }

  static Future<AdaptiveNudgeResponse> _fetchAssistantRecommendations({
    int limit = 3,
    bool forceRefresh = false,
  }) async {
    final sessionKey = await WellnessContentApi.sessionKey();
    final revision = WellnessContentApi.revision;
    final userId = await _storedUserId();
    if (userId == null) {
      return await _fallbackResponse();
    }

    final scope = _assistantCacheScope(userId);
    final cachedSnapshot = await OfflineCacheStore.readLatestJsonSnapshot(
      namespace: _assistantRecommendationsCache,
      scope: scope,
    );
    if (!forceRefresh) {
      if (cachedSnapshot != null && _assistantNudgeIsCurrent(cachedSnapshot)) {
        final cached = AdaptiveNudgeResponse.fromJson(cachedSnapshot.data);
        if (cached.recommendations.isNotEmpty) {
          unawaited(
            SmartNudgeDeliveryService.instance.deliver(
              cached.recommendations.first.toJson(),
              expectedUserId: userId,
            ),
          );
        }
        return cached;
      }
    }

    final response = await fetchRecommendations(
      limit: limit,
      delivery: true,
      selectionMode: forceRefresh ? 'next' : 'default',
    );
    if (await WellnessContentApi.sessionKey() != sessionKey ||
        revision != WellnessContentApi.revision) {
      return const AdaptiveNudgeResponse(
        recommendations: [],
        adaptiveState: {},
        patterns: [],
      );
    }
    // A failed refresh must not replace the last real nudge or restart its clock.
    if (_isLocalFallbackResponse(response) ||
        response.recommendations.any(
          (item) => item.metadata['offline_cached'] == true,
        ) ||
        response.recommendations.isEmpty) {
      return cachedSnapshot != null
          ? AdaptiveNudgeResponse.fromJson(cachedSnapshot.data)
          : response;
    }
    if (response.recommendations.isNotEmpty) {
      unawaited(
        SmartNudgeDeliveryService.instance.deliver(
          response.recommendations.first.toJson(),
          expectedUserId: userId,
        ),
      );
    }
    await OfflineCacheStore.saveJson(
      namespace: _assistantRecommendationsCache,
      scope: scope,
      data: response.toJson(),
    );
    return response;
  }

  static Future<NudgeSelection<AdaptiveNudgeRecommendation>> anotherIdea({
    required List<String> excludeActionIds,
    String selectionMode = 'next',
  }) async {
    final userId = await _storedUserId();
    final sessionKey = await WellnessContentApi.sessionKey();
    final response = await fetchRecommendations(
      limit: 1,
      strict: true,
      delivery: true,
      selectionMode: selectionMode,
      excludeActionIds: excludeActionIds,
    );
    final item = response.recommendations.firstOrNull;
    if (!['available', 'exhausted'].contains(response.selection['status'])) {
      throw Exception('Unable to confirm a replacement');
    }
    if (item != null) {
      if (excludeActionIds.contains(item.metadata['action_id']) ||
          item.metadata['local_fallback'] == true) {
        throw Exception('A different idea is not available yet');
      }
      if (userId == null ||
          await WellnessContentApi.sessionKey() != sessionKey) {
        throw Exception('The active account or language changed');
      }
      await OfflineCacheStore.saveJson(
        namespace: _assistantRecommendationsCache,
        scope: _assistantCacheScope(userId),
        data: response.toJson(),
      );
      unawaited(
        SmartNudgeDeliveryService.instance.deliver(
          item.toJson(),
          expectedUserId: userId,
        ),
      );
    }
    return NudgeSelection(
      item: item,
      canRevisit: response.selection['can_revisit'] == true,
    );
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

    if (recommendation.metadata['content_id'] != null) {
      await WellnessContentApi.respond(
        recommendation.toJson(),
        switch (status) {
          'accepted' => 'like',
          'dismissed' => 'dislike',
          _ => status,
        },
      );
      if (status == 'accepted' || status == 'dismissed') {
        await _cacheNudgeFeedback(userId, recommendation, status);
      }
      return;
    }

    final eventId = recommendation.nudgeEventId;
    if (eventId != null) {
      await updateNudgeStatus(eventId: eventId, status: status);
      await _cacheNudgeFeedback(userId, recommendation, status);
      await _updateCachedRecommendationStatus(userId, recommendation, status);
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
    await _cacheNudgeFeedback(userId, recommendation, status);
    await _updateCachedRecommendationStatus(userId, recommendation, status);
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

  static Future<void> recordProductEvent({
    required String eventName,
    required String eventKey,
    Map<String, dynamic> dimensions = const <String, dynamic>{},
  }) async {
    final userId = await _storedUserId();
    if (userId == null) return;

    try {
      await http
          .post(
            Uri.parse(ApiConfig.adaptive('/product-events')),
            headers: await ApiConfig.jsonHeaders(),
            body: jsonEncode({
              'user_id': userId,
              'event_name': eventName,
              'event_key': eventKey,
              'dimensions': dimensions,
            }),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      // Rollout telemetry is best-effort and must never block wellness flows.
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
    if (recommendation.metadata['content_id'] != null) {
      final event = await WellnessContentApi.savedEvent(
        recommendation.toJson(),
      );
      final details = event == null
          ? recommendation.metadata
          : WellnessContentApi.metadata(event);
      if (details['completed_at'] != null) return 'done';
      final snoozedUntil = DateTime.tryParse('${details['snoozed_until']}');
      if (snoozedUntil?.isAfter(DateTime.now()) == true) return 'not_now';
      return switch (details['helpfulness']) {
        'like' => 'accepted',
        'dislike' => 'dismissed',
        _ => null,
      };
    }
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
    final snapshot = await OfflineCacheStore.readLatestJsonSnapshot(
      namespace: _recommendationsCache,
      scope: _cacheScope(userId, ai: ai),
    );
    if (snapshot == null) {
      return null;
    }
    final data = snapshot.data;
    return AdaptiveNudgeResponse.fromJson({
      ...data,
      'recommendations': [
        for (final item in (data['recommendations'] as List? ?? []))
          if (item is Map)
            {
              ...item,
              'metadata': {
                ...Map<String, dynamic>.from(item['metadata'] as Map? ?? {}),
                'offline_cached': true,
                'cached_at': snapshot.cachedAt?.toIso8601String(),
              },
            },
      ],
    });
  }

  static Future<AdaptiveNudgeRecommendation?> fetchPersonalInsight() async {
    final revision = WellnessContentApi.revision;
    final sessionKey = await WellnessContentApi.sessionKey();
    final userId = await _storedUserId();
    if (userId == null) return null;
    final date = _dateKey(DateTime.now());
    final scope = '${sessionKey}_${date}_weekly_paragraph_v1';
    try {
      final uri = Uri.parse(ApiConfig.adaptive('/personal-insight')).replace(
        queryParameters: {'user_id': '$userId', 'ai': 'true', 'date': date},
      );
      final response = await http
          .get(uri, headers: await ApiConfig.jsonHeaders())
          .timeout(_aiRequestTimeout);
      if (response.statusCode != 200) throw Exception('Insight unavailable');
      final data = _decodeResponseMap(response);
      await OfflineCacheStore.reload();
      if (await WellnessContentApi.sessionKey() != sessionKey) return null;
      if (revision != WellnessContentApi.revision) return null;
      await OfflineCacheStore.saveJson(
        namespace: 'personal_insight',
        scope: scope,
        data: data,
      );
      return data['insight'] is Map
          ? AdaptiveNudgeRecommendation.fromJson(
              Map<String, dynamic>.from(data['insight']),
            )
          : null;
    } catch (_) {
      if (await WellnessContentApi.sessionKey() != sessionKey ||
          revision != WellnessContentApi.revision) {
        return null;
      }
      final snapshot = await OfflineCacheStore.readLatestJsonSnapshot(
        namespace: 'personal_insight',
        scope: scope,
      );
      final raw = snapshot?.data['insight'];
      if (raw is! Map) return null;
      return AdaptiveNudgeRecommendation.fromJson({
        ...Map<String, dynamic>.from(raw),
        'metadata': {
          ...Map<String, dynamic>.from(raw['metadata'] as Map? ?? {}),
          'offline_cached': true,
          'cached_at': snapshot?.cachedAt?.toIso8601String(),
        },
      });
    }
  }

  static String _cacheScope(int userId, {required bool ai}) {
    return '${userId}_${ai ? 'ai' : 'rules'}_companion_v2';
  }

  static String _assistantCacheScope(int userId) {
    return '${userId}_persistent_v1';
  }

  static bool _assistantNudgeIsCurrent(OfflineCachedJson snapshot) {
    final response = AdaptiveNudgeResponse.fromJson(snapshot.data);
    final item = response.recommendations.firstOrNull;
    if (item == null || _isLocalFallbackResponse(response)) return false;
    final metadata = item.metadata;
    final due = DateTime.tryParse('${metadata['next_due_at']}');
    if (due != null) return DateTime.now().isBefore(due);
    final generatedAt =
        DateTime.tryParse('${metadata['generated_at']}') ?? snapshot.cachedAt;
    if (generatedAt == null) return false;
    final hours = num.tryParse('${metadata['nudge_cooldown_hours']}') ?? 8;
    return DateTime.now().isBefore(
      generatedAt.add(Duration(minutes: (hours.clamp(1, 48) * 60).round())),
    );
  }

  static String _feedbackScope(
    int userId,
    AdaptiveNudgeRecommendation recommendation,
  ) {
    return '${userId}_${_recommendationKey(recommendation)}';
  }

  static String _recommendationKey(AdaptiveNudgeRecommendation recommendation) {
    final raw =
        recommendation.metadata['content_id']?.toString() ??
        (recommendation.nudgeEventId != null
            ? 'event_${recommendation.nudgeEventId}'
            : [
                recommendation.nudgeType,
                recommendation.title,
                recommendation.message,
              ].join('_'));
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

  static bool _isLocalFallbackResponse(AdaptiveNudgeResponse response) {
    return response.recommendations.isNotEmpty &&
        response.recommendations.every(
          (recommendation) =>
              recommendation.metadata['local_fallback'] == true ||
              recommendation.triggerReason == 'Local fallback',
        );
  }

  static Future<AdaptiveNudgeResponse> _fallbackResponse() async {
    final preferences = AppPreferencesController.instance;
    if (!preferences.notifier.value.isLoaded) {
      await preferences.load();
    }
    final strings = await loadAppLocalizations(
      preferences.notifier.value.locale,
    );
    final username = await _storedUsername();
    final displayName = username == null ? null : _displayName(username);
    final message = displayName == null
        ? strings.smartNudgeFallbackBody
        : strings.smartNudgeFallbackBodyWithName(name: displayName);
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
          title: strings.smartNudgeFallbackTitle,
          message: message,
          actionLabel: strings.keepItSimple,
          triggerReason: strings.localFallback,
          recommendedFocus: 'maintenance',
          patternType: null,
          severity: 'steady',
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
