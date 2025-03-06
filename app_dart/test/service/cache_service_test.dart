// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:mockito/mockito.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import '../src/utilities/mocks.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;

    const testSubcacheName = 'test';

    setUp(() {
      cache = CacheService(inMemory: true, inMemoryMaxNumberEntries: 1);
    });

    test('returns null when no value exists', () async {
      final value = await cache.getOrCreate(
        testSubcacheName,
        'abc',
        createFn: null,
      );

      expect(value, isNull);
    });

    test('returns value when it exists', () async {
      const testKey = 'abc';
      final expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.set(testSubcacheName, testKey, expectedValue);

      final value = await cache.getOrCreate(
        testSubcacheName,
        testKey,
        createFn: null,
      );

      expect(value, expectedValue);
    });

    test('last used value is rotated out of cache if cache is full', () async {
      const testKey1 = 'abc';
      const testKey2 = 'def';
      final expectedValue1 = Uint8List.fromList('123'.codeUnits);
      final expectedValue2 = Uint8List.fromList('456'.codeUnits);

      await cache.set(testSubcacheName, testKey1, expectedValue1);
      await cache.set(testSubcacheName, testKey2, expectedValue2);

      final value1 = await cache.getOrCreate(
        testSubcacheName,
        testKey1,
        createFn: null,
      );
      expect(value1, null);

      final value2 = await cache.getOrCreate(
        testSubcacheName,
        testKey2,
        createFn: null,
      );
      expect(value2, expectedValue2);
    });

    test('retries when get throws exception', () async {
      final Cache<Uint8List> mockMainCache = MockCache();
      final Cache<Uint8List> mockTestSubcache = MockCache();
      when<Cache<Uint8List>>(
        mockMainCache.withPrefix(testSubcacheName),
      ).thenReturn(mockTestSubcache);

      var getCallCount = 0;
      final Entry<Uint8List> entry = FakeEntry();
      // Only on the first call do we want it to throw the exception.
      when(mockTestSubcache['does not matter']).thenAnswer(
        (Invocation invocation) =>
            getCallCount++ < 1
                ? throw Exception('simulate stream sink error')
                : entry,
      );

      cache.cacheValue = mockMainCache;

      final value = await cache.getOrCreate(
        testSubcacheName,
        'does not matter',
        createFn: null,
      );
      verify(mockTestSubcache['does not matter']).called(2);
      expect(value, Uint8List.fromList('abc123'.codeUnits));
    });

    test('returns null if reaches max attempts of retries', () async {
      final Cache<Uint8List> mockMainCache = MockCache();
      final Cache<Uint8List> mockTestSubcache = MockCache();
      when<Cache<Uint8List>>(
        mockMainCache.withPrefix(testSubcacheName),
      ).thenReturn(mockTestSubcache);

      var getCallCount = 0;
      final Entry<Uint8List> entry = FakeEntry();
      // Always throw exception until max retries
      when(mockTestSubcache['does not matter']).thenAnswer(
        (Invocation invocation) =>
            getCallCount++ < CacheService.maxCacheGetAttempts
                ? throw Exception('simulate stream sink error')
                : entry,
      );

      cache.cacheValue = mockMainCache;

      final value = await cache.getOrCreate(
        testSubcacheName,
        'does not matter',
        createFn: null,
      );
      verify(
        mockTestSubcache['does not matter'],
      ).called(CacheService.maxCacheGetAttempts);
      expect(value, isNull);
    });

    test('creates value if given createFn', () async {
      final cat = Uint8List.fromList('cat'.codeUnits);
      Future<Uint8List> createCat() async => cat;

      final value = await cache.getOrCreate(
        testSubcacheName,
        'dog',
        createFn: createCat,
      );

      expect(value, cat);
    });

    test('purge removes value', () async {
      const testKey = 'abc';
      final expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.set(testSubcacheName, testKey, expectedValue);

      final value = await cache.getOrCreate(
        testSubcacheName,
        testKey,
        createFn: null,
      );

      expect(value, expectedValue);

      await cache.purge(testSubcacheName, testKey);

      final valueAfterPurge = await cache.getOrCreate(
        testSubcacheName,
        testKey,
        createFn: null,
      );
      expect(valueAfterPurge, isNull);
    });

    test('sets ttl from set', () async {
      final Cache<Uint8List> mockMainCache = MockCache();
      final Cache<Uint8List> mockTestSubcache = MockCache();
      when<Cache<Uint8List>>(
        mockMainCache.withPrefix(testSubcacheName),
      ).thenReturn(mockTestSubcache);

      final Entry<Uint8List> entry = MockFakeEntry();
      when(
        mockTestSubcache['fish'],
      ).thenAnswer((Invocation invocation) => entry);
      cache.cacheValue = mockMainCache;

      const testDuration = Duration(days: 40);
      when(entry.set(any, testDuration)).thenAnswer((_) async => null);
      verifyNever(entry.set(any, testDuration));
      await cache.set(
        testSubcacheName,
        'fish',
        Uint8List.fromList('bigger fish'.codeUnits),
        ttl: testDuration,
      );
      verify(entry.set(any, testDuration)).called(1);
    });

    test('sets ttl is passed through correctly from createFn', () async {
      const value = 'bigger fish';
      final valueBytes = Uint8List.fromList(value.codeUnits);
      const testDuration = Duration(days: 40);

      final Entry<Uint8List> entry = MockFakeEntry();
      when(
        entry.set(valueBytes, testDuration),
      ).thenAnswer((_) async => valueBytes);

      final Cache<Uint8List> mockTestSubcache = MockCache();
      final Cache<Uint8List> mockMainCache = MockCache();
      when<Cache<Uint8List>>(
        mockMainCache.withPrefix(testSubcacheName),
      ).thenReturn(mockTestSubcache);
      when(
        mockTestSubcache['fish'],
      ).thenAnswer((Invocation invocation) => entry);
      cache.cacheValue = mockMainCache;

      verifyNever(entry.set(any, testDuration));
      await cache.getOrCreate(
        testSubcacheName,
        'fish',
        createFn: () async => valueBytes,
        ttl: testDuration,
      );
      verify(entry.set(any, testDuration)).called(1);
    });

    test('set does not block read attempt', () async {
      const testKey = 'abc';
      final expectedValue = Uint8List.fromList('123'.codeUnits);

      final cacheWrite = cache.setWithLocking(
        testSubcacheName,
        testKey,
        expectedValue,
      );
      var valueAfterSet = await cache.getOrCreateWithLocking(
        testSubcacheName,
        testKey,
        createFn: null,
      );

      expect(valueAfterSet, null);
      await cacheWrite;
      valueAfterSet = await cache.getOrCreateWithLocking(
        testSubcacheName,
        testKey,
        createFn: null,
      );
      expect(valueAfterSet, expectedValue);
    });

    test('read locks are not blocking', () async {
      const testKey = 'abc';
      final expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.setWithLocking(testSubcacheName, testKey, expectedValue);
      final valueAfterSet = cache.getOrCreateWithLocking(
        testSubcacheName,
        testKey,
        createFn: null,
      );
      final valueAfterSet2 = await cache.getOrCreateWithLocking(
        testSubcacheName,
        testKey,
        createFn: null,
      );

      expect(valueAfterSet2, expectedValue);
      await valueAfterSet.then((value) => expect(value, expectedValue));
    });

    test('write locks are blocking', () async {
      const testKey = 'abc';
      final expectedValue = Uint8List.fromList('123'.codeUnits);
      final newValue = Uint8List.fromList('345'.codeUnits);

      final cacheWrite = cache.setWithLocking(
        testSubcacheName,
        testKey,
        expectedValue,
      );
      final cacheWrite2 = cache.setWithLocking(
        testSubcacheName,
        testKey,
        newValue,
      );
      await cacheWrite;
      final readValue = await cache.getOrCreateWithLocking(
        testSubcacheName,
        testKey,
        createFn: null,
      );
      expect(readValue, expectedValue);
      await cacheWrite2;
    });
  });
}

class FakeEntry extends Entry<Uint8List> {
  Uint8List value = Uint8List.fromList('abc123'.codeUnits);

  @override
  Future<Uint8List> get([
    Future<Uint8List?> Function()? create,
    Duration? ttl,
  ]) async => value;

  @override
  Future<void> purge({int retries = 0}) => throw UnimplementedError();

  @override
  Future<Uint8List?> set(Uint8List? value, [Duration? ttl]) async {
    value = value;

    return value;
  }
}
