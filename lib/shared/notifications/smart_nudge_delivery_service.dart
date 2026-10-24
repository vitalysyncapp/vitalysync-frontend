import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../offline/fetch_policy.dart';
import 'local_notification_service.dart';
import 'notification_feed_cache.dart';

typedef SmartNudgeNotifier =
    Future<String> Function({
      required int id,
      required String title,
      required String body,
      required String payload,
      DateTime? scheduledFor,
    });

/// Delivery is keyed by the server's finalized content, not by a widget render.
/// Server claims coordinate the main Flutter engine and the Android overlay.
class SmartNudgeDeliveryService {
  SmartNudgeDeliveryService._()
    : _show = LocalNotificationService.instance.showSmartNudge,
      _cancel = LocalNotificationService.instance.cancelSmartNudge;

  /// Allows delivery behavior to be verified without an operating-system alert.
  SmartNudgeDeliveryService.forTesting({
    required SmartNudgeNotifier show,
    required Future<void> Function(int) cancel,
  }) : _show = show,
       _cancel = cancel;
  static final instance = SmartNudgeDeliveryService._();
  static const _ledgerPrefix = 'smart_nudge_delivery_v2_';
  final SmartNudgeNotifier _show;
  final Future<void> Function(int) _cancel;
  final Map<String, Future<void>> _pending = {};

