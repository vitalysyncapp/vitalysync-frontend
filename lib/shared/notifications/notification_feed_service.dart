import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../features/activity/data/activity_service.dart';
import '../../features/dashboard/data/burnout_score_api.dart';
import '../../features/dashboard/data/weekly_user_metrics.dart';
import '../../features/exercise/data/exercise_goal_service.dart';
import '../../features/log/data/log_api.dart';
import '../preferences/app_preferences.dart';

final ValueNotifier<int> notificationFeedRefreshNotifier = ValueNotifier<int>(
  0,
);

Future<void> refreshNotificationFeed() async {
  notificationFeedRefreshNotifier.value++;
}

class AppNotificationItem {
  final String id;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  final String sourceLabel;
  final bool showAction;
  final bool isUnread;

  const AppNotificationItem({
    required this.id,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.sourceLabel,
    required this.isUnread,
    this.showAction = false,
  });

  AppNotificationItem copyWith({bool? isUnread}) {
    return AppNotificationItem(
      id: id,
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      message: message,
      time: time,
      sourceLabel: sourceLabel,
      isUnread: isUnread ?? this.isUnread,
      showAction: showAction,
    );
  }
}

class NotificationFeedResult {
  final List<AppNotificationItem> items;
  final List<String> functionalSources;

  const NotificationFeedResult({
    required this.items,
    required this.functionalSources,
  });

  int get unreadCount => items.where((item) => item.isUnread).length;
}

class NotificationFeedService {
  NotificationFeedService._();

  static final NotificationFeedService instance = NotificationFeedService._();
  static const String _readIdsKey = 'notification_feed_read_ids';
  static const String _createdAtKey = 'notification_feed_created_at';

  Future<int> unreadCount() async {
    final result = await loadFeed();
    return result.unreadCount;
  }

  Future<NotificationFeedResult> loadFeed() async {
    final readIds = await _readIds();
    final createdAtById = await _readCreatedAtById();
    final items = <AppNotificationItem>[];
    final sources = <String>{};

    await AppPreferencesController.instance.load();
    final prefs = AppPreferencesController.instance.notifier.value;
    if (prefs.notificationsEnabled) {
      if (prefs.hydrationReminderEnabled) {
        sources.add('Hydration reminders');
        items.add(
          _buildItem(
            readIds: readIds,
            createdAtById: createdAtById,
            id: 'reminder_hydration_${_todayKey()}',
            icon: Icons.water_drop_outlined,
            iconBg: const Color(0xFFDDF7FA),
            iconColor: const Color(0xFF00A7C4),
            title: 'Hydration Reminder',
            message:
                'Drink water every ${_intervalLabel(prefs.hydrationIntervalMinutes)} between ${_timeLabel(prefs.hydrationStartTime)} and ${_timeLabel(prefs.hydrationEndTime)}.',
            sourceLabel: 'Reminder',
            showAction: true,
          ),
        );
      }

      if (prefs.bedtimeReminderEnabled) {
        sources.add('Sleep reminders');
        items.add(
          _buildItem(
            readIds: readIds,
            createdAtById: createdAtById,
            id: 'reminder_sleep_${_todayKey()}',
            icon: Icons.nightlight_round,
            iconBg: const Color(0xFFE7E9FF),
            iconColor: const Color(0xFF5A4CFF),
            title: 'Sleep Wind-down',
            message:
                'Start winding down around ${_timeLabel(prefs.sleepWindDownTime)} so recovery has room tonight.',
            sourceLabel: 'Reminder',
            showAction: true,
          ),
        );
      }
    }

    await _addSmartRecommendations(items, readIds, createdAtById, sources);
    await _addBurnoutReports(items, readIds, createdAtById, sources);
    await _addWeeklyProgress(items, readIds, createdAtById, sources);
    await _addActivityReport(items, readIds, createdAtById, sources);
    await _addGoalReport(items, readIds, createdAtById, sources);
    await _writeCreatedAtById(createdAtById, items.map((item) => item.id));

    return NotificationFeedResult(
      items: items,
      functionalSources: sources.toList()..sort(),
    );
  }

