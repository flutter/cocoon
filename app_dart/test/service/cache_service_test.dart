// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/service/cache_service.dart';

void main() {
  group('CacheService', () {
    CacheService cache;

    const String testSubcacheName = 'test';

    setUp(() {
      cache = CacheService(inMemory: true, inMemoryMaxNumberEntries: 1);
    });

    test('returns null when no value exists', () async {
      final Uint8List value = await cache.getOrCreate(testSubcacheName, 'abc');

      expect(value, isNull);
    });

    test('returns value when it exists', () async {
      const String testKey = 'abc';
      final Uint8List expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.set(testSubcacheName, testKey, expectedValue);

      final Uint8List value =
          await cache.getOrCreate(testSubcacheName, testKey);

      expect(value, expectedValue);
    });

    test('last used value is rotated out of cache if cache is full', () async {
      const String testKey1 = 'abc';
      const String testKey2 = 'def';
      final Uint8List expectedValue1 = Uint8List.fromList('123'.codeUnits);
      final Uint8List expectedValue2 = Uint8List.fromList('456'.codeUnits);

      await cache.set(testSubcacheName, testKey1, expectedValue1);
      await cache.set(testSubcacheName, testKey2, expectedValue2);

      final Uint8List value1 =
          await cache.getOrCreate(testSubcacheName, testKey1);
      expect(value1, null);

      final Uint8List value2 =
          await cache.getOrCreate(testSubcacheName, testKey2);
      expect(value2, expectedValue2);
    });

    test('retries when get throws exception', () async {
      final Cache<Uint8List> mockMainCache = MockCache();
      final Cache<Uint8List> mockTestSubcache = MockCache();
      when<Cache<Uint8List>>(mockMainCache.withPrefix(any))
          .thenReturn(mockTestSubcache);

      int getCallCount = 0;
      final Entry<Uint8List> entry = FakeEntry();
      // Only on the first call do we want it to throw the exception.
      when(mockTestSubcache[any]).thenAnswer((Invocation invocation) =>
          getCallCount++ < 1
              ? throw Exception('simulate stream sink error')
              : entry);

      cache.cacheValue = mockMainCache;

      final Uint8List value =
          await cache.getOrCreate(testSubcacheName, 'does not matter');
      verify(mockTestSubcache[any]).called(2);
      expect(value, Uint8List.fromList('abc123'.codeUnits));
    });

    test('returns null if reaches max attempts of retries', () async {
      final Cache<Uint8List> mockMainCache = MockCache();
      final Cache<Uint8List> mockTestSubcache = MockCache();
      when<Cache<Uint8List>>(mockMainCache.withPrefix(any))
          .thenReturn(mockTestSubcache);

      int getCallCount = 0;
      final Entry<Uint8List> entry = FakeEntry();
      // Always throw exception until max retries
      when(mockTestSubcache[any]).thenAnswer((Invocation invocation) =>
          getCallCount++ < CacheService.maxCacheGetAttempts
              ? throw Exception('simulate stream sink error')
              : entry);

      cache.cacheValue = mockMainCache;

      final Uint8List value =
          await cache.getOrCreate(testSubcacheName, 'does not matter');
      verify(mockTestSubcache[any]).called(CacheService.maxCacheGetAttempts);
      expect(value, isNull);
    });

    test('creates value if given createFn', () async {
      final Uint8List cat = Uint8List.fromList('cat'.codeUnits);
      Future<Uint8List> createCat() async => cat;

      final Uint8List value =
          await cache.getOrCreate(testSubcacheName, 'dog', createFn: createCat);

      expect(value, cat);
    });

    test('purge removes value', () async {
      const String testKey = 'abc';
      final Uint8List expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.set(testSubcacheName, testKey, expectedValue);

      final Uint8List value =
          await cache.getOrCreate(testSubcacheName, testKey);

      expect(value, expectedValue);

      await cache.purge(testSubcacheName, testKey);

      final Uint8List valueAfterPurge =
          await cache.getOrCreate(testSubcacheName, testKey);
      expect(valueAfterPurge, isNull);
    });

    test('sets ttl from set', () async {
      final Cache<Uint8List> mockMainCache = MockCache();
      final Cache<Uint8List> mockTestSubcache = MockCache();
      when<Cache<Uint8List>>(mockMainCache.withPrefix(any))
          .thenReturn(mockTestSubcache);

      final Entry<Uint8List> entry = MockEntry();
      when(mockTestSubcache[any]).thenAnswer((Invocation invocation) => entry);
      cache.cacheValue = mockMainCache;

      verifyNever(entry.set(any, any));

      const Duration testDuration = Duration(days: 40);
      await cache.set(
          testSubcacheName, 'fish', Uint8List.fromList('bigger fish'.codeUnits),
          ttl: testDuration);

      verify(entry.set(any, testDuration)).called(1);
    });

    test('sets ttl is passed through correctly from createFn', () async {
      final Cache<Uint8List> mockMainCache = MockCache();
      final Cache<Uint8List> mockTestSubcache = MockCache();
      when<Cache<Uint8List>>(mockMainCache.withPrefix(any))
          .thenReturn(mockTestSubcache);

      final Entry<Uint8List> entry = MockEntry();
      when(mockTestSubcache[any]).thenAnswer((Invocation invocation) => entry);
      cache.cacheValue = mockMainCache;

      verifyNever(entry.set(any, any));

      const Duration testDuration = Duration(days: 40);
      await cache.getOrCreate(testSubcacheName, 'fish',
          createFn: () async => Uint8List.fromList(
                'bigger fish'.codeUnits,
              ),
          ttl: testDuration);

      verify(entry.set(any, testDuration)).called(1);
    });
  });
}

class MockCache extends Mock implements Cache<Uint8List> {}

class FakeEntry extends Entry<Uint8List> {
  Uint8List value = Uint8List.fromList('abc123'.codeUnits);

  @override
  Future<Uint8List> get(
          [Future<Uint8List> Function() create, Duration ttl]) async =>
      value;

  @override
  Future<void> purge({int retries = 0}) => throw UnimplementedError();

  @override
  Future<Uint8List> set(Uint8List value, [Duration ttl]) async {
    value = value;

    return value;
  }
}

class MockEntry extends Mock implements FakeEntry {}
