// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';
import 'package:mutex/mutex.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:retry/retry.dart';

/// Service for reading and writing values to a cache for quick access of data.
///
/// If [inMemory] is true, a cache with [inMemoryMaxNumberEntries] number
/// of entries will be created. Otherwise, it will use the default redis cache.
class CacheService {
  CacheService({bool inMemory = false, int inMemoryMaxNumberEntries = 256})
    : _provider =
          inMemory
              ? Cache.inMemoryCacheProvider(inMemoryMaxNumberEntries)
              : Cache.redisCacheProvider(memorystoreUri);

  final Mutex m = Mutex();

  final CacheProvider<List<int>> _provider;

  Cache<Uint8List> get cache =>
      cacheValue ??
      Cache<List<int>>(_provider).withCodec<Uint8List>(const _CacheCodec());

  @visibleForTesting
  Cache<Uint8List>? cacheValue;

  /// Google Cloud Memorystore default url.
  static Uri memorystoreUri = Uri.parse('redis://10.0.0.4:6379');

  /// An arbritary number for how many times we should try to get from cache
  /// before giving up.
  ///
  /// Writing to the cache creates a racy condition for when another operation
  /// is trying to get the same key. This race condition throws an exception.
  @visibleForTesting
  static const int maxCacheGetAttempts = 3;

  /// Get value of [key] from the subcache [subcacheName]. If the key has no
  /// value, call [createFn] to create a value for it, set it, and return it.
  ///
  /// The underlying cache get function is inherently racy as if there is a
  /// write operation while a read operation, getting the value can fail. To
  /// handle this racy condition, this attempts to get the value [maxCacheGetAttempts]
  /// times before giving up. This is because the cache is magnitudes faster
  /// than the fallback operation (usually a Datastore query).
  Future<Uint8List?> getOrCreate(
    String subcacheName,
    String key, {
    required Future<Uint8List> Function()? createFn,
    Duration ttl = const Duration(minutes: 1),
  }) async {
    var value = await _readValue(subcacheName, key);

    // If given createFn, update the cache value if the value returned was null.
    if (createFn != null && value == null) {
      // Try creating the value
      value = await createFn();
      await set(subcacheName, key, value, ttl: ttl);
    }

    return value;
  }

  /// This method is the same as the [getOrCreate] method above except that it
  /// enforces locking access.
  ///
  /// Note: these methods are intended to prevent issues around race conditions
  /// when storing and retrieving github tokens locally only for this instance.
  /// Care should be taken to use the locking methods together when accessing
  /// data from an entity using the cache.
  Future<Uint8List?> getOrCreateWithLocking(
    String subcacheName,
    String key, {
    required Future<Uint8List> Function()? createFn,
    Duration ttl = const Duration(minutes: 1),
  }) async {
    var value = await _readValue(subcacheName, key);

    // If given createFn, update the cache value if the value returned was null.
    if (createFn != null && value == null) {
      // Try creating the value
      value = await createFn();
      await setWithLocking(subcacheName, key, value, ttl: ttl);
    }

    return value;
  }

  Future<Uint8List?> _readValue(String subcacheName, String key) async {
    final subcache = cache.withPrefix(subcacheName);
    Uint8List? value;

    const r = RetryOptions(
      maxAttempts: maxCacheGetAttempts,
      delayFactor: Duration(milliseconds: 50),
    );

    try {
      await r.retry(() async {
        value = await subcache[key].get();
      });
    } catch (e) {
      // If the last retry is unsuccessful on an exception we do not want to die
      // here.
      log.warn('Unable to retrieve value for $key from cache.', e);
      value = null;
    }

    return value;
  }

  /// Set [value] for [key] in the subcache [subcacheName] with [ttl].
  Future<Uint8List?> set(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    final subcache = cache.withPrefix(subcacheName);
    final entry = subcache[key];
    return entry.set(value, ttl);
  }

  /// Set [value] for [key] in the subcache [subcacheName] with [ttl] but
  /// enforce locking accessing.
  ///
  /// Note: these methods are intended to prevent issues around race conditions
  /// when storing and retrieving github tokens. Care should be taken to use the
  /// locking methods together when accessing data from an entity using the
  /// cache.
  Future<Uint8List?> setWithLocking(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    await m.acquire();
    try {
      return set(subcacheName, key, value, ttl: ttl);
    } finally {
      m.release();
    }
  }

  /// Clear the value stored in subcache [subcacheName] for key [key].
  ///
  /// Note: these methods are intended to prevent issues around race conditions
  /// when storing and retrieving github tokens. Care should be taken to use the
  /// locking methods together when accessing data from an entity using the
  /// cache.
  Future<void> purge(String subcacheName, String key) async {
    await m.acquire();
    try {
      final subcache = cache.withPrefix(subcacheName);
      return subcache[key].purge(retries: maxCacheGetAttempts);
    } finally {
      m.release();
    }
  }

  Future<void> dispose() async {
    await _provider.close();
  }
}

class _CacheCodec extends Codec<Uint8List, List<int>> {
  const _CacheCodec();

  @override
  Converter<Uint8List, List<int>> get encoder => const _ListIntConverter();

  @override
  Converter<List<int>, Uint8List> get decoder => const _Uint8ListConverter();
}

class _ListIntConverter extends Converter<Uint8List, List<int>> {
  const _ListIntConverter();

  @override
  List<int> convert(Uint8List input) => input;
}

class _Uint8ListConverter extends Converter<List<int>, Uint8List> {
  const _Uint8ListConverter();

  @override
  Uint8List convert(List<int> input) => Uint8List.fromList(input);
}
