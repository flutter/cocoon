// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:cocoon_service/src/service/cache_service.dart';

void main() {
  group('CacheService', () {
    CacheService cache;

    const String testSubcacheName = 'test';

    setUp(() {
      cache = CacheService(inMemory: true, inMemoryMaxSize: 1);
    });

    test('returns null when no value exists', () async {
      final Uint8List value = await cache.get(testSubcacheName, 'abc');

      expect(value, isNull);
    });

    test('returns value when it exists', () async {
      const String testKey = 'abc';
      final Uint8List expectedValue = Uint8List.fromList('123'.codeUnits);

      await cache.set(testSubcacheName, testKey, expectedValue);

      final Uint8List value = await cache.get(testSubcacheName, testKey);

      expect(value, expectedValue);
    });

    test('last used value is rotated out of cache if cache is full', () async {
      const String testKey1 = 'abc';
      const String testKey2 = 'def';
      final Uint8List expectedValue1 = Uint8List.fromList('123'.codeUnits);
      final Uint8List expectedValue2 = Uint8List.fromList('456'.codeUnits);

      await cache.set(testSubcacheName, testKey1, expectedValue1);
      await cache.set(testSubcacheName, testKey2, expectedValue2);

      final Uint8List value1 = await cache.get(testSubcacheName, testKey1);
      expect(value1, null);

      final Uint8List value2 = await cache.get(testSubcacheName, testKey2);
      expect(value2, expectedValue2);
    });    

    test('retries when get throws exception', () async {});

    test('returns null if reaches max attempts of retries', () async {});
    
  });
}