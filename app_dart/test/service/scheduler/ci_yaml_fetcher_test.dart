// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/service/fake_fusion_tester.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

void main() {
  late CacheService cache;
  late FakeConfig config;
  late FakeFusionTester fusionTester;
  late MockClient httpClient;
  late MockFirestoreService firestoreService;

  late CiYamlFetcher ciYamlFetcher;

  setUp(() {
    cache = CacheService(inMemory: true);
    config = FakeConfig();
    fusionTester = FakeFusionTester();
    httpClient = _cannedCiYamlResponses({});

    firestoreService = MockFirestoreService();
    config.firestoreService = firestoreService;
    when(
      firestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        limit: argThat(equals(1), named: 'limit'),
        timestamp: argThat(isNull, named: 'timestamp'),
        branch: anyNamed('branch'),
      ),
    ).thenAnswer((_) async {
      return [generateFirestoreCommit(1)];
    });

    ciYamlFetcher = CiYamlFetcher(
      cache: cache,
      config: config,
      fusionTester: fusionTester,
      httpClientProvider: () => httpClient,
      retryOptions: const RetryOptions(maxAttempts: 1),
    );
  });

  test('fetches the root .ci.yaml for a repository', () async {
    httpClient = _cannedCiYamlResponses({kCiYamlPath: singleCiYaml});

    final ciYaml = await ciYamlFetcher.getCiYaml(
      slug: Config.flutterSlug,
      commitSha: 'abc123',
      commitBranch: 'master',
    );
  });
}

/// Returns a [MockClient] that given a request (URL key), returns the content.
MockClient _cannedCiYamlResponses(Map<String, String> pathToContent) {
  return MockClient((request) async {
    final content = pathToContent[request.url.toString()];
    if (content == null) {
      return http.Response('Missing file: ${request.url}', HttpStatus.notFound);
    }
    return http.Response(content, HttpStatus.ok);
  });
}

const String singleCiYaml = r'''
targets:
  - name: Linux A
''';
