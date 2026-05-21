import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../features/adaptive/data/insight_report_api.dart';
import '../offline/offline_cache_store.dart';
import '../preferences/user_session.dart';
import 'notification_event_api.dart';
import 'notification_feed_cache.dart';

export 'notification_feed_cache.dart';

class AppNotificationItem {
  final String id;
  final String category;
  final String title;
  final String message;
  final String sourceLabel;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> metricChips;
  final bool showAction;
  final bool isUnread;
  final String? reportType;

  const AppNotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.sourceLabel,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.metricChips,
    required this.isUnread,
    this.showAction = false,
    this.reportType,
  });

  String get time => _timeAgo(updatedAt);

  String get filterKey {
    if (category == 'daily' || reportType == 'daily') {
      return 'daily';
    }
    if (category == 'weekly' || reportType == 'weekly') {
      return 'weekly';
    }
    if (category == 'nudge') {
      return 'nudges';
    }
    return 'reminders';
  }

  IconData get icon {
    switch (filterKey) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.calendar_month_rounded;
      case 'nudges':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color get iconBg {
    switch (filterKey) {
      case 'daily':
        return const Color(0xFFE8F4FF);
      case 'weekly':
        return const Color(0xFFEAF8EF);
      case 'nudges':
        return const Color(0xFFFFF4CC);
      default:
        return const Color(0xFFE7E9FF);
    }
  }

  Color get iconColor {
    switch (filterKey) {
      case 'daily':
        return const Color(0xFF1479CC);
      case 'weekly':
        return const Color(0xFF22A55D);
      case 'nudges':
        return const Color(0xFFE0A100);
      default:
        return const Color(0xFF5A4CFF);
    }
  }

  AppNotificationItem copyWith({bool? isUnread}) {
    return AppNotificationItem(
      id: id,
      category: category,
      title: title,
      message: message,
      sourceLabel: sourceLabel,
      priority: priority,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metricChips: metricChips,
      isUnread: isUnread ?? this.isUnread,
      showAction: showAction,
      reportType: reportType,
    );
  }

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'reminder',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      sourceLabel: json['source_label']?.toString() ?? 'Notification',
      priority: json['priority']?.toString() ?? 'low',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      metricChips: (json['metric_chips'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      isUnread: json['is_unread'] == true,
      showAction: json['show_action'] == true,
      reportType: json['report_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'message': message,
      'source_label': sourceLabel,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metric_chips': metricChips,
      'show_action': showAction,
      'report_type': reportType,
    };
  }
}

class NotificationFeedResult {
  final List<AppNotificationItem> items;
  final List<String> functionalSources;
  final DateTime? refreshedAt;
  final bool isFromCache;

  const NotificationFeedResult({
    required this.items,
    required this.functionalSources,
    required this.refreshedAt,
    required this.isFromCache,
  });

  int get unreadCount => items.where((item) => item.isUnread).length;

  bool get hasReports {
    return items.any((item) => item.filterKey == 'daily' || item.filterKey == 'weekly');
  }
}

class NotificationFeedService {
  NotificationFeedService._();

  static final NotificationFeedService instance = NotificationFeedService._();
  static const String _readIdsKeyPrefix = 'notification_feed_read_ids_v2';
  static const Duration _freshnessWindow = Duration(minutes: 10);

  Future<int> unreadCount() async {
    final result = await loadFeed();
    return result.unreadCount;
  }

  Future<NotificationFeedResult> loadFeed({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await loadCachedFeed();
      if (cached != null) {
        return cached;
      }
    }

    return refreshFeed();
  }

  Future<NotificationFeedResult?> loadCachedFeed() async {
    final userId = await _storedUserId();
    if (userId == null) {
      return null;
    }

    final data = await OfflineCacheStore.readLatestJson(
      namespace: notificationFeedCacheNamespace,
      scope: userId.toString(),
    );
    if (data == null) {
      return null;
    }

    return _resultFromCacheData(userId, data);
  }

  Future<NotificationFeedResult> refreshFeed() async {
    final userId = await _storedUserId();
    if (userId == null) {
      return const NotificationFeedResult(
        items: [],
        functionalSources: [],
        refreshedAt: null,
        isFromCache: false,
      );
    }

    try {
      await InsightReportApi.refreshReports();
      final results = await Future.wait<dynamic>([
        InsightReportApi.listReports(limit: 30),
        AdaptiveNudgeApi.listNudgeEvents(limit: 30),
        NotificationEventApi.listEvents(limit: 30),
      ]);

      final reports = results[0] as List<InsightReport>;
      final nudges = results[1] as List<AdaptiveNudgeEvent>;
      final events = results[2] as List<NotificationEventRecord>;
      final readIds = await _readIds(userId);
      final sources = <String>{};

      final items = <AppNotificationItem>[
        for (final report in reports) _itemFromReport(report, readIds, sources),
        for (final nudge in nudges) _itemFromNudge(nudge, readIds, sources),
        for (final event in events) _itemFromNotification(event, readIds, sources),
      ]..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

      final limitedItems = items.take(60).toList();
      final refreshedAt = DateTime.now();
      final data = {
        'items': limitedItems.map((item) => item.toJson()).toList(),
        'sources': sources.toList()..sort(),
        'refreshed_at': refreshedAt.toIso8601String(),
      };
      final sourceList = (data['sources'] as List).cast<String>();
      await OfflineCacheStore.saveJson(
        namespace: notificationFeedCacheNamespace,
        scope: userId.toString(),
        data: data,
      );

      return NotificationFeedResult(
        items: limitedItems,
        functionalSources: sourceList,
        refreshedAt: refreshedAt,
        isFromCache: false,
      );
    } catch (_) {
      final cached = await loadCachedFeed();
      if (cached != null) {
        return cached;
      }

      return const NotificationFeedResult(
        items: [],
        functionalSources: [],
        refreshedAt: null,
        isFromCache: false,
      );
    }
  }

  Future<bool> shouldRefreshCachedFeed() async {
    final cached = await loadCachedFeed();
    if (cached == null) {
      return true;
    }

    final refreshedAt = cached.refreshedAt;
    if (refreshedAt == null) {
      return true;
    }

    return DateTime.now().difference(refreshedAt) >= _freshnessWindow;
  }

  Future<void> markRead(String id) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return;
    }

    final ids = await _readIds(userId);
    ids.add(id);
    await _writeIds(userId, ids);
    await refreshNotificationFeed();
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return;
    }

    final saved = await _readIds(userId);
    saved.addAll(ids);
    await _writeIds(userId, saved);
    await refreshNotificationFeed();
  }

  Future<NotificationFeedResult?> _resultFromCacheData(
    int userId,
    Map<String, dynamic> data,
  ) async {
    final readIds = await _readIds(userId);
    final rawItems = data['items'];
    if (rawItems is! List) {
      return null;
    }

    final items = rawItems
        .whereType<Map>()
        .map((item) => AppNotificationItem.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .map((item) => item.copyWith(isUnread: !readIds.contains(item.id)))
        .toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    return NotificationFeedResult(
      items: items,
      functionalSources: (data['sources'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      refreshedAt: DateTime.tryParse(data['refreshed_at']?.toString() ?? ''),
      isFromCache: true,
    );
  }

  AppNotificationItem _itemFromReport(
    InsightReport report,
    Set<String> readIds,
    Set<String> sources,
  ) {
    final category = report.reportType == 'weekly' ? 'weekly' : 'daily';
    sources.add(category == 'weekly' ? 'Weekly reports' : 'Daily reports');
    final id = 'report_${report.insightReportId}';

    return AppNotificationItem(
      id: id,
      category: category,
      title: report.title,
      message: report.summary,
      sourceLabel: category == 'weekly' ? 'Weekly report' : 'Daily report',
      priority: report.priority,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
      metricChips: _reportMetricChips(report),
      isUnread: !readIds.contains(id),
      reportType: report.reportType,
    );
  }

  AppNotificationItem _itemFromNudge(
    AdaptiveNudgeEvent event,
    Set<String> readIds,
    Set<String> sources,
  ) {
    sources.add('Smart nudges');
    final id = 'nudge_${event.nudgeEventId}';
    final priority = event.metadata['priority']?.toString() ?? 'medium';

    return AppNotificationItem(
      id: id,
      category: 'nudge',
      title: event.title,
      message: _oneSentence(event.message),
      sourceLabel: 'Smart nudge',
      priority: priority,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      metricChips: [
        _titleCase(event.status),
        if (event.nudgeType.trim().isNotEmpty) _humanize(event.nudgeType),
      ],
      showAction: event.actionLabel?.trim().isNotEmpty == true,
      isUnread: !readIds.contains(id),
    );
  }

  AppNotificationItem _itemFromNotification(
    NotificationEventRecord event,
    Set<String> readIds,
    Set<String> sources,
  ) {
    sources.add('Reminder history');
    final id = 'notification_${event.notificationEventId}';
    final occurredAt = event.sentAt ?? event.scheduledFor ?? event.updatedAt;

    return AppNotificationItem(
      id: id,
      category: 'reminder',
      title: event.title,
      message: _oneSentence(event.body),
      sourceLabel: _humanize(event.notificationType),
      priority: event.status == 'failed' ? 'medium' : 'low',
      createdAt: event.createdAt,
      updatedAt: occurredAt,
      metricChips: [_titleCase(event.status)],
      isUnread: !readIds.contains(id),
    );
  }

  Future<int?> _storedUserId() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    return userId == null || userId <= 0 ? null : userId;
  }

  Future<Set<String>> _readIds(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readIdsKey(userId)) ?? const <String>[]).toSet();
  }

  Future<void> _writeIds(int userId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey(userId), ids.toList()..sort());
  }

  String _readIdsKey(int userId) {
    return '${_readIdsKeyPrefix}_$userId';
  }
}