  Future<void> markRead(String id) async {
    final ids = await _readIds();
    ids.add(id);
    await _writeIds(ids);
    await refreshNotificationFeed();
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    final saved = await _readIds();
    saved.addAll(ids);
    await _writeIds(saved);
    await refreshNotificationFeed();
  }

  Future<void> _addSmartRecommendations(
    List<AppNotificationItem> items,
    Set<String> readIds,
    Map<String, DateTime> createdAtById,
    Set<String> sources,
  ) async {
    try {
      final response = await AdaptiveNudgeApi.fetchRecommendations(
        limit: 1,
        record: false,
        ai: true,
      );
      final recommendation = response.recommendations.firstOrNull;
      if (recommendation == null || recommendation.message.trim().isEmpty) {
        return;
      }

      sources.add('Smart recommendations');
      items.add(
        _buildItem(
          readIds: readIds,
          createdAtById: createdAtById,
          id: 'smart_${recommendation.nudgeEventId ?? recommendation.nudgeType}_${_todayKey()}',
          icon: Icons.auto_awesome_rounded,
          iconBg: const Color(0xFFFFF4CC),
          iconColor: const Color(0xFFE0A100),
          title: recommendation.title,
          message: _oneSentence(recommendation.message),
          sourceLabel: 'Smart recommendation',
          showAction: recommendation.actionLabel.trim().isNotEmpty,
        ),
      );
    } catch (_) {
      // Recommendations are optional; the rest of the feed can still load.
    }
  }

  Future<void> _addBurnoutReports(
    List<AppNotificationItem> items,
    Set<String> readIds,
    Map<String, DateTime> createdAtById,
    Set<String> sources,
  ) async {
    try {
      final summary = await BurnoutScoreApi.fetchPatternSummary();
      final latest = summary?.latestScore;
      final pattern = summary?.patterns.firstOrNull;
      if (latest == null && pattern == null) {
        return;
      }

      sources.add('Burnout reports');
      final scoreText = latest == null
          ? 'Burnout pattern data is available.'
          : 'Burnout risk is ${latest.riskLevel} at ${latest.overallScore.round()}/100.';
      final patternText = pattern?.message.trim();
      items.add(
        _buildItem(
          readIds: readIds,
          createdAtById: createdAtById,
          id: 'burnout_${latest?.scoreDate ?? _todayKey()}_${pattern?.type ?? 'score'}',
          icon: Icons.health_and_safety_outlined,
          iconBg: const Color(0xFFFFE5E5),
          iconColor: const Color(0xFFFF3B30),
          title: 'Burnout Report',
          message: _oneSentence(
            patternText == null || patternText.isEmpty
                ? scoreText
                : patternText,
            fallback: scoreText,
          ),
          sourceLabel: 'Burnout report',
        ),
      );
    } catch (_) {
      // Burnout reporting depends on backend data and should fail quietly here.
    }
  }

  Future<void> _addWeeklyProgress(
    List<AppNotificationItem> items,
    Set<String> readIds,
    Map<String, DateTime> createdAtById,
    Set<String> sources,
  ) async {
    try {
      final metrics = await WeeklyUserMetricsService.loadCurrentWeek();
      if (metrics.loggedDays == 0) {
        return;
      }

      sources.add('Progress reports');
      sources.add('Insights');
      items.add(
        _buildItem(
          readIds: readIds,
          createdAtById: createdAtById,
          id: 'progress_${LogApi.weekStartKey()}',
          icon: Icons.show_chart_rounded,
          iconBg: const Color(0xFFDDF5E6),
          iconColor: const Color(0xFF22A55D),
          title: 'Progress Report',
          message:
              '${metrics.weeklyNote} Consistency is ${metrics.consistencyScore}% across ${metrics.loggedDays}/7 logged days.',
          sourceLabel: 'Progress report',
        ),
      );
    } catch (_) {
      // Weekly reports should not block reminders.
    }
  }

