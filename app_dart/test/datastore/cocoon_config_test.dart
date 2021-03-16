// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/luci.dart';

import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_http.dart';

const String luciBuildersDefaultBranch = '''
      {
        "builders":[
            {
              "name":"Linux framework_tests",
              "repo":"flutter",
              "enabled":true
            }, {
              "name":"Linux build_aar_test",
              "repo":"cocoon",
              "enabled":false
            }
        ]
      }
      ''';

const String luciBuildersReleaseBranch = '''
      {
        "builders":[
            {
              "name":"Linux Stable framework_tests",
              "repo":"flutter",
              "enabled":true
            }, {
              "name":"Linux stable build_aar_test",
              "repo":"flutter",
              "enabled":false
            }
        ]
      }
      ''';

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

  group('luci builders', () {
    FakeDatastoreDB datastore;
    FakeHttpClient fakeHttpClient;
    CacheService cacheService;
    Config config;
    setUp(() {
      datastore = FakeDatastoreDB();
      fakeHttpClient = FakeHttpClient();
      cacheService = CacheService(inMemory: true);
      cacheService.set(Config.configCacheName, 'flutterBranches',
          Uint8List.fromList(<int>[...'master'.codeUnits, ...'release-abc'.codeUnits]));
      config = Config(datastore, cacheService, httpClientProvider: () => fakeHttpClient);
    });

    test('gets all builds from default and release branches', () async {
      fakeHttpClient.onIssueRequest = (FakeHttpClientRequest request) {
        if (request.uri == Uri.https('github.com', 'flutter/master/dev/prod_builders.json')) {
          return luciBuildersDefaultBranch;
        } else {
          return luciBuildersReleaseBranch;
        }
      };

      final List<LuciBuilder> prodBuilders = await config.luciBuilders('prod', 'flutter');
      expect(prodBuilders.length, 2);
      expect(luciBuildersToNames(prodBuilders),
          containsAll(<String>['Linux framework_tests', 'Linux Stable framework_tests']));
    });
  });
}

List<String> luciBuildersToNames(List<LuciBuilder> builders) =>
    builders.map((LuciBuilder builder) => builder.name).toList();
