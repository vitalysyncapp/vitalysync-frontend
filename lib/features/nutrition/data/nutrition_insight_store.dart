import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'nutrition_coach.dart';

class NutritionInsightStore {
  NutritionInsightStore._();

  static final NutritionInsightStore instance = NutritionInsightStore._();

  static const String _lastInsightKey = 'nutrition_last_insight';
  static const String _assistantInsightKey = 'nutrition_assistant_insight';
  static const String _messageHistoryKey = 'nutrition_message_history';
  static const String _lastPushDateKey = 'nutrition_last_push_date';
  static const String _assistantShownDateKey = 'nutrition_assistant_shown_date';
  static const String _insightFeedbackKey = 'nutrition_insight_feedback';

  Future<NutritionInsight?> readLastInsight() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastInsightKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return NutritionInsight.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> saveInsight(NutritionInsight insight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastInsightKey, jsonEncode(insight.toJson()));
    await rememberMessage(insight.message, at: insight.generatedAt);
  }

  Future<NutritionInsight?> readAssistantInsightForToday({
    DateTime? now,
    Duration? maxAge,
    bool allowStale = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_assistantInsightKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(decoded);
      if (data['date']?.toString() != _dateKey(now ?? DateTime.now())) {
        return null;
      }

      final insight = data['insight'];
      if (insight is Map) {
        final parsedInsight = NutritionInsight.fromJson(
          Map<String, dynamic>.from(insight),
        );
        if (maxAge != null &&
            !allowStale &&
            !_isFreshAssistantCache(data, parsedInsight, maxAge, now)) {
          return null;
        }

        return parsedInsight;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> saveAssistantInsightForToday(
    NutritionInsight insight, {
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _assistantInsightKey,
      jsonEncode({
        'date': _dateKey(now ?? DateTime.now()),
        'cached_at': DateTime.now().toIso8601String(),
        'insight': insight.toJson(),
      }),
    );
  }

  Future<bool> canUseMessage(
    String message, {
    DateTime? now,
    Duration minGap = const Duration(hours: 48),
  }) async {
    final normalized = _normalizeMessage(message);
    if (normalized.isEmpty) {
      return false;
    }

    final history = await _readMessageHistory();
    final currentTime = now ?? DateTime.now();
    final lastUsed = history[normalized];
    if (lastUsed == null) {
      return true;
    }

    return currentTime.difference(lastUsed) >= minGap;
  }

  Future<void> rememberMessage(String message, {DateTime? at}) async {
    final normalized = _normalizeMessage(message);
    if (normalized.isEmpty) {
      return;
    }

    final currentTime = at ?? DateTime.now();
    final history = await _readMessageHistory();
    history[normalized] = currentTime;

    final cutoff = currentTime.subtract(const Duration(days: 14));
    history.removeWhere((_, value) => value.isBefore(cutoff));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _messageHistoryKey,
      jsonEncode({
        for (final entry in history.entries)
          entry.key: entry.value.toIso8601String(),
      }),
    );
  }

  Future<bool> hasSentNutritionPushToday({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPushDateKey) == _dateKey(now ?? DateTime.now());
  }

  Future<void> markNutritionPushSentToday({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPushDateKey, _dateKey(now ?? DateTime.now()));
  }

  Future<bool> hasShownAssistantToday({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_assistantShownDateKey) ==
        _dateKey(now ?? DateTime.now());
  }

  Future<void> markAssistantShownToday({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _assistantShownDateKey,
      _dateKey(now ?? DateTime.now()),
    );
  }

  Future<String?> readFeedbackStatus(String insightId) async {
    final history = await _readFeedbackHistory();
    return history[insightId]?['status']?.toString();
  }

  Future<void> saveFeedbackStatus(String insightId, String status) async {
    final history = await _readFeedbackHistory();
    history[insightId] = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_insightFeedbackKey, jsonEncode(history));
  }

  Future<Map<String, DateTime>> _readMessageHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messageHistoryKey);
    if (raw == null || raw.isEmpty) {
      return <String, DateTime>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, DateTime>{};
      }

      final history = <String, DateTime>{};
      for (final entry in decoded.entries) {
        final parsed = DateTime.tryParse(entry.value.toString());
        if (parsed != null) {
          history[entry.key.toString()] = parsed;
        }
      }
      return history;
    } catch (_) {
      return <String, DateTime>{};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _readFeedbackHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_insightFeedbackKey);
    if (raw == null || raw.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, Map<String, dynamic>>{};
      }

      return decoded.map((key, value) {
        final normalizedValue = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        return MapEntry(key.toString(), normalizedValue);
      });
    } catch (_) {
      return <String, Map<String, dynamic>>{};
    }
  }

  String _normalizeMessage(String message) {
    return message.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  bool _isFreshAssistantCache(
    Map<String, dynamic> data,
    NutritionInsight insight,
    Duration maxAge,
    DateTime? now,
  ) {
    final cachedAt =
        DateTime.tryParse(data['cached_at']?.toString() ?? '') ??
        insight.generatedAt;

    return (now ?? DateTime.now()).difference(cachedAt) <= maxAge;
  }

  String _dateKey(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().substring(0, 10);
  }
}
