import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/config/api_config.dart';
import '../../../../shared/offline/fetch_policy.dart';
import '../../../../shared/preferences/user_session.dart';
import 'quick_check_in_preset.dart';

class QuickCheckInPresetException implements Exception {
  const QuickCheckInPresetException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuickCheckInPresetApi {
  QuickCheckInPresetApi({http.Client? client})
    : _client = client ?? http.Client();

  static final instance = QuickCheckInPresetApi();
  static const cacheKeyPrefix = 'quick_check_in_presets_v1_';

  final http.Client _client;
  final ValueNotifier<QuickCheckInPreset?> createdPresets = ValueNotifier(null);
  final Map<int, int> _mutationVersions = {};

  Future<int> _userId() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      throw const QuickCheckInPresetException('Missing logged-in user');
    }
    return userId;
  }

  String _cacheKey(int userId) => '$cacheKeyPrefix$userId';

  Future<List<QuickCheckInPreset>> readCache() async {
    final userId = await _userId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(userId));
    if (raw == null) return const [];
    try {
      return _decodePresetList(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  Future<List<QuickCheckInPreset>> fetch() async {
    final userId = await _userId();
    final version = _mutationVersions[userId] ?? 0;
    late http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(ApiConfig.logs('/check-in-presets')),
            headers: await ApiConfig.acceptJsonHeaders(),
          )
          .timeout(ApiRequestTimeouts.standard);
    } catch (_) {
      throw const QuickCheckInPresetException(
        'Unable to sync quick check-ins. Showing saved presets when available.',
      );
    }
    final data = _decodeMap(response.body);
    if (response.statusCode != 200) {
      throw QuickCheckInPresetException(
        data['message']?.toString() ?? 'Unable to load quick check-ins.',
      );
    }
    final presets = _decodePresetList(data['presets']);
    final wroteCache = await _writeCache(
      userId,
      presets,
      expectedVersion: version,
    );
    return wroteCache ? presets : readCache();
  }

  Future<QuickCheckInPreset> create(QuickCheckInPreset preset) async {
    final userId = await _userId();
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConfig.logs('/check-in-presets')),
            headers: await ApiConfig.jsonHeaders(),
            body: jsonEncode(preset.toMutationJson()),
          )
          .timeout(ApiRequestTimeouts.standard);
    } catch (_) {
      throw const QuickCheckInPresetException(
        'Connect to the internet to create this quick check-in.',
      );
    }
    final data = _decodeMap(response.body);
    if (response.statusCode != 201 || data['preset'] is! Map) {
      throw QuickCheckInPresetException(
        data['message']?.toString() ??
            'Connect to the internet to create this quick check-in.',
      );
    }
    final created = QuickCheckInPreset.fromJson(
      Map<String, dynamic>.from(data['preset'] as Map),
    );
    _mutationVersions[userId] = (_mutationVersions[userId] ?? 0) + 1;
    final cached = await readCache();
    await _writeCache(userId, [
      ...cached.where((item) => item.presetId != created.presetId),
      created,
    ]);
    createdPresets.value = created;
    return created;
  }

  Future<QuickCheckInPreset> update(QuickCheckInPreset preset) async {
    final userId = await _userId();
    late http.Response response;
    try {
      response = await _client
          .put(
            Uri.parse(ApiConfig.logs('/check-in-presets/${preset.presetId}')),
            headers: await ApiConfig.jsonHeaders(),
            body: jsonEncode(preset.toMutationJson()),
          )
          .timeout(ApiRequestTimeouts.standard);
    } catch (_) {
      throw const QuickCheckInPresetException(
        'Connect to the internet to update this quick check-in.',
      );
    }
    final data = _decodeMap(response.body);
    if (response.statusCode != 200 || data['preset'] is! Map) {
      throw QuickCheckInPresetException(
        data['message']?.toString() ??
            'Connect to the internet to update this quick check-in.',
      );
    }
    final updated = QuickCheckInPreset.fromJson(
      Map<String, dynamic>.from(data['preset'] as Map),
    );
    _mutationVersions[userId] = (_mutationVersions[userId] ?? 0) + 1;
    final cached = await readCache();
    final containsUpdated = cached.any(
      (item) => item.presetId == updated.presetId,
    );
    await _writeCache(userId, [
      for (final item in cached)
        if (item.presetId == updated.presetId) updated else item,
      if (!containsUpdated) updated,
    ]);
    return updated;
  }

  Future<void> delete(int presetId) async {
    final userId = await _userId();
    late http.Response response;
    try {
      response = await _client
          .delete(
            Uri.parse(ApiConfig.logs('/check-in-presets/$presetId')),
            headers: await ApiConfig.acceptJsonHeaders(),
          )
          .timeout(ApiRequestTimeouts.standard);
    } catch (_) {
      throw const QuickCheckInPresetException(
        'Connect to the internet to delete this quick check-in.',
      );
    }
    final data = _decodeMap(response.body);
    if (response.statusCode != 200) {
      throw QuickCheckInPresetException(
        data['message']?.toString() ??
            'Connect to the internet to delete this quick check-in.',
      );
    }
    _mutationVersions[userId] = (_mutationVersions[userId] ?? 0) + 1;
    final cached = await readCache();
    await _writeCache(
      userId,
      cached.where((item) => item.presetId != presetId).toList(),
    );
  }

  Future<bool> _writeCache(
    int userId,
    List<QuickCheckInPreset> presets, {
    int? expectedVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (expectedVersion != null &&
        expectedVersion != (_mutationVersions[userId] ?? 0)) {
      return false;
    }
    await prefs.setString(
      _cacheKey(userId),
      jsonEncode(presets.map((item) => item.toJson()).toList()),
    );
    return true;
  }

  List<QuickCheckInPreset> _decodePresetList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              QuickCheckInPreset.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.presetId > 0 && item.name.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
