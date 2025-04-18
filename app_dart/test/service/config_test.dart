// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:cocoon_server_test/fake_secret_manager.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_datastore.dart';

void main() {
  useTestLoggerPerTest();

  FakeDatastoreDB datastore;
  late CacheService cacheService;
  late Config config;
  late FakeSecretManager secrets;

  setUp(() async {
    datastore = FakeDatastoreDB();
    cacheService = CacheService(inMemory: true);
    secrets = FakeSecretManager()..putString('APP_DART_USE_DATASTORE', 'true');
    config = await Config.createDuringDatastoreMigration(
      datastore,
      cacheService,
      secrets,
    );
  });

  test('githubAppInstallations when builder config does not exist', () async {
    const configValue = '{"godofredoc/cocoon":{"installation_id":"123"}}';
    final cachedValue = Uint8List.fromList(configValue.codeUnits);

    await cacheService.set(
      Config.configCacheName,
      'APP_DART_GITHUBAPP_INSTALLATIONS',
      cachedValue,
    );
    final installation = await config.githubAppInstallations;
    expect(installation['godofredoc/cocoon']['installation_id'], equals('123'));
  });

  test('generateGithubToken pulls from cache', () async {
    const configValue = 'githubToken';
    final cachedValue = Uint8List.fromList(configValue.codeUnits);
    await cacheService.set(
      Config.configCacheName,
      'githubToken-${Config.flutterSlug}',
      cachedValue,
    );

    final githubToken = await config.generateGithubToken(Config.flutterSlug);
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
}