List<String> _reportMetricChips(InsightReport report) {
  final metrics = report.metrics;
  final chips = <String>[];
  if (report.reportType == 'weekly') {
    _addMetric(chips, 'Logs', metrics['logged_days'], suffix: '/7');
    _addMetric(chips, 'Avg sleep', metrics['average_sleep_hours'], suffix: 'h');
    _addMetric(chips, 'Steps', metrics['total_steps'], compactNumber: true);
    _addRiskMetric(chips, metrics['latest_burnout_risk_level']);
  } else {
    _addMetric(chips, 'Sleep', metrics['sleep_hours'], suffix: 'h');
    _addMetric(chips, 'Hydration', metrics['hydration_liters'], suffix: 'L');
    _addMetric(chips, 'Stress', metrics['perceived_stress_level'], suffix: '/5');
    _addMetric(chips, 'Steps', metrics['steps'], compactNumber: true);
    _addRiskMetric(chips, metrics['burnout_risk_level']);
  }

  return chips.take(4).toList();
}

void _addMetric(
  List<String> chips,
  String label,
  dynamic value, {
  String suffix = '',
  bool compactNumber = false,
}) {
  if (value == null) {
    return;
  }
  final parsed = num.tryParse(value.toString());
  if (parsed == null || parsed == 0) {
    return;
  }
  final formatted = compactNumber
      ? NumberFormat.compact().format(parsed)
      : parsed == parsed.roundToDouble()
          ? parsed.toInt().toString()
          : parsed.toStringAsFixed(1);
  chips.add('$label $formatted$suffix');
}

void _addRiskMetric(List<String> chips, dynamic risk) {
  final text = risk?.toString().trim();
  if (text == null || text.isEmpty) {
    return;
  }

  chips.add('Risk ${_titleCase(text)}');
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
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

  return DateFormat('MMM d').format(value);
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

String _humanize(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  return _titleCase(normalized);
}

String _titleCase(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        if (part.length == 1) {
          return part.toUpperCase();
        }
        return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
      })
      .join(' ');
}
