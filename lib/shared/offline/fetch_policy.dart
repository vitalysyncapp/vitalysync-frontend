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

  static final Map<String, Future<Object?>> _inFlightRefreshes = {};

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
    T? parsedCached;
    if (cachedData != null) {
      try {
        parsedCached = parser(cachedData);
      } catch (_) {
        // A model change or interrupted write should not prevent a fresh load.
        await OfflineCacheStore.remove(namespace: namespace, scope: scope);
      }
    }
    final isFresh = cached?.isFresh(policy.maxAge) == true;

    if (!forceRefresh && parsedCached != null && isFresh) {
      return CachedFetchResult<T>(
        data: parsedCached,
        isFromCache: true,
        isStale: false,
        cachedAt: cached?.cachedAt,
      );
    }

    Future<T> refresh() => _refreshOnce(
      namespace: namespace,
      scope: scope,
      policy: policy,
      parser: parser,
      fetcher: fetcher,
    );

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

  static Future<T> _refreshOnce<T>({
    required String namespace,
    required String scope,
    required FetchPolicy policy,
    required JsonParser<T> parser,
    required JsonFetcher fetcher,
  }) {
    final requestKey = '$namespace::$scope';
    final pending = _inFlightRefreshes[requestKey];
    if (pending != null) {
      return pending.then((value) => value as T);
    }

    late final Future<T> request;
    request =
        () async {
          final data = await fetcher().timeout(policy.requestTimeout);
          final parsed = parser(data);
          await OfflineCacheStore.saveJson(
            namespace: namespace,
            scope: scope,
            data: data,
          );
          return parsed;
        }().whenComplete(() {
          if (identical(_inFlightRefreshes[requestKey], request)) {
            _inFlightRefreshes.remove(requestKey);
          }
        });
    _inFlightRefreshes[requestKey] = request;
    return request;
  }
}
