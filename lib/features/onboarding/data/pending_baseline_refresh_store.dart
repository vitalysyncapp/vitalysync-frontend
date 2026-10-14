import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class PendingBaselineRefresh {
  final int userId;
  final List<Map<String, dynamic>> answers;
  final String baselineDate;
  final String clientRefreshId;
  final DateTime queuedAt;
  final bool needsAttention;
  final String? lastError;

  const PendingBaselineRefresh({
    required this.userId,
    required this.answers,
    required this.baselineDate,
    required this.clientRefreshId,
    required this.queuedAt,
    this.needsAttention = false,
    this.lastError,
  });

  bool isExpired(DateTime now) => now.difference(queuedAt).inDays >= 7;

  PendingBaselineRefresh copyWithAttention(String message) {
    return PendingBaselineRefresh(
      userId: userId,
      answers: answers,
      baselineDate: baselineDate,
      clientRefreshId: clientRefreshId,
      queuedAt: queuedAt,
      needsAttention: true,
      lastError: message,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'burnout_answers': answers,
    'baseline_date': baselineDate,
    'client_refresh_id': clientRefreshId,
    'queued_at': queuedAt.toUtc().toIso8601String(),
    'needs_attention': needsAttention,
    if (lastError != null) 'last_error': lastError,
  };

  factory PendingBaselineRefresh.fromJson(Map<String, dynamic> json) {
    return PendingBaselineRefresh(
      userId: (json['user_id'] as num).toInt(),
      answers: (json['burnout_answers'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((answer) => Map<String, dynamic>.from(answer))
          .toList(),
      baselineDate: json['baseline_date']?.toString() ?? '',
      clientRefreshId: json['client_refresh_id']?.toString() ?? '',
      queuedAt:
          DateTime.tryParse(json['queued_at']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      needsAttention: json['needs_attention'] == true,
      lastError: json['last_error']?.toString(),
    );
  }
}

class PendingBaselineRefreshStore {
  const PendingBaselineRefreshStore();

  static const instance = PendingBaselineRefreshStore();
  static const String _keyPrefix = 'pending_baseline_refresh_v1';

  Future<PendingBaselineRefresh> queue({
    required int userId,
    required List<Map<String, dynamic>> answers,
    required String baselineDate,
    DateTime? now,
  }) async {
    final queuedAt = (now ?? DateTime.now()).toUtc();
    final pending = PendingBaselineRefresh(
      userId: userId,
      answers: answers
          .map(
            (answer) => {
              'question_key': answer['question_key']?.toString(),
              'numeric_value': answer['numeric_value'],
            },
          )
          .toList(),
      baselineDate: baselineDate,
      clientRefreshId: _newRefreshId(userId, queuedAt),
      queuedAt: queuedAt,
    );
    await _write(pending);
    return pending;
  }

  Future<PendingBaselineRefresh?> read(int userId, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final pending = PendingBaselineRefresh.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (pending.userId != userId ||
          pending.isExpired(now ?? DateTime.now())) {
        await clear(userId);
        return null;
      }
      return pending;
    } catch (_) {
      await clear(userId);
      return null;
    }
  }

  Future<void> markNeedsAttention(
    PendingBaselineRefresh pending,
    String message,
  ) {
    return _write(pending.copyWithAttention(message));
  }

  Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }

  Future<void> _write(PendingBaselineRefresh pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(pending.userId), jsonEncode(pending.toJson()));
  }

  String _newRefreshId(int userId, DateTime now) {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    return 'refresh_${userId}_${now.microsecondsSinceEpoch}_$random';
  }

  String _key(int userId) => '${_keyPrefix}_$userId';
}
