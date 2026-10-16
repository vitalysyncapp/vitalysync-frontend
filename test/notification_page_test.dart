import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/notifications/presentation/pages/notification_page.dart';
import 'package:vitalysync/shared/notifications/notification_feed_service.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 1});
  });

  testWidgets(
    'opening NotificationPage automatically marks unread notifications as read',
    (tester) async {
      await OfflineCacheStore.saveJson(
        namespace: notificationFeedCacheNamespace,
        scope: '1',
        data: {
          'refreshed_at': DateTime.now().toIso8601String(),
          'sources': ['Daily reports', 'Smart nudges'],
          'items': [
            {
              'id': 'report_101',
              'category': 'daily',
              'title': 'Daily report',
              'message': 'Good sleep pattern recorded.',
              'source_label': 'Daily report',
              'priority': 'low',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'metric_chips': ['Sleep 8h'],
              'show_action': false,
              'report_type': 'daily',
            },
            {
              'id': 'nudge_202',
              'category': 'nudge',
              'title': 'Hydration reminder',
              'message': 'Drink some water.',
              'source_label': 'Smart nudge',
              'priority': 'medium',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'metric_chips': [],
              'show_action': false,
            },
          ],
        },
      );

      // Verify feed initially has 2 unread notifications
      final initialUnread =
          await NotificationFeedService.instance.unreadCount();
      expect(initialUnread, 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // UI should show "0 unread"
      expect(find.text('0 unread'), findsOneWidget);

      // Service unread count should now be 0
      final afterOpenUnread =
          await NotificationFeedService.instance.unreadCount();
      expect(afterOpenUnread, 0);

      // Notification cards should no longer show "Mark read" button
      expect(find.text('Mark read'), findsNothing);
    },
  );
}
