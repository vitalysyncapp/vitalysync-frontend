import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/log/data/log_api.dart';
import '../../features/onboarding/data/onboarding_api.dart';

class FirstWeekLearningState {
  final bool isVisible;
  final int dayNumber;
  final int loggedDays;

  const FirstWeekLearningState({
    required this.isVisible,
    required this.dayNumber,
    required this.loggedDays,
  });

  const FirstWeekLearningState.hidden()
    : isVisible = false,
      dayNumber = 0,
      loggedDays = 0;

  String get headerLabel => 'Day $dayNumber/7 - learning your rhythm';

  String get aiInsightNote {
    if (loggedDays == 0) {
      return 'Still learning - log today to start your baseline.';
    }
    if (loggedDays == 1) {
      return 'Still learning - one more log sharpens AI insight.';
    }
    return 'Still learning your rhythm through day 7.';
  }

  String get assistantNudgeNote {
    if (loggedDays == 0) {
      return 'Personalized nudges start after 2 days of logging.';
    }
    if (loggedDays == 1) {
      return 'Personalized nudges can start tomorrow.';
    }
    return 'Nudges keep getting sharper through day 7.';
  }
}

class FirstWeekLearningService {
  FirstWeekLearningService._();

  static const int windowDays = 7;
  static const String _startKeyPrefix = 'first_week_learning_started_at';

  static Future<FirstWeekLearningState> load() async {
    final userId = await LogApi.getStoredUserId();
    if (userId == null) {
      return const FirstWeekLearningState.hidden();
    }

    final today = _dateOnly(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final storedStart = _parseDateTime(prefs.getString(_startKey(userId)));
    final recentLogs = await _loadRecentLogs(today);
    final earliestRecentLog = _earliestLogDate(recentLogs);
    final onboardingStart = await _loadOnboardingCompletedDate(userId);

    final startDate =
        onboardingStart ?? earliestRecentLog ?? storedStart ?? today;
    final normalizedStartDate = _dateOnly(startDate);

    if (storedStart == null ||
        normalizedStartDate.isBefore(_dateOnly(storedStart))) {
      await prefs.setString(
        _startKey(userId),
        normalizedStartDate.toIso8601String(),
      );
    }

    final dayNumber = today.difference(normalizedStartDate).inDays + 1;
    if (dayNumber < 1 || dayNumber > windowDays) {
      return const FirstWeekLearningState.hidden();
    }

    return FirstWeekLearningState(
      isVisible: true,
      dayNumber: dayNumber,
      loggedDays: _countLoggedDays(
        recentLogs,
        startDate: normalizedStartDate,
        endDate: today,
      ),
    );
  }

  static Future<DateTime?> _loadOnboardingCompletedDate(int userId) async {
    try {
      final status = await OnboardingApi.fetchStatus(
        userId,
      ).timeout(const Duration(seconds: 4));
      return _parseDateTime(status['onboarding_completed_at']);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _loadRecentLogs(
    DateTime today,
  ) async {
    try {
      return LogApi.fetchHistory(
        startDate: _dateKey(today.subtract(const Duration(days: 29))),
        endDate: _dateKey(today),
        limit: 30,
      );
    } catch (_) {
      return const [];
    }
  }

  static DateTime? _earliestLogDate(List<Map<String, dynamic>> logs) {
    DateTime? earliest;
    for (final log in logs) {
      final logDate = _parseDateTime(
        LogApi.normalizeDateString(log['log_date']),
      );
      if (logDate == null) {
        continue;
      }

      final normalized = _dateOnly(logDate);
      if (earliest == null || normalized.isBefore(earliest)) {
        earliest = normalized;
      }
    }

    return earliest;
  }

  static int _countLoggedDays(
    List<Map<String, dynamic>> logs, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dates = <String>{};
    for (final log in logs) {
      final logDate = _parseDateTime(
        LogApi.normalizeDateString(log['log_date']),
      );
      if (logDate == null) {
        continue;
      }

      final normalized = _dateOnly(logDate);
      if (normalized.isBefore(startDate) || normalized.isAfter(endDate)) {
        continue;
      }

      dates.add(_dateKey(normalized));
    }

    return dates.length.clamp(0, windowDays).toInt();
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime? _parseDateTime(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String _startKey(int userId) => '${_startKeyPrefix}_$userId';
}
