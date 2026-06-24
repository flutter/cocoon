// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('CacheService', () {
    late CacheService cache;
    const testSubcacheName = 'test';

    setUp(() {
      cache = CacheService(inMemory: true, inMemoryMaxNumberEntries: 2);
    });

    test('returns null when no value exists', () async {
      final value = await cache.get(testSubcacheName, 'abc');
      expect(value, isNull);
    });

    test('returns value when it exists', () async {
      const testKey = 'abc';
      final expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.set(testSubcacheName, testKey, expectedValue);
      final value = await cache.get(testSubcacheName, testKey);

      expect(value, expectedValue);
    });

    test('getOrCreate retrieves or creates value', () async {
      const testKey = 'abc';
      final cat = Uint8List.fromList('cat'.codeUnits);
      var createCount = 0;

      Future<Uint8List> createCat() async {
        createCount++;
        return cat;
      }

      // First call should invoke createFn
      final value1 = await cache.getOrCreate(
        testSubcacheName,
        testKey,
        createFn: createCat,
      );
      expect(value1, cat);
      expect(createCount, 1);

      // Second call should return cached value directly
      final value2 = await cache.getOrCreate(
        testSubcacheName,
        testKey,
        createFn: createCat,
      );
      expect(value2, cat);
      expect(createCount, 1);
    });

    test('rotation evicts oldest entry when cache is full', () async {
      const key1 = 'abc';
      const key2 = 'def';
      const key3 = 'ghi';
      final val1 = Uint8List.fromList('123'.codeUnits);
      final val2 = Uint8List.fromList('456'.codeUnits);
      final val3 = Uint8List.fromList('789'.codeUnits);

      // Cache size is 2 (configured in setUp)
      await cache.set(testSubcacheName, key1, val1);
      await cache.set(testSubcacheName, key2, val2);
      
      // Both should be in cache
      expect(await cache.get(testSubcacheName, key1), val1);
      expect(await cache.get(testSubcacheName, key2), val2);

      // Writing third entry should evict oldest (key1)
      await cache.set(testSubcacheName, key3, val3);

      expect(await cache.get(testSubcacheName, key1), isNull);
      expect(await cache.get(testSubcacheName, key2), val2);
      expect(await cache.get(testSubcacheName, key3), val3);
    });

    test('purge removes value', () async {
      const testKey = 'abc';
      final expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.set(testSubcacheName, testKey, expectedValue);
      expect(await cache.get(testSubcacheName, testKey), expectedValue);

      await cache.purge(testSubcacheName, testKey);
      expect(await cache.get(testSubcacheName, testKey), isNull);
    });

    group('tryLock distributed lock', () {
      test('successfully acquires lock and executes block', () async {
        var executed = false;
        final result = await cache.tryLock('lockKey', () async {
          executed = true;
        }, const Duration(seconds: 5));

        expect(result, isTrue);
        expect(executed, isTrue);
      });

      test('second lock attempt fails while first lock is active', () async {
        final lockAcquiredCompleter = Completer<void>();
        final releaseLockCompleter = Completer<void>();
        
        var secondAttemptResult = false;
        var secondAttemptExecuted = false;

        final firstLockFuture = cache.tryLock('lockKey', () async {
          lockAcquiredCompleter.complete();
          await releaseLockCompleter.future;
        }, const Duration(seconds: 5));

        // Wait for first lock to be acquired
        await lockAcquiredCompleter.future;

        // Try to acquire the same lock concurrently with 0 retries
        secondAttemptResult = await cache.tryLock('lockKey', () async {
          secondAttemptExecuted = true;
        }, const Duration(seconds: 5), 0);

        expect(secondAttemptResult, isFalse);
        expect(secondAttemptExecuted, isFalse);

        // Release first lock
        releaseLockCompleter.complete();
        await firstLockFuture;
      });

      test('lock is automatically released on completion', () async {
        final result1 = await cache.tryLock('lockKey', () async {}, const Duration(seconds: 5));
        expect(result1, isTrue);

        // Immediately after, we should be able to acquire it again
        final result2 = await cache.tryLock('lockKey', () async {}, const Duration(seconds: 5));
        expect(result2, isTrue);
      });

      test('lock is automatically released on exception', () async {
        try {
          await cache.tryLock('lockKey', () async {
            throw Exception('block failed');
          }, const Duration(seconds: 5));
        } catch (_) {}

        // Even after exception, we should be able to acquire it again immediately
        final result = await cache.tryLock('lockKey', () async {}, const Duration(seconds: 5));
        expect(result, isTrue);
      });

      test('lock expires and allows new acquisition', () async {
        // Acquire lock with short TTL
        final result = await cache.tryLock('lockKey', () async {
          // Do nothing but let time pass.
          // Wait longer than TTL
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }, const Duration(milliseconds: 50));

        expect(result, isTrue);

        // After TTL expired, another instance can acquire it immediately
        final result2 = await cache.tryLock('lockKey', () async {}, const Duration(seconds: 5));
        expect(result2, isTrue);
      });

      test('tryLock retries with backoff and eventually succeeds when lock is released', () async {
        final lockAcquiredCompleter = Completer<void>();
        final releaseLockCompleter = Completer<void>();

        final firstLockFuture = cache.tryLock('lockKey', () async {
          lockAcquiredCompleter.complete();
          await releaseLockCompleter.future;
        }, const Duration(seconds: 5));

        await lockAcquiredCompleter.future;

        // Start a second tryLock that will retry up to 5 times.
        // It will wait for first lock to release.
        final secondLockFuture = cache.tryLock('lockKey', () async {
          // Succeeds!
        }, const Duration(seconds: 5), 5);

        // Wait a bit, then release the first lock
        await Future<void>.delayed(const Duration(milliseconds: 100));
        releaseLockCompleter.complete();

        await firstLockFuture;
        final secondResult = await secondLockFuture;

        expect(secondResult, isTrue);
      });
    });
  });
}
