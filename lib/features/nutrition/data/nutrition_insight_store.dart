import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'nutrition_coach.dart';

class NutritionInsightStore {
  NutritionInsightStore._();

  static final NutritionInsightStore instance = NutritionInsightStore._();

  static const String _lastInsightKey = 'nutrition_last_insight';
  static const String _messageHistoryKey = 'nutrition_message_history';
  static const String _lastPushDateKey = 'nutrition_last_push_date';
  static const String _assistantShownDateKey = 'nutrition_assistant_shown_date';

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

  String _normalizeMessage(String message) {
    return message.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _dateKey(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().substring(0, 10);
  }
}