  Future<Map<String, dynamic>?> _read(int userId, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    try {
      final raw = prefs.getString('$_ledgerPrefix${userId}_$id');
      return raw == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(int userId, String id, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_ledgerPrefix${userId}_$id', jsonEncode(value));
  }

  static int notificationId(String contentId) =>
      20000000 + int.parse(contentId.substring(0, 7), radix: 16);
  static String payload(int userId, String contentId) =>
      'smart_nudge:$userId:$contentId';
  static ({int userId, String contentId})? parsePayload(String? value) {
    final match = RegExp(
      r'^smart_nudge:(\d+):([a-f0-9]{32})$',
    ).firstMatch(value ?? '');
    final userId = int.tryParse(match?.group(1) ?? '');
    return userId == null
        ? null
        : (userId: userId, contentId: match!.group(2)!);
  }

  Future<void> deliver(
    Map<String, dynamic> content, {
    int? expectedUserId,
  }) async {
    final metadata = Map<String, dynamic>.from(
      content['metadata'] as Map? ?? {},
    );
    final id = metadata['content_id']?.toString();
    if (id == null ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
        metadata['delivery'] is! Map) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final userId = prefs.getInt('user_id');
    if (userId == null ||
        (expectedUserId != null && userId != expectedUserId)) {
      return;
    }
    final delivery = metadata['delivery'] as Map;
    for (final oldId in (delivery['cancelled_content_ids'] as List? ?? [])) {
      if (oldId is String && RegExp(r'^[a-f0-9]{32}$').hasMatch(oldId)) {
        await _cancelRecord(userId, oldId);
      }
    }
    final key = '${userId}_$id';
    final pending = _pending[key];
    if (pending != null) return pending;
    final work = _deliver(content, userId, id, prefs.getString('app_language'));
    _pending[key] = work;
    try {
      await work;
    } finally {
      _pending.remove(key);
    }
  }

  Future<Map<String, dynamic>> _request(
    int userId,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.adaptive('/nudges/$id/delivery')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode({'user_id': userId, ...body}),
        )
        .timeout(ApiRequestTimeouts.fastRead);
    if (response.statusCode != 200) {
      throw Exception('Nudge delivery unavailable');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<bool> _sameSession(int userId, String? language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getInt('user_id') == userId &&
        prefs.getString('app_language') == language;
  }

  Future<void> _deliver(
    Map<String, dynamic> content,
    int userId,
    String id,
    String? language,
  ) async {
    String? token;
    bool deviceCompleted = false;
    try {
      final saved = await _read(userId, id);
      if ([
        'sent',
        'scheduled',
        'suppressed',
        'cancelled',
      ].contains(saved?['state'])) {
        // Retry only the acknowledgment, never the device alert.
        if (saved?['acknowledged'] != true &&
            saved?['token'] != null &&
            saved?['state'] != 'cancelled' &&
            await _sameSession(userId, language)) {
          deviceCompleted = true;
          await _acknowledge(userId, id, saved!);
        }
        return;
      }
      final claim = await _request(userId, id, {'operation': 'claim'});
      if (claim['claimed'] != true) return;
      token = claim['token']?.toString();
      final canonical = Map<String, dynamic>.from(
        claim['recommendation'] as Map,
      );
      final metadata = Map<String, dynamic>.from(canonical['metadata'] as Map);
      final delivery = Map<String, dynamic>.from(metadata['delivery'] as Map);
      if (!await _sameSession(userId, language)) return;
      if ((await _read(userId, id))?['state'] == 'cancelled') return;
      await _write(userId, id, {
        'content': canonical,
        'state': 'claimed',
        'token': token,
        'scheduled_for': delivery['scheduled_for'],
        'user_id': userId,
      });
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      final scheduledFor = DateTime.tryParse('${delivery['scheduled_for']}');
      final state = enabled
          ? await _show(
              id: notificationId(id),
              title: canonical['title'].toString(),
              body: canonical['message'].toString(),
              payload: payload(userId, id),
              scheduledFor: scheduledFor,
            )
          : 'suppressed';
      deviceCompleted = true;
      if (!await _sameSession(userId, language) ||
          (await _read(userId, id))?['state'] == 'cancelled') {
        await _cancel(notificationId(id));
        return;
      }
      // Store before acknowledging: an acknowledgment retry must never re-alert.
      final record = <String, dynamic>{
        'content': canonical,
        'state': state,
        'token': token,
        'scheduled_for': delivery['scheduled_for'],
        'user_id': userId,
      };
      await _write(userId, id, record);
      await _acknowledge(userId, id, record);
    } catch (_) {
      if (!deviceCompleted &&
          token != null &&
          await _sameSession(userId, language)) {
        try {
          await _request(userId, id, {
            'operation': 'failed',
            'token': token,
            'reason': 'device_delivery_failed',
          });
        } catch (_) {}
      }
      // The finalized card remains usable; a later delivery retry uses the same ID.
    }
  }

  Future<void> _acknowledge(
    int userId,
    String id,
    Map<String, dynamic> record,
  ) async {
    final result = await _request(userId, id, {
      'operation': record['state'],
      'token': record['token'],
      'reason': record['state'] == 'suppressed'
          ? 'notifications_disabled_or_unavailable'
          : null,
    });
    final state =
        ((result['recommendation'] as Map?)?['metadata'] as Map?)?['delivery'];
    if (state is Map && state['state'] == 'cancelled') {
      await _cancelRecord(userId, id);
    } else if ((await _read(userId, id))?['state'] != 'cancelled') {
      await _write(userId, id, {...record, 'acknowledged': true});
    }
    await invalidateNotificationFeedCache();
  }

  Future<void> _cancelRecord(int userId, String id) async {
    final saved = await _read(userId, id);
    await _write(userId, id, {
      ...?saved,
      'state': 'cancelled',
      'user_id': userId,
    });
    await _cancel(notificationId(id));
  }

  Future<void> cancelPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    final prefix = '$_ledgerPrefix${userId}_';
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(prefix)).toList()) {
      final id = key.substring(prefix.length);
      final record = await _read(userId, id);
      if (!['claimed', 'scheduled', 'pending'].contains(record?['state'])) {
        continue;
      }
      await _cancelRecord(userId, id);
      try {
        await _request(userId, id, {
          'operation': 'cancelled',
          'reason': 'context_changed',
        });
      } catch (_) {}
    }
  }

  Future<void> cancel(Map<String, dynamic> content) async {
    final id = (content['metadata'] as Map?)?['content_id']?.toString();
    if (id == null || !RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    await _cancelRecord(userId, id);
  }

  Future<Map<String, dynamic>?> readNotification(String value) async {
    final identity = parsePayload(value);
    if (identity == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (prefs.getInt('user_id') != identity.userId) return null;
    final saved = await _read(identity.userId, identity.contentId);
    if (saved?['content'] is Map) {
      return Map<String, dynamic>.from(saved!['content'] as Map);
    }
    try {
      final uri = Uri.parse(
        ApiConfig.adaptive('/nudges/${identity.contentId}'),
      ).replace(queryParameters: {'user_id': '${identity.userId}'});
      final response = await http
          .get(uri, headers: await ApiConfig.jsonHeaders())
          .timeout(ApiRequestTimeouts.fastRead);
      await prefs.reload();
      if (response.statusCode != 200 ||
          prefs.getInt('user_id') != identity.userId) {
        return null;
      }
      final raw = (jsonDecode(response.body) as Map)['recommendation'];
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (_) {
      return null;
    }
  }
}
