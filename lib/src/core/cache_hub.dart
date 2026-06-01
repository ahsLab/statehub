import 'hub.dart';
import 'async_value.dart';

enum CacheStrategy {
  networkFirst,
  cacheFirst,
  staleWhileRevalidate,
  cacheOnly,
  networkOnly,
}

abstract interface class CacheStorage<T> {
  Future<T?> read(String key);
  Future<void> write(String key, T value);
  Future<void> delete(String key);
  Future<bool> exists(String key);
  Future<DateTime?> lastUpdated(String key);
}

class MemoryCacheStorage<T> implements CacheStorage<T> {
  final _store = <String, (T value, DateTime time)>{};

  @override
  Future<T?> read(String key) async => _store[key]?.$1;

  @override
  Future<void> write(String key, T value) async =>
      _store[key] = (value, DateTime.now());

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<bool> exists(String key) async => _store.containsKey(key);

  @override
  Future<DateTime?> lastUpdated(String key) async => _store[key]?.$2;
}

class CacheHub<T> extends AsyncHub<T> {
  final String key;
  final Future<T> Function() fetcher;
  final CacheStrategy strategy;
  final Duration? ttl;
  final CacheStorage<T> _storage;

  CacheHub({
    required this.key,
    required this.fetcher,
    this.strategy = CacheStrategy.staleWhileRevalidate,
    this.ttl,
    CacheStorage<T>? storage,
  })  : _storage = storage ?? MemoryCacheStorage<T>(),
        super();

  bool _isCacheExpired(DateTime lastUpdated) {
    if (ttl == null) return false;
    return DateTime.now().difference(lastUpdated) > ttl!;
  }

  Future<T?> fetch() async {
    switch (strategy) {
      case CacheStrategy.networkOnly:
        return run(fetcher);

      case CacheStrategy.cacheOnly:
        final cached = await _storage.read(key);
        if (cached != null) {
          set(AsyncValue.data(cached));
          return cached;
        }
        set(AsyncValue.error(CacheException('No cache found for key: $key')));
        return null;

      case CacheStrategy.networkFirst:
        try {
          final result = await fetcher();
          await _storage.write(key, result);
          set(AsyncValue.data(result));
          return result;
        } catch (e, st) {
          final cached = await _storage.read(key);
          if (cached != null) {
            set(AsyncValue.data(cached));
            return cached;
          }
          set(AsyncValue.error(e, stackTrace: st));
          return null;
        }

      case CacheStrategy.cacheFirst:
        final cached = await _storage.read(key);
        final lastUpdated = await _storage.lastUpdated(key);
        final isExpired =
            lastUpdated == null || _isCacheExpired(lastUpdated);
        if (cached != null && !isExpired) {
          set(AsyncValue.data(cached));
          return cached;
        }
        return run(() async {
          final result = await fetcher();
          await _storage.write(key, result);
          return result;
        });

      case CacheStrategy.staleWhileRevalidate:
        final cached = await _storage.read(key);
        if (cached != null) {
          set(AsyncValue.data(cached));
        } else {
          set(const AsyncValue.loading());
        }
        try {
          final result = await fetcher();
          await _storage.write(key, result);
          set(AsyncValue.data(result));
          return result;
        } catch (e, st) {
          if (cached == null) {
            set(AsyncValue.error(e, stackTrace: st));
          }
          return cached;
        }
    }
  }

  Future<T?> invalidate() async {
    await _storage.delete(key);
    return fetch();
  }

  Future<void> optimisticUpdate(
    T optimisticValue,
    Future<T> Function() operation,
  ) async {
    final previous = value;
    set(AsyncValue.data(optimisticValue));
    try {
      final result = await operation();
      await _storage.write(key, result);
      set(AsyncValue.data(result));
    } catch (e, st) {
      set(previous);
      throw AsyncError<T>(e, stackTrace: st);
    }
  }
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}
