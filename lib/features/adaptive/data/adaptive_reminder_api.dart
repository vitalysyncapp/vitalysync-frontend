import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/fetch_policy.dart';

class AdaptiveReminderPreferences {
  final String dailyLogReminderTime;
  final int weeklyPulseReminderDay;
  final String weeklyPulseReminderTime;
  final String hydrationStartTime;
  final String hydrationEndTime;
  final int hydrationIntervalMinutes;
  final String sleepWindDownTime;
  final bool hydrationReminderEnabled;
  final bool recoveryReminderEnabled;
  final bool sleepWindDownEnabled;
  final int nudgeCooldownHours;
  final int maxDailyNudges;

  const AdaptiveReminderPreferences({
    required this.dailyLogReminderTime,
    required this.weeklyPulseReminderDay,
    required this.weeklyPulseReminderTime,
    required this.hydrationStartTime,
    required this.hydrationEndTime,
    required this.hydrationIntervalMinutes,
    required this.sleepWindDownTime,
    required this.hydrationReminderEnabled,
    required this.recoveryReminderEnabled,
    required this.sleepWindDownEnabled,
    required this.nudgeCooldownHours,
    required this.maxDailyNudges,
  });

  factory AdaptiveReminderPreferences.fromJson(Map<String, dynamic> json) {
    return AdaptiveReminderPreferences(
      dailyLogReminderTime: _timeOrFallback(
        json['daily_log_reminder_time'],
        '20:00',
      ),
      weeklyPulseReminderDay: _parseInt(json['weekly_pulse_reminder_day'], 1),
      weeklyPulseReminderTime: _timeOrFallback(
        json['weekly_pulse_reminder_time'],
        '18:00',
      ),
      hydrationStartTime: _timeOrFallback(
        json['hydration_start_time'],
        '07:00',
      ),
      hydrationEndTime: _timeOrFallback(json['hydration_end_time'], '21:00'),
      hydrationIntervalMinutes: _parseInt(
        json['hydration_interval_minutes'],
        120,
      ),
      sleepWindDownTime: _timeOrFallback(json['sleep_wind_down_time'], '21:30'),
      hydrationReminderEnabled: json['hydration_reminder_enabled'] != false,
      recoveryReminderEnabled: json['recovery_reminder_enabled'] != false,
      sleepWindDownEnabled: json['sleep_wind_down_enabled'] != false,
      nudgeCooldownHours: _parseInt(json['nudge_cooldown_hours'], 6),
      maxDailyNudges: _parseInt(json['max_daily_nudges'], 3),
    );
  }

  Map<String, dynamic> toJson({required int userId}) {
    return {
      'user_id': userId,
      'daily_log_reminder_time': dailyLogReminderTime,
      'weekly_pulse_reminder_day': weeklyPulseReminderDay,
      'weekly_pulse_reminder_time': weeklyPulseReminderTime,
      'hydration_start_time': hydrationStartTime,
      'hydration_end_time': hydrationEndTime,
      'hydration_interval_minutes': hydrationIntervalMinutes,
      'sleep_wind_down_time': sleepWindDownTime,
      'hydration_reminder_enabled': hydrationReminderEnabled,
      'recovery_reminder_enabled': recoveryReminderEnabled,
      'sleep_wind_down_enabled': sleepWindDownEnabled,
      'nudge_cooldown_hours': nudgeCooldownHours,
      'max_daily_nudges': maxDailyNudges,
    };
  }

  AdaptiveReminderPreferences copyWith({
    String? dailyLogReminderTime,
    int? weeklyPulseReminderDay,
    String? weeklyPulseReminderTime,
    String? hydrationStartTime,
    String? hydrationEndTime,
    int? hydrationIntervalMinutes,
    String? sleepWindDownTime,
    bool? hydrationReminderEnabled,
    bool? recoveryReminderEnabled,
    bool? sleepWindDownEnabled,
    int? nudgeCooldownHours,
    int? maxDailyNudges,
  }) {
    return AdaptiveReminderPreferences(
      dailyLogReminderTime: dailyLogReminderTime ?? this.dailyLogReminderTime,
      weeklyPulseReminderDay:
          weeklyPulseReminderDay ?? this.weeklyPulseReminderDay,
      weeklyPulseReminderTime:
          weeklyPulseReminderTime ?? this.weeklyPulseReminderTime,
      hydrationStartTime: hydrationStartTime ?? this.hydrationStartTime,
      hydrationEndTime: hydrationEndTime ?? this.hydrationEndTime,
      hydrationIntervalMinutes:
          hydrationIntervalMinutes ?? this.hydrationIntervalMinutes,
      sleepWindDownTime: sleepWindDownTime ?? this.sleepWindDownTime,
      hydrationReminderEnabled:
          hydrationReminderEnabled ?? this.hydrationReminderEnabled,
      recoveryReminderEnabled:
          recoveryReminderEnabled ?? this.recoveryReminderEnabled,
      sleepWindDownEnabled: sleepWindDownEnabled ?? this.sleepWindDownEnabled,
      nudgeCooldownHours: nudgeCooldownHours ?? this.nudgeCooldownHours,
      maxDailyNudges: maxDailyNudges ?? this.maxDailyNudges,
    );
  }

  static const defaults = AdaptiveReminderPreferences(
    dailyLogReminderTime: '20:00',
    weeklyPulseReminderDay: 1,
    weeklyPulseReminderTime: '18:00',
    hydrationStartTime: '07:00',
    hydrationEndTime: '21:00',
    hydrationIntervalMinutes: 120,
    sleepWindDownTime: '21:30',
    hydrationReminderEnabled: true,
    recoveryReminderEnabled: true,
    sleepWindDownEnabled: true,
    nudgeCooldownHours: 6,
    maxDailyNudges: 3,
  );
}

class AdaptiveReminderApi {
  static const Duration _requestTimeout = ApiRequestTimeouts.fastRead;

  static Future<AdaptiveReminderPreferences> fetchPreferences() async {
    final userId = await _storedUserId();
    if (userId == null) {
      return AdaptiveReminderPreferences.defaults;
    }

    final response = await http
        .get(
          Uri.parse('${ApiConfig.adaptive('/reminders')}?user_id=$userId'),
          headers: await ApiConfig.jsonHeaders(),
        )
        .timeout(_requestTimeout);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200) {
      return AdaptiveReminderPreferences.defaults;
    }

    final preferences = data['preferences'];
    if (preferences is! Map) {
      return AdaptiveReminderPreferences.defaults;
    }

    return AdaptiveReminderPreferences.fromJson(
      Map<String, dynamic>.from(preferences),
    );
  }

  static Future<AdaptiveReminderPreferences> savePreferences(
    AdaptiveReminderPreferences preferences,
  ) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return preferences;
    }

    final response = await http
        .put(
          Uri.parse(ApiConfig.adaptive('/reminders')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode(preferences.toJson(userId: userId)),
        )
        .timeout(_requestTimeout);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to save reminder preferences');
    }

    final saved = data['preferences'];
    if (saved is Map) {
      return AdaptiveReminderPreferences.fromJson(
        Map<String, dynamic>.from(saved),
      );
    }

    return preferences;
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
}

String _timeOrFallback(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  if (text.length >= 5) {
    return text.substring(0, 5);
  }

  return fallback;
}

int _parseInt(dynamic value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}
