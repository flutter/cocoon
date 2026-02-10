// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:cocoon_service/src/service/cache_service.dart';

/// A [CacheService] that doesn't actually cache anything.
class FakeCacheService extends CacheService {
  FakeCacheService() : super(inMemory: true);

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
  Future<Uint8List?> getOrCreateWithLocking(
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
  Future<Uint8List?> setWithLocking(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    return value;
  }

  @override
  Future<void> purge(String subcacheName, String key) async {}
}
