// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:cocoon_service/src/service/cache_service.dart';

/// A [CacheService] that doesn't actually cache anything.
class FakeCacheService extends CacheService {
  FakeCacheService();

  @override
  Future<Uint8List?> get(String subcacheName, String key) async => null;

  @override
  Future<List<Uint8List?>> getMulti(
    String subcacheName,
    List<String> keys,
  ) async {
    return List.filled(keys.length, null);
  }

  @override
  Future<void> insertVersioned(
    String subcacheName,
    List<VersionedCacheEntry> entries,
  ) async {}

  @override
  Future<Set<String>> getSet(String subcacheName, String key) async => const {};

  @override
  Future<void> updateSet(
    String subcacheName,
    String key,
    Set<String> values, {
    Duration ttl = const Duration(hours: 12),
  }) async {}

  @override
  Future<bool> addToSetIfExists(
    String subcacheName,
    String key,
    String value,
  ) async => false;

  @override
  Future<void> dispose() async {}

  @override
  Future<Uint8List?> getOrCreate(
    String subcacheName,
    String key, {
    required Future<Uint8List> Function()? createFn,
    Duration ttl = const Duration(minutes: 1),
  }) async {
    return createFn?.call();
  }

  @override
  Future<Uint8List?> set(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    return value;
  }

  @override
  Future<void> purge(String subcacheName, String key) async {}

  @override
  Future<bool> setIfNotExists(
    String subcacheName,
    String key,
    Uint8List value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    return true;
  }

  @override
  Future<bool> tryLock(
    String key,
    FutureOr<void> Function() block,
    Duration ttl, [
    int retries = 5,
  ]) async {
    await block();
    return true;
  }
}
