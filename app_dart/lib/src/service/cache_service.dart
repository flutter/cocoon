// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';

class CacheService {
  CacheService({
    bool inMemory = false,
    int inMemoryMaxSize = 256,
  }) : _provider = inMemory
            ? Cache.inMemoryCacheProvider(inMemoryMaxSize)
            : Cache.redisCacheProvider(memorystoreUrl);

  final CacheProvider<List<int>> _provider;

  Cache<Uint8List> get cache =>
      cacheValue ??
      Cache<List<int>>(_provider).withCodec<Uint8List>(const _CacheCodec());

  @visibleForTesting
  Cache<Uint8List> cacheValue;

  /// Google Cloud Memorystore default url.
  static const String memorystoreUrl = 'redis://10.0.0.4:6379';

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
  Future<Uint8List> get(
    String subcacheName,
    String key, {
    int attempt = 1,
    Future<Uint8List> Function() createFn,
    Duration ttl = const Duration(minutes: 1),
  }) async {
    final Cache<Uint8List> subcache = cache.withPrefix(subcacheName);
    Uint8List value;

    try {
      value = await subcache[key].get();
    } catch (e) {
      if (attempt < maxCacheGetAttempts) {
        return get(subcacheName, key, attempt: ++attempt);
      } else {
        // Give up on trying to get the value from the cache.
        value = null;
      }
    }

    if (value == null && createFn != null) {
      // Try creating the value
      value = await createFn();
      await set(subcacheName, key, value, ttl: ttl);
    }

    return value;
  }

  /// Set [value] for [key] in the subcache [subcacheName] with [ttl].
  Future<Uint8List> set(
    String subcacheName,
    String key,
    Uint8List value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    final Cache<Uint8List> subcache = cache.withPrefix(subcacheName);
    return subcache[key].set(value);
  }

  void dispose() {
    _provider.close();
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
