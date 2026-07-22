import 'dart:async';

import 'offline_cache_store.dart';

enum FetchFreshnessTier { seconds, perMinute, fiveMinutes, tenMinutesPlus }

typedef JsonParser<T> = T Function(Map<String, dynamic> json);
typedef JsonFetcher = Future<Map<String, dynamic>> Function();

class ApiRequestTimeouts {
  const ApiRequestTimeouts._();

  static const Duration fastRead = Duration(seconds: 12);
  static const Duration standard = Duration(seconds: 30);
  static const Duration coldStart = Duration(seconds: 60);
  static const Duration aiAnalysis = Duration(seconds: 90);
}

class FetchPolicy {
  final FetchFreshnessTier tier;
  final Duration maxAge;
  final Duration requestTimeout;

  const FetchPolicy({
    required this.tier,
    required this.maxAge,
    required this.requestTimeout,
  });

  static const seconds = FetchPolicy(
    tier: FetchFreshnessTier.seconds,
    maxAge: Duration(seconds: 15),
    requestTimeout: ApiRequestTimeouts.fastRead,
  );

  static const perMinute = FetchPolicy(
    tier: FetchFreshnessTier.perMinute,
    maxAge: Duration(minutes: 1),
    requestTimeout: ApiRequestTimeouts.fastRead,
  );

  static const fiveMinutes = FetchPolicy(
    tier: FetchFreshnessTier.fiveMinutes,
    maxAge: Duration(minutes: 5),
    requestTimeout: ApiRequestTimeouts.standard,
  );

  static const tenMinutesPlus = FetchPolicy(
    tier: FetchFreshnessTier.tenMinutesPlus,
    maxAge: Duration(minutes: 10),
    requestTimeout: ApiRequestTimeouts.coldStart,
  );
}

class CachedFetchResult<T> {
  final T data;
  final bool isFromCache;
  final bool isStale;
  final DateTime? cachedAt;
  final Future<T>? refresh;

  const CachedFetchResult({
    required this.data,
    required this.isFromCache,
    required this.isStale,
    required this.cachedAt,
    this.refresh,
  });

  bool get isRefreshing => refresh != null;
}

class CachedJsonFetch {
  const CachedJsonFetch._();

  static Future<CachedFetchResult<T>?> load<T>({
    required String namespace,
    required String scope,
    required FetchPolicy policy,
    required JsonParser<T> parser,
    required JsonFetcher fetcher,
    bool forceRefresh = false,
  }) async {
    final cached = await OfflineCacheStore.readLatestJsonSnapshot(
      namespace: namespace,
      scope: scope,
    );
    final cachedData = cached?.data;
    final parsedCached = cachedData == null ? null : parser(cachedData);
    final isFresh = cached?.isFresh(policy.maxAge) == true;

    if (!forceRefresh && parsedCached != null && isFresh) {
      return CachedFetchResult<T>(
        data: parsedCached,
        isFromCache: true,
        isStale: false,
        cachedAt: cached?.cachedAt,
      );
    }

    Future<T> refresh() async {
      final data = await fetcher().timeout(policy.requestTimeout);
      await OfflineCacheStore.saveJson(
        namespace: namespace,
        scope: scope,
        data: data,
      );
      return parser(data);
    }

    if (!forceRefresh && parsedCached != null) {
      return CachedFetchResult<T>(
        data: parsedCached,
        isFromCache: true,
        isStale: true,
        cachedAt: cached?.cachedAt,
        refresh: refresh(),
      );
    }

    final data = await refresh();
    return CachedFetchResult<T>(
      data: data,
      isFromCache: false,
      isStale: false,
      cachedAt: null,
    );
  }

  static Future<void> invalidate({
    required String namespace,
    required String scope,
  }) {
    return OfflineCacheStore.remove(namespace: namespace, scope: scope);
  }

  static Future<void> invalidateNamespace({required String namespace}) {
    return OfflineCacheStore.removeNamespace(namespace: namespace);
  }
}
