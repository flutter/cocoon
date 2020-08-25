// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/luci.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';

void main() {
  group('githubAppInstallations', () {
    FakeDatastoreDB datastore;
    CacheService cacheService;
    Config config;
    setUp(() {
      datastore = FakeDatastoreDB();
      cacheService = CacheService(inMemory: true);
      config = Config(datastore, cacheService);
    });
    test('Builder config does not exist', () async {
      const String configValue = '{"godofredoc/cocoon":{"installation_id":"123"}}';
      final Uint8List cachedValue = Uint8List.fromList(configValue.codeUnits);

      await cacheService.set(
        'config',
        'githubapp_installations',
        cachedValue,
      );
      final Map<String, dynamic> installation = await config.githubAppInstallations;
      expect(installation['godofredoc/cocoon']['installation_id'], equals('123'));
    });
  });

  group('luciTryBuilders', () {
    FakeConfig config;
    setUp(() {
      config = FakeConfig();
    });
    test('returns updated builders when there is a config file change in commit', () async {
      config.cocoonTryBuilderValueCommit =
          const LuciBuilder(name: 'Cocoon_test', repo: 'cocoon', taskName: 'cocoon_bot', flaky: true);
      final List<String> files = <String>['dev/try_builders.json'];
      final List<LuciBuilder> luciBuilders = await config.getLuciTryBuilders(files, 'cocoon', 'test');

      expect(luciBuilders, <LuciBuilder>[
        const LuciBuilder(name: 'Cocoon_test', repo: 'cocoon', taskName: 'cocoon_bot', flaky: true)
      ]);
    });

    test('returns TOT builders when there is no config file change in commit', () async {
      config.cocoonTryBuilderValueTot =
          const LuciBuilder(name: 'Cocoon', repo: 'cocoon', taskName: 'cocoon_bot', flaky: true);
      final List<String> files = <String>['a/b/c.d'];
      final List<LuciBuilder> luciBuilders = await config.getLuciTryBuilders(files, 'cocoon', 'test');

      expect(luciBuilders,
          <LuciBuilder>[const LuciBuilder(name: 'Cocoon', repo: 'cocoon', taskName: 'cocoon_bot', flaky: true)]);
    });
  });
}
