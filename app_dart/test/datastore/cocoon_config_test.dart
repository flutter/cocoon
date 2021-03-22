// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/luci.dart';

import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_github_service.dart';

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
      }''';

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
      }''';

const String luciTryBuildersDefaultBranch = '''
      {
        "builders":[
            {
              "name":"try test 1",
              "repo":"flutter",
              "enabled":true
            }, {
              "name":"Linux build_aar_test try",
              "repo":"cocoon",
              "enabled":false
            }
        ]
      }''';

void main() {
  group('githubAppInstallations', () {
    FakeDatastoreDB datastore;
    CacheService cacheService;
    Config config;
    setUp(() {
      datastore = FakeDatastoreDB();
    });
    test('Builder config does not exist', () async {
      cacheService = CacheService(inMemory: true);
      config = Config(datastore, cacheService);
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
      config = Config(
        datastore,
        cacheService,
        httpClientProvider: () => fakeHttpClient,
        githubService: FakeGithubService(),
        logValue: FakeLogging(),
      );
    });

    test('gets all prod builds from default branch', () async {
      fakeHttpClient.onIssueRequest = (FakeHttpClientRequest request) {
        if (request.uri == Uri.https('raw.githubusercontent.com', 'flutter/flutter/shashaabc/dev/prod_builders.json')) {
          request.response = FakeHttpClientResponse(body: luciBuildersDefaultBranch);
        }
      };
      final List<LuciBuilder> prodBuilders = await config.luciBuilders(
        'prod',
        'flutter',
        branch: config.defaultBranch,
        commitSha: 'shashaabc',
      );
      expect(luciBuildersToNames(prodBuilders), <String>['Linux framework_tests']);
    });

    test('gets all prod builds from release branch', () async {
      fakeHttpClient.onIssueRequest = (FakeHttpClientRequest request) {
        if (request.uri ==
            Uri.https('raw.githubusercontent.com', 'flutter/flutter/release-abc/dev/prod_builders.json')) {
          request.response = FakeHttpClientResponse(body: luciBuildersReleaseBranch);
        }
      };
      final List<LuciBuilder> prodBuilders = await config.luciBuilders(
        'prod',
        'flutter',
        branch: 'release-abc',
      );
      expect(luciBuildersToNames(prodBuilders), <String>['Linux Stable framework_tests']);
    });

    test('gets all try builds from default branch', () async {
      fakeHttpClient.onIssueRequest = (FakeHttpClientRequest request) {
        if (request.uri == Uri.https('raw.githubusercontent.com', 'flutter/flutter/master/dev/try_builders.json')) {
          request.response = FakeHttpClientResponse(body: luciTryBuildersDefaultBranch);
        }
      };
      final List<LuciBuilder> tryBuilders = await config.luciBuilders(
        'try',
        'flutter',
        prNumber: 12345,
      );
      expect(luciBuildersToNames(tryBuilders), <String>['try test 1']);
    });
  });
}

List<String> luciBuildersToNames(List<LuciBuilder> builders) =>
    builders.map((LuciBuilder builder) => builder.name).toList();