  Future<void> _addActivityReport(
    List<AppNotificationItem> items,
    Set<String> readIds,
    Map<String, DateTime> createdAtById,
    Set<String> sources,
  ) async {
    final state = ActivityService.instance.notifier.value;
    if (state.isLoading) {
      return;
    }

    final log = state.log;
    sources.add('Activity reports');
    items.add(
      _buildItem(
        readIds: readIds,
        createdAtById: createdAtById,
        id: 'activity_${log.logDate}_${log.steps}_${log.goalSteps}',
        icon: Icons.directions_walk_rounded,
        iconBg: const Color(0xFFE8F4FF),
        iconColor: const Color(0xFF1479CC),
        title: 'Activity Report',
        message:
            '${NumberFormat.decimalPattern().format(log.steps)} steps logged today; ${log.statusLabel.toLowerCase()} toward ${NumberFormat.decimalPattern().format(log.goalSteps)} steps.',
        sourceLabel: 'Activity report',
      ),
    );
  }

  Future<void> _addGoalReport(
    List<AppNotificationItem> items,
    Set<String> readIds,
    Map<String, DateTime> createdAtById,
    Set<String> sources,
  ) async {
    final state = ExerciseGoalService.instance.notifier.value;
    final goal = state.goal;
    if (goal == null || !goal.hasSelectedGoal || goal.isCanceled) {
      return;
    }

    sources.add('Goal reports');
    final status = goal.isCompleted ? 'completed' : 'active';
    items.add(
      _buildItem(
        readIds: readIds,
        createdAtById: createdAtById,
        id: 'goal_${goal.logDate}_${goal.exerciseName}_$status',
        icon: Icons.flag_outlined,
        iconBg: const Color(0xFFF0E8FF),
        iconColor: const Color(0xFF7C3AED),
        title: 'Goal Report',
        message:
            '${goal.exerciseName} is $status today; keep the goal aligned with your current energy.',
        sourceLabel: 'Goal report',
      ),
    );
  }

  AppNotificationItem _buildItem({
    required Set<String> readIds,
    required Map<String, DateTime> createdAtById,
    required String id,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String message,
    required String sourceLabel,
    bool showAction = false,
  }) {
    final createdAt = createdAtById.putIfAbsent(id, DateTime.now);

    return AppNotificationItem(
      id: id,
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      message: message,
      time: _timeAgo(createdAt),
      sourceLabel: sourceLabel,
      isUnread: !readIds.contains(id),
      showAction: showAction,
    );
  }

  Future<Set<String>> _readIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readIdsKey) ?? const <String>[]).toSet();
  }

  Future<void> _writeIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, ids.toList()..sort());
  }

  Future<Map<String, DateTime>> _readCreatedAtById() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_createdAtKey);
    if (raw == null || raw.isEmpty) {
      return <String, DateTime>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, DateTime>{};
      }

      final values = <String, DateTime>{};
      for (final entry in decoded.entries) {
        final parsed = DateTime.tryParse(entry.value.toString());
        if (parsed != null) {
          values[entry.key.toString()] = parsed;
        }
      }
      return values;
    } catch (_) {
      return <String, DateTime>{};
    }
  }

  Future<void> _writeCreatedAtById(
    Map<String, DateTime> createdAtById,
    Iterable<String> activeIds,
  ) async {
    final activeIdSet = activeIds.toSet();
    final normalized = <String, String>{
      for (final entry in createdAtById.entries)
        if (activeIdSet.contains(entry.key))
          entry.key: entry.value.toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_createdAtKey, jsonEncode(normalized));
  }

  String _todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String _timeLabel(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.firstOrNull ?? '') ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final date = DateTime(2020, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(date);
  }

  String _intervalLabel(int minutes) {
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    }

    return '$minutes minutes';
  }

  String _timeAgo(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }

    final years = (difference.inDays / 365).floor();
    return years == 1 ? '1 year ago' : '$years years ago';
  }

  String _oneSentence(String value, {String fallback = 'Insight available.'}) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return fallback;
    }

    final match = RegExp(r'^.*?[.!?](\s|$)').firstMatch(normalized);
    if (match != null) {
      return normalized.substring(0, match.end).trim();
    }

    return normalized;
  }
}
