// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_datastore.dart';

void main() {
  group('Config', () {
    FakeDatastoreDB datastore;
    late CacheService cacheService;
    late Config config;
    setUp(() {
      datastore = FakeDatastoreDB();
      cacheService = CacheService(inMemory: true);
      config = Config(datastore, cacheService);
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

    test('flutter branches', () async {
      final List<String> branches = <String>['master', 'main', 'flutter-2.13-candidate.0'];
      final Uint8List branchesBytes = Uint8List.fromList(branches.join(',').codeUnits);
      await cacheService.set(Config.configCacheName, 'flutterBranches', branchesBytes);
      expect(await config.getSupportedBranches(Config.flutterSlug), <String>['master', 'flutter-2.13-candidate.0']);
      expect(await config.getSupportedBranches(Config.engineSlug), <String>['main', 'flutter-2.13-candidate.0']);
      expect(await config.getSupportedBranches(Config.cocoonSlug), <String>['main']);
    });
  });
}
