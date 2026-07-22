import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/shared/offline/fetch_policy.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fresh cache returns immediately without fetching', () async {
    await OfflineCacheStore.saveJson(
      namespace: 'policy',
      scope: 'fresh',
      data: {'value': 'cached'},
    );

    var fetchCount = 0;
    final result = await CachedJsonFetch.load<String>(
      namespace: 'policy',
      scope: 'fresh',
      policy: FetchPolicy.perMinute,
      parser: _valueParser,
      fetcher: () async {
        fetchCount++;
        return {'value': 'remote'};
      },
    );

    expect(result?.data, 'cached');
    expect(result?.isFromCache, isTrue);
    expect(result?.isStale, isFalse);
    expect(result?.refresh, isNull);
    expect(fetchCount, 0);
  });

  test(
    'stale cache returns immediately and refreshes in the background',
    () async {
      await _writeSnapshot(
        namespace: 'policy',
        scope: 'stale',
        cachedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        data: {'value': 'cached'},
      );
      final remote = Completer<Map<String, dynamic>>();
      var fetchCount = 0;

      final result = await CachedJsonFetch.load<String>(
        namespace: 'policy',
        scope: 'stale',
        policy: FetchPolicy.perMinute,
        parser: _valueParser,
        fetcher: () {
          fetchCount++;
          return remote.future;
        },
      );

      expect(result?.data, 'cached');
      expect(result?.isFromCache, isTrue);
      expect(result?.isStale, isTrue);
      expect(result?.isRefreshing, isTrue);
      expect(fetchCount, 1);

      remote.complete({'value': 'remote'});
      expect(await result!.refresh, 'remote');

      final cached = await OfflineCacheStore.readLatestJson(
        namespace: 'policy',
        scope: 'stale',
      );
      expect(cached?['value'], 'remote');
    },
  );

  test('forced refresh bypasses fresh cache', () async {
    await OfflineCacheStore.saveJson(
      namespace: 'policy',
      scope: 'force',
      data: {'value': 'cached'},
    );

    final result = await CachedJsonFetch.load<String>(
      namespace: 'policy',
      scope: 'force',
      policy: FetchPolicy.perMinute,
      parser: _valueParser,
      forceRefresh: true,
      fetcher: () async => {'value': 'remote'},
    );

    expect(result?.data, 'remote');
    expect(result?.isFromCache, isFalse);
    expect(result?.isStale, isFalse);
  });

  test('namespace invalidation clears only matching cache keys', () async {
    await OfflineCacheStore.saveJson(
      namespace: 'policy',
      scope: 'one',
      data: {'value': 'one'},
    );
    await OfflineCacheStore.saveJson(
      namespace: 'policy',
      scope: 'two',
      data: {'value': 'two'},
    );
    await OfflineCacheStore.saveJson(
      namespace: 'other_policy',
      scope: 'one',
      data: {'value': 'kept'},
    );

    await CachedJsonFetch.invalidateNamespace(namespace: 'policy');

    expect(
      await OfflineCacheStore.readLatestJson(namespace: 'policy', scope: 'one'),
      isNull,
    );
    expect(
      await OfflineCacheStore.readLatestJson(namespace: 'policy', scope: 'two'),
      isNull,
    );
    expect(
      await OfflineCacheStore.readLatestJson(
        namespace: 'other_policy',
        scope: 'one',
      ),
      {'value': 'kept'},
    );
  });

  test('scope prefix invalidation clears only related query ranges', () async {
    await OfflineCacheStore.saveJson(
      namespace: 'burnout_history',
      scope: '7_today_30',
      data: {'value': 'current'},
    );
    await OfflineCacheStore.saveJson(
      namespace: 'burnout_history',
      scope: '7_last_week_30',
      data: {'value': 'older'},
    );
    await OfflineCacheStore.saveJson(
      namespace: 'burnout_history',
      scope: '8_today_30',
      data: {'value': 'other-user'},
    );

    await OfflineCacheStore.removeScopePrefix(
      namespace: 'burnout_history',
      scopePrefix: '7_',
    );

    expect(
      await OfflineCacheStore.readLatestJson(
        namespace: 'burnout_history',
        scope: '7_today_30',
      ),
      isNull,
    );
    expect(
      await OfflineCacheStore.readLatestJson(
        namespace: 'burnout_history',
        scope: '7_last_week_30',
      ),
      isNull,
    );
    expect(
      await OfflineCacheStore.readLatestJson(
        namespace: 'burnout_history',
        scope: '8_today_30',
      ),
      {'value': 'other-user'},
    );
  });

  test('timeout policies expose the intended slow lanes', () {
    expect(ApiRequestTimeouts.fastRead, const Duration(seconds: 12));
    expect(ApiRequestTimeouts.standard, const Duration(seconds: 30));
    expect(ApiRequestTimeouts.coldStart, const Duration(seconds: 60));
    expect(ApiRequestTimeouts.aiAnalysis, const Duration(seconds: 90));
    expect(FetchPolicy.fiveMinutes.maxAge, const Duration(minutes: 5));
    expect(
      FetchPolicy.tenMinutesPlus.maxAge,
      greaterThanOrEqualTo(const Duration(minutes: 10)),
    );
  });
}

String _valueParser(Map<String, dynamic> data) {
  return data['value']?.toString() ?? '';
}

Future<void> _writeSnapshot({
  required String namespace,
  required String scope,
  required DateTime cachedAt,
  required Map<String, dynamic> data,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'offline_cache_v1_${namespace}_$scope',
    jsonEncode([
      {'cached_at': cachedAt.toIso8601String(), 'data': data},
    ]),
  );
}
