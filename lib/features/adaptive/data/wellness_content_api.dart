import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/fetch_policy.dart';
import '../../../shared/offline/offline_cache_store.dart';

/// Shared exposure and response memory for cards in both Flutter engines.
class WellnessContentApi {
  static final changes = ValueNotifier<int>(0);
  static int revision = 0;
  static final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};
  static const _eventCache = 'wellness_content_events';

  static Future<String> sessionKey() async {
    final prefs = await SharedPreferences.getInstance();
    return '${prefs.getInt('user_id')}_${prefs.getString('app_language') ?? 'english'}';
  }

  static Map<String, dynamic> metadata(Map<String, dynamic> content) =>
      content['metadata'] is Map
      ? Map<String, dynamic>.from(content['metadata'] as Map)
      : <String, dynamic>{};

  static Future<Map<String, dynamic>?> savedEvent(
    Map<String, dynamic> content,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final id = metadata(content)['content_id'];
    if (userId == null || id == null) return null;
    await OfflineCacheStore.reload();
    return OfflineCacheStore.readLatestJson(
      namespace: _eventCache,
      scope: '${userId}_$id',
    );
  }

  static Future<Map<String, dynamic>?> respond(
    Map<String, dynamic> content,
    String interaction,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final details = metadata(content);
    final id = details['content_id']?.toString();
    if (userId == null ||
        id == null ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) {
      return null;
    }
    final key =
        '${userId}_${prefs.getString('app_language')}_${id}_$interaction';
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final future = _save(content, details, userId, id, interaction);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<Map<String, dynamic>?> _save(
    Map<String, dynamic> content,
    Map<String, dynamic> details,
    int userId,
    String id,
    String interaction,
  ) async {
    if (interaction == 'shown') {
      final cached = await savedEvent(content);
      if (cached != null) return cached;
    }
    final response = await http
        .post(
          Uri.parse(ApiConfig.adaptive('/nudge-events')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({
            'user_id': userId,
            'nudge_type':
                content['nudge_type'] ??
                (details['surface'] == 'dashboard'
                    ? 'personal_insight'
                    : 'nutrition_insight'),
            'message': content['message'],
            'action_label': content['action_label'],
            'trigger_reason': content['trigger_reason'] ?? details['evidence'],
            'metadata': {...details, 'title': content['title']},
            'interaction': interaction,
          }),
        )
        .timeout(ApiRequestTimeouts.fastRead);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Unable to save your response. Please try again.');
    }
    final data = jsonDecode(response.body) as Map;
    final event = Map<String, dynamic>.from(data['event'] as Map);
    // Commit locally only after the server acknowledges the response.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('user_id') == userId) {
      final previous = await savedEvent(content);
      if (interaction == 'shown' &&
          previous != null &&
          metadata(previous)['interacted_at'] != null) {
        return previous;
      }
      await OfflineCacheStore.saveJson(
        namespace: _eventCache,
        scope: '${userId}_$id',
        data: event,
      );
      if (interaction != 'shown') await invalidate(notify: false);
    }
    return event;
  }

  static Future<void> invalidate({bool notify = true}) async {
    revision++;
    for (final namespace in [
      'adaptive_nudge_recommendations',
      'assistant_nudge_recommendations',
      'personal_insight',
    ]) {
      await OfflineCacheStore.removeNamespace(namespace: namespace);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nutrition_assistant_insight');
    if (notify) changes.value++;
  }
}
