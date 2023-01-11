// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:mutex/mutex.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_datastore.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  group('Config', () {
    FakeDatastoreDB datastore;
    late CacheService cacheService;
    late Config config;
    late ReadWriteMutex readWriteMutex;
    late MockReadWriteMutex mockReadWriteMutex;
    setUp(() {
      datastore = FakeDatastoreDB();
      cacheService = CacheService(inMemory: true);
      readWriteMutex = ReadWriteMutex();
      mockReadWriteMutex = MockReadWriteMutex();
      config = Config(datastore, cacheService, mockReadWriteMutex);

      when(mockReadWriteMutex.acquireWrite()).thenAnswer((realInvocation) => readWriteMutex.acquireWrite());
      when(mockReadWriteMutex.release()).thenAnswer((realInvocation) => readWriteMutex.release());
    });
    test('githubAppInstallations when builder config does not exist', () async {
      const String configValue = '{"godofredoc/cocoon":{"installation_id":"123"}}';
      final Uint8List cachedValue = Uint8List.fromList(configValue.codeUnits);

      await cacheService.set(
        Config.configCacheName,
        'githubapp_installations',
        cachedValue,
      );
      final Map<String, dynamic> installation = await config.githubAppInstallations;
      expect(installation['godofredoc/cocoon']['installation_id'], equals('123'));
    });

    test('generateGithubToken pulls from cache', () async {
      const String configValue = 'githubToken';
      final Uint8List cachedValue = Uint8List.fromList(configValue.codeUnits);
      await cacheService.set(
        Config.configCacheName,
        'githubToken-${Config.flutterSlug}',
        cachedValue,
      );

      final String githubToken = await config.generateGithubToken(Config.flutterSlug);
      expect(githubToken, 'githubToken');
    });

    test('generateGithubToken only tries to generate a github token one at a time', () async {
      const String configValue = 'githubToken';
      final Uint8List cachedValue = Uint8List.fromList(configValue.codeUnits);
      await cacheService.set(
        Config.configCacheName,
        'githubToken-${Config.flutterSlug}',
        cachedValue,
      );

      final futures = <Future<String>>[];
      futures.add(config.generateGithubToken(Config.flutterSlug));
      futures.add(config.generateGithubToken(Config.flutterSlug));

      await Future.wait(futures);
      verifyInOrder(
        [
          mockReadWriteMutex.acquireWrite(),
          mockReadWriteMutex.release(),
          mockReadWriteMutex.acquireWrite(),
          mockReadWriteMutex.release()
        ]
      );
    });

    test('Returns the right flutter gold alert', () {
      expect(
        config.flutterGoldAlertConstant(RepositorySlug.full('flutter/flutter')),
        contains('package:flutter'),
      );
      expect(
        config.flutterGoldAlertConstant(RepositorySlug.full('flutter/engine')),
        isNot(contains('package:flutter')),
      );
    });
  });
}
