// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon_service/src/service/cache_service.dart';

void main() {
  group('CacheService', () {
    CacheService cache;

    setUp(() {
      cache = CacheService(inMemory: true, inMemoryMaxSize: 1);
    });

    test('returns null when no value exists', () async {

    });

    test('returns value when it exists', () async {});

    test('last used value is rotated out of cache if cache is full', () async {});
    

    test('retries when get throws exception', () async {});

    test('returns null if reaches max attempts of retries', () async {});
    
  });
}