import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_feed_cache.dart';

class LocaleSensitiveCacheService {
  const LocaleSensitiveCacheService._();

  static const Set<String> _exactKeys = {
    'cached_environment_snapshot',
    'nutrition_last_insight',
    'nutrition_assistant_insight',
    'nutrition_message_history',
    'nutrition_last_push_date',
    'nutrition_assistant_shown_date',
  };

  static const List<String> _prefixes = ['overlay_preview_'];

  static Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) =>
          _exactKeys.contains(key) ||
          _prefixes.any((prefix) => key.startsWith(prefix)),
    );

    for (final key in keys.toList(growable: false)) {
      await prefs.remove(key);
    }

    await invalidateNotificationFeedCache();
  }
}
