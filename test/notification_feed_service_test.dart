import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/shared/notifications/notification_feed_service.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 1});
  });

  test('cached notification feed loads in stable newest-first order', () async {
    await OfflineCacheStore.saveJson(
      namespace: notificationFeedCacheNamespace,
      scope: '1',
      data: {
        'refreshed_at': '2026-05-21T10:00:00.000Z',
        'sources': ['Daily reports'],
        'items': [
          _itemJson(
            id: 'report_1',
            title: 'Older report',
            updatedAt: '2026-05-20T10:00:00.000Z',
          ),
          _itemJson(
            id: 'report_2',
            title: 'Newer report',
            updatedAt: '2026-05-21T10:00:00.000Z',
          ),
        ],
      },
    );

    final feed = await NotificationFeedService.instance.loadFeed();

    expect(feed.isFromCache, isTrue);
    expect(feed.items.map((item) => item.id), ['report_2', 'report_1']);
    expect(feed.unreadCount, 2);
  });

  test('read ids update unread count without rebuilding remote feed', () async {
    await OfflineCacheStore.saveJson(
      namespace: notificationFeedCacheNamespace,
      scope: '1',
      data: {
        'refreshed_at': '2026-05-21T10:00:00.000Z',
        'sources': ['Daily reports'],
        'items': [
          _itemJson(id: 'report_1', title: 'Daily report'),
          _itemJson(id: 'nudge_1', title: 'Smart nudge', category: 'nudge'),
        ],
      },
    );

    await NotificationFeedService.instance.markRead('report_1');
    final feed = await NotificationFeedService.instance.loadFeed();

    expect(feed.unreadCount, 1);
    expect(
      feed.items.firstWhere((item) => item.id == 'report_1').isUnread,
      isFalse,
    );
    expect(
      feed.items.firstWhere((item) => item.id == 'nudge_1').isUnread,
      isTrue,
    );
  });

  test('cached reminders are excluded from the insight feed', () async {
    await OfflineCacheStore.saveJson(
      namespace: notificationFeedCacheNamespace,
      scope: '1',
      data: {
        'refreshed_at': '2026-05-21T10:00:00.000Z',
        'sources': ['Daily reports', 'Reminder history'],
        'items': [
          _itemJson(id: 'report_1', title: 'Daily report'),
          _itemJson(
            id: 'notification_1',
            title: 'Hydration reminder',
            category: 'reminder',
          ),
        ],
      },
    );

    final feed = await NotificationFeedService.instance.loadFeed();

    expect(feed.items.map((item) => item.id), ['report_1']);
    expect(feed.items.any((item) => item.filterKey == 'reminders'), isFalse);
  });

  test('daily report cache preserves the summarized date', () {
    final original = AppNotificationItem(
      id: 'report_1',
      category: 'daily',
      title: 'Daily wellness report',
      message: "Yesterday's wellness summary.",
      sourceLabel: 'Daily report',
      priority: 'low',
      createdAt: DateTime(2026, 7, 16, 7),
      updatedAt: DateTime(2026, 7, 16, 7),
      metricChips: const [],
      isUnread: true,
      reportType: 'daily',
      periodStart: '2026-07-15',
      periodEnd: '2026-07-15',
    );

    final restored = AppNotificationItem.fromJson(original.toJson());

    expect(restored.periodStart, '2026-07-15');
    expect(restored.reportPeriodLabel, 'For Jul 15');
  });
}

Map<String, dynamic> _itemJson({
  required String id,
  required String title,
  String category = 'daily',
  String updatedAt = '2026-05-21T10:00:00.000Z',
}) {
  return {
    'id': id,
    'category': category,
    'title': title,
    'message': 'A data-based summary is available.',
    'source_label': 'Daily report',
    'priority': 'low',
    'created_at': updatedAt,
    'updated_at': updatedAt,
    'metric_chips': ['Sleep 7h'],
    'show_action': false,
    'report_type': category == 'daily' ? 'daily' : null,
  };
}
