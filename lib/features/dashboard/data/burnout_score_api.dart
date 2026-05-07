import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/offline_cache_store.dart';
import '../../../shared/preferences/user_session.dart';

class BurnoutScoreSnapshot {
  final String scoreDate;
  final double overallScore;
  final String riskLevel;
  final double confidenceScore;
  final double completenessScore;
  final List<String> missingFields;

  const BurnoutScoreSnapshot({
    required this.scoreDate,
    required this.overallScore,
    required this.riskLevel,
    required this.confidenceScore,
    required this.completenessScore,
    required this.missingFields,
  });

  factory BurnoutScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return BurnoutScoreSnapshot(
      scoreDate: json['score_date']?.toString() ?? '',
      overallScore: _parseDouble(json['overall_score']),
      riskLevel: json['risk_level']?.toString() ?? 'moderate',
      confidenceScore: _parseDouble(json['confidence_score']),
      completenessScore: _parseDouble(json['completeness_score']),
      missingFields: (json['missing_fields'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class BurnoutPatternPoint {
  final String scoreDate;
  final double overallScore;
  final String riskLevel;
  final double confidenceScore;

  const BurnoutPatternPoint({
    required this.scoreDate,
    required this.overallScore,
    required this.riskLevel,
    required this.confidenceScore,
  });

  factory BurnoutPatternPoint.fromJson(Map<String, dynamic> json) {
    return BurnoutPatternPoint(
      scoreDate: json['score_date']?.toString() ?? '',
      overallScore: _parseDouble(json['overall_score']),
      riskLevel: json['risk_level']?.toString() ?? 'moderate',
      confidenceScore: _parseDouble(json['confidence_score']),
    );
  }
}

class BurnoutWindowSummary {
  final int windowDays;
  final double? averageScore;
  final double? latestScore;
  final double? deltaFromStart;
  final double? slopePerDay;
  final double coveragePercent;
  final double? averageConfidenceScore;
  final String trendDirection;
  final String? dominantDimensionLabel;
  final List<BurnoutPatternPoint> points;

  const BurnoutWindowSummary({
    required this.windowDays,
    required this.averageScore,
    required this.latestScore,
    required this.deltaFromStart,
    required this.slopePerDay,
    required this.coveragePercent,
    required this.averageConfidenceScore,
    required this.trendDirection,
    required this.dominantDimensionLabel,
    required this.points,
  });

  factory BurnoutWindowSummary.fromJson(Map<String, dynamic> json) {
    final dominantDimension = json['dominant_dimension'];

    return BurnoutWindowSummary(
      windowDays: _parseInt(json['window_days']),
      averageScore: _parseOptionalDouble(json['average_score']),
      latestScore: _parseOptionalDouble(json['latest_score']),
      deltaFromStart: _parseOptionalDouble(json['delta_from_start']),
      slopePerDay: _parseOptionalDouble(json['slope_per_day']),
      coveragePercent: _parseDouble(json['coverage_percent']),
      averageConfidenceScore: _parseOptionalDouble(
        json['average_confidence_score'],
      ),
      trendDirection: json['trend_direction']?.toString() ?? 'stable',
      dominantDimensionLabel: dominantDimension is Map
          ? dominantDimension['label']?.toString()
          : null,
      points: (json['points'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BurnoutPatternPoint.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class BurnoutPatternInsight {
  final String type;
  final String severity;
  final String title;
  final String message;
  final String recommendedFocus;

  const BurnoutPatternInsight({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.recommendedFocus,
  });

  factory BurnoutPatternInsight.fromJson(Map<String, dynamic> json) {
    return BurnoutPatternInsight(
      type: json['type']?.toString() ?? 'stable_current_pattern',
      severity: json['severity']?.toString() ?? 'low',
      title: json['title']?.toString() ?? 'Pattern stable',
      message: json['message']?.toString() ?? '',
      recommendedFocus: json['recommended_focus']?.toString() ?? 'maintenance',
    );
  }
}

class BurnoutAdaptiveState {
  final String state;
  final String label;
  final String priority;
  final String recommendedFocus;
  final double confidenceScore;
  final String reason;

  const BurnoutAdaptiveState({
    required this.state,
    required this.label,
    required this.priority,
    required this.recommendedFocus,
    required this.confidenceScore,
    required this.reason,
  });

  factory BurnoutAdaptiveState.fromJson(Map<String, dynamic> json) {
    return BurnoutAdaptiveState(
      state: json['state']?.toString() ?? 'insufficient_data',
      label: json['label']?.toString() ?? 'More data needed',
      priority: json['priority']?.toString() ?? 'low',
      recommendedFocus: json['recommended_focus']?.toString() ?? 'maintenance',
      confidenceScore: _parseDouble(json['confidence_score']),
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class BurnoutPatternSummary {
  final BurnoutScoreSnapshot? latestScore;
  final BurnoutAdaptiveState adaptiveState;
  final Map<String, BurnoutWindowSummary> windows;
  final List<BurnoutPatternInsight> patterns;
  final List<BurnoutPatternPoint> timeline;

  const BurnoutPatternSummary({
    required this.latestScore,
    required this.adaptiveState,
    required this.windows,
    required this.patterns,
    required this.timeline,
  });

  factory BurnoutPatternSummary.fromJson(Map<String, dynamic> json) {
    final rawWindows = json['windows'];
    final windows = <String, BurnoutWindowSummary>{};
    if (rawWindows is Map) {
      for (final entry in rawWindows.entries) {
        final value = entry.value;
        if (value is Map) {
          windows[entry.key.toString()] = BurnoutWindowSummary.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
    }

    final latestScore = json['latest_score'];
    final adaptiveState = json['adaptive_state'];

    return BurnoutPatternSummary(
      latestScore: latestScore is Map
          ? BurnoutScoreSnapshot.fromJson(
              Map<String, dynamic>.from(latestScore),
            )
          : null,
      adaptiveState: adaptiveState is Map
          ? BurnoutAdaptiveState.fromJson(
              Map<String, dynamic>.from(adaptiveState),
            )
          : const BurnoutAdaptiveState(
              state: 'insufficient_data',
              label: 'More data needed',
              priority: 'low',
              recommendedFocus: 'data_completion',
              confidenceScore: 0,
              reason: '',
            ),
      windows: windows,
      patterns: (json['patterns'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BurnoutPatternInsight.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BurnoutPatternPoint.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  BurnoutWindowSummary? windowForDays(int days) {
    return windows['${days}_day'];
  }
}

class BurnoutScoreApi {
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const String _latestScoreCache = 'burnout_latest_score';
  static const String _scoreHistoryCache = 'burnout_score_history';
  static const String _patternSummaryCache = 'burnout_pattern_summary';

  static Future<BurnoutScoreSnapshot?> fetchLatestScore() async {
    if (await _isDemoMode()) {
      return null;
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return null;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.burnout('/scores/latest')}?user_id=$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);
      if (response.statusCode != 200 || data['has_score'] != true) {
        return await _readCachedLatestScore(userId);
      }

      final score = data['score'];
      if (score is! Map) {
        return await _readCachedLatestScore(userId);
      }

      final scoreMap = Map<String, dynamic>.from(score);
      await _cacheJson(_latestScoreCache, userId, {'score': scoreMap});
      return BurnoutScoreSnapshot.fromJson(scoreMap);
    } catch (_) {
      return _readCachedLatestScore(userId);
    }
  }

  static Future<BurnoutScoreSnapshot?> recalculateToday() async {
    if (await _isDemoMode()) {
      return null;
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.burnout('/scores/recalculate')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);
      if (response.statusCode != 200) {
        return await _readCachedLatestScore(userId);
      }

      final score = data['score'];
      if (score is! Map) {
        return await _readCachedLatestScore(userId);
      }

      final scoreMap = Map<String, dynamic>.from(score);
      await _cacheJson(_latestScoreCache, userId, {'score': scoreMap});
      return BurnoutScoreSnapshot.fromJson(scoreMap);
    } catch (_) {
      return _readCachedLatestScore(userId);
    }
  }

  static Future<List<BurnoutScoreSnapshot>> fetchHistory({
    String? startDate,
    String? endDate,
    int limit = 30,
  }) async {
    if (await _isDemoMode()) {
      return const [];
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return const [];
    }

    final query = <String, String>{
      'user_id': userId.toString(),
      'limit': limit.toString(),
    };
    if (startDate != null) {
      query['start'] = startDate;
    }
    if (endDate != null) {
      query['end'] = endDate;
    }
    final uri = Uri.parse(
      ApiConfig.burnout('/scores/history'),
    ).replace(queryParameters: query);
    try {
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);
      if (response.statusCode != 200) {
        return await _readCachedHistory(userId);
      }

      final rawScores = data['scores'] as List<dynamic>? ?? const [];
      await _cacheJson(_scoreHistoryCache, userId, {'scores': rawScores});
      return rawScores
          .whereType<Map>()
          .map(
            (item) =>
                BurnoutScoreSnapshot.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return _readCachedHistory(userId);
    }
  }

  static Future<BurnoutPatternSummary?> fetchPatternSummary() async {
    if (await _isDemoMode()) {
      return null;
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return null;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.burnout('/patterns/summary')}?user_id=$userId',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_requestTimeout);

      final data = _decodeResponseMap(response);
      if (response.statusCode != 200) {
        return await _readCachedPatternSummary(userId);
      }

      await _cacheJson(_patternSummaryCache, userId, data);
      final latestScore = data['latest_score'];
      if (latestScore is Map) {
        await _cacheJson(_latestScoreCache, userId, {
          'score': Map<String, dynamic>.from(latestScore),
        });
      }
      return BurnoutPatternSummary.fromJson(data);
    } catch (_) {
      return _readCachedPatternSummary(userId);
    }
  }

  static Future<void> _cacheJson(
    String namespace,
    int userId,
    Map<String, dynamic> data,
  ) {
    return OfflineCacheStore.saveJson(
      namespace: namespace,
      scope: userId.toString(),
      data: data,
    );
  }

  static Future<BurnoutScoreSnapshot?> _readCachedLatestScore(
    int userId,
  ) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _latestScoreCache,
      scope: userId.toString(),
    );
    var score = data?['score'];
    if (score is! Map) {
      final patternData = await OfflineCacheStore.readLatestJson(
        namespace: _patternSummaryCache,
        scope: userId.toString(),
      );
      score = patternData?['latest_score'];
    }

    if (score is! Map) {
      return null;
    }

    return BurnoutScoreSnapshot.fromJson(Map<String, dynamic>.from(score));
  }

  static Future<List<BurnoutScoreSnapshot>> _readCachedHistory(
    int userId,
  ) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _scoreHistoryCache,
      scope: userId.toString(),
    );
    final scores = data?['scores'];
    if (scores is! List) {
      return const [];
    }

    return scores
        .whereType<Map>()
        .map(
          (item) =>
              BurnoutScoreSnapshot.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<BurnoutPatternSummary?> _readCachedPatternSummary(
    int userId,
  ) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _patternSummaryCache,
      scope: userId.toString(),
    );
    if (data == null) {
      return null;
    }

    return BurnoutPatternSummary.fromJson(data);
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
}

double _parseDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}

double? _parseOptionalDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  return _parseDouble(value);
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}
