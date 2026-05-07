import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheStore {
  static const int maxSnapshots = 2;
  static const String _keyPrefix = 'offline_cache_v1';

  const OfflineCacheStore._();

  static Future<void> saveJson({
    required String namespace,
    required String scope,
    required Map<String, dynamic> data,
  }) async {
    final snapshots = await _readSnapshots(namespace: namespace, scope: scope);
    final normalizedData = Map<String, dynamic>.from(data);

    if (snapshots.isNotEmpty &&
        _sameJson(snapshots.first['data'], normalizedData)) {
      snapshots[0] = _snapshot(normalizedData);
    } else {
      snapshots.insert(0, _snapshot(normalizedData));
    }

    await _writeSnapshots(
      namespace: namespace,
      scope: scope,
      snapshots: snapshots.take(maxSnapshots).toList(),
    );
  }

  static Future<Map<String, dynamic>?> readLatestJson({
    required String namespace,
    required String scope,
  }) async {
    final snapshots = await _readSnapshots(namespace: namespace, scope: scope);
    if (snapshots.isEmpty) {
      return null;
    }

    final data = snapshots.first['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<Map<String, dynamic>?> readPreviousJson({
    required String namespace,
    required String scope,
  }) async {
    final snapshots = await _readSnapshots(namespace: namespace, scope: scope);
    if (snapshots.length < 2) {
      return null;
    }

    final data = snapshots[1]['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> remove({
    required String namespace,
    required String scope,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(namespace, scope));
  }

  static Future<List<Map<String, dynamic>>> _readSnapshots({
    required String namespace,
    required String scope,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(namespace, scope));
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => item['data'] is Map)
          .take(maxSnapshots)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeSnapshots({
    required String namespace,
    required String scope,
    required List<Map<String, dynamic>> snapshots,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(namespace, scope),
      jsonEncode(snapshots.take(maxSnapshots).toList()),
    );
  }

  static Map<String, dynamic> _snapshot(Map<String, dynamic> data) {
    return {'cached_at': DateTime.now().toIso8601String(), 'data': data};
  }

  static String _cacheKey(String namespace, String scope) {
    return '${_keyPrefix}_${namespace}_$scope';
  }

  static bool _sameJson(dynamic first, dynamic second) {
    try {
      return jsonEncode(first) == jsonEncode(second);
    } catch (_) {
      return false;
    }
  }
}
