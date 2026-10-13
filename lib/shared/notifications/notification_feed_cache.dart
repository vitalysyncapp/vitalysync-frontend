import 'package:flutter/foundation.dart';

import '../offline/offline_cache_store.dart';
import '../preferences/user_session.dart';

final ValueNotifier<int> notificationFeedRefreshNotifier = ValueNotifier<int>(
  0,
);

const String notificationFeedCacheNamespace =
    'notification_feed_cbi_wellness_1';

Future<void> refreshNotificationFeed() async {
  notificationFeedRefreshNotifier.value++;
}

Future<void> invalidateNotificationFeedCache() async {
  final session = await UserSessionController.instance.load();
  final userId = session.userId;
  if (userId != null && userId > 0) {
    await OfflineCacheStore.remove(
      namespace: notificationFeedCacheNamespace,
      scope: userId.toString(),
    );
  }

  await refreshNotificationFeed();
}
