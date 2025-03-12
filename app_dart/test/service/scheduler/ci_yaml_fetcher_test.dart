// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as firestore;
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/service/fake_fusion_tester.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

void main() {
  // githubFileContent, which is what downloads .ci.yaml, has logic that looks
  // at the length of the SHA to determine whether is a branch name or a SHA
  // reference, so these need to be "real" (40 character-length) SHAs.
  const currentSha = '42f53a3e65dbebce34b52d4a97dd70f08621875c';
  const totSha = 'bf58e0e6dffbfd759a3b2b5c56a2b5b115506c91';
  assert(currentSha.length >= 40);
  assert(totSha.length >= 40);

  late List<String> logs;

  late CacheService cache;
  late FakeConfig config;
  late FakeFusionTester fusionTester;
  late MockClient httpClient;
  late MockFirestoreService firestoreService;
  late firestore.Commit totCommit;

  late CiYamlFetcher ciYamlFetcher;

  setUp(() {
    logs = [];
    log = Logger.detached('ci_yaml_fetcher_test');
    log.onRecord.listen((r) => logs.add(r.message));

    cache = CacheService(inMemory: true);
    config = FakeConfig();
    fusionTester = FakeFusionTester();
    httpClient = MockClient((request) async {
      return http.Response('Missing file: ${request.url}', HttpStatus.notFound);
    });

    firestoreService = MockFirestoreService();
    config.firestoreService = firestoreService;

    totCommit = generateFirestoreCommit(
      1,
      sha: 'bf58e0e6dffbfd759a3b2b5c56a2b5b115506c91',
    );
    when(
      firestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        limit: argThat(equals(1), named: 'limit'),
        timestamp: argThat(isNull, named: 'timestamp'),
        branch: anyNamed('branch'),
      ),
    ).thenAnswer((_) async {
      return [totCommit];
    });

    ciYamlFetcher = CiYamlFetcher(
      cache: cache,
      config: config,
      fusionTester: fusionTester,
      httpClientProvider: () => httpClient,
      retryOptions: const RetryOptions(maxAttempts: 1),
    );
  });

  tearDown(() {
    printOnFailure(logs.join('\n'));
  });

  test('fetches the root .ci.yaml for a repository (GitHub)', () async {
    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.flutterSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      if (ref == totSha || ref == currentSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    final ciYaml = await ciYamlFetcher.getCiYaml(
      slug: Config.flutterSlug,
      commitSha: currentSha,
      commitBranch: 'master',
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A']),
    );
  });

  test('fetches the root .ci.yaml for a repository (GoB fallback)', () async {
    httpClient = MockClient((request) async {
      if (request.url.host == 'raw.githubusercontent.com') {
        return http.Response('', HttpStatus.notFound);
      }

      if (request.url.host != 'flutter.googlesource.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request (mirrors/$slug/+/$ref/$path)
      final [_, repository, _, ref, ...path] = request.url.pathSegments;
      expect(repository, Config.flutterSlug.name);
      expect(p.joinAll(path), kCiYamlPath);

      // GoB returns all text data as base64-encoded?
      if (ref == totSha || ref == currentSha) {
        return http.Response.bytes(
          base64Encode(singleCiYaml.codeUnits).codeUnits,
          HttpStatus.ok,
        );
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    final ciYaml = await ciYamlFetcher.getCiYaml(
      slug: Config.flutterSlug,
      commitSha: currentSha,
      commitBranch: 'master',
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A']),
    );
  });

  test('fetches the root .ci.yaml for a datastore commit', () async {
    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.flutterSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      if (ref == totSha || ref == currentSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    final ciYaml = await ciYamlFetcher.getCiYamlByDatastoreCommit(
      generateCommit(1, sha: currentSha),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A']),
    );
  });

  test('fetches the root .ci.yaml for a firestore commit', () async {
    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.flutterSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      if (ref == totSha || ref == currentSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    final ciYaml = await ciYamlFetcher.getCiYamlByFirestoreCommit(
      generateFirestoreCommit(1, sha: currentSha),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A']),
    );
  });

  test('prevents an invalid target when in conflict with ToT', () async {
    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.flutterSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      // ToT does not have "Linux B"
      if (ref == totSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      // But current does, and it's not marked bringup.
      if (ref == currentSha) {
        return http.Response(singleCiYamlWithTwoTargets, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    await expectLater(
      ciYamlFetcher.getCiYaml(
        slug: Config.flutterSlug,
        commitSha: currentSha,
        commitBranch: 'master',
        validate: true,
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Linux B is a new builder added'),
        ),
      ),
    );
  });

  test('allows an invalid target when bringup: true is set', () async {
    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.flutterSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      // ToT does not have "Linux B"
      if (ref == totSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      // But current does, but it's marked bringup
      if (ref == currentSha) {
        return http.Response(singleCiYamlWithTwoTargetsBringup, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    final ciYaml = await ciYamlFetcher.getCiYamlByFirestoreCommit(
      generateFirestoreCommit(1, sha: currentSha),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A', 'Linux B']),
    );
  });

  test('merges targets from dual .ci.yaml in a fusion repo', () async {
    fusionTester.isFusion = (_, _) => true;

    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.flutterSlug.fullName);

      // Use the same result for both current and ToT, disallow others.
      if (ref != totSha && ref != currentSha) {
        fail('Should not occur. Unexpected request: ${request.url}');
      }

      return http.Response(switch (p.joinAll(path)) {
        kCiYamlPath => singleCiYaml,
        kCiYamlFusionEnginePath => engineCiYaml,
        _ => fail('Should not occur. Unexpected request: ${request.url}'),
      }, HttpStatus.ok);
    });

    final ciYaml = await ciYamlFetcher.getCiYamlByFirestoreCommit(
      generateFirestoreCommit(1, sha: currentSha),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A']),
      reason: 'Root .ci.yaml should only contain Linux A',
    );

    expect(
      ciYaml.targets(type: CiType.fusionEngine).map((t) => t.value.name),
      unorderedEquals(['Linux Engine']),
      reason: 'Engine .ci.yaml should only contain Linux Engine',
    );
  });
}

const String singleCiYaml = r'''
enabled_branches:
  - master

targets:
  - name: Linux A
''';

const String singleCiYamlWithTwoTargets = r'''
enabled_branches:
  - master

targets:
  - name: Linux A
  - name: Linux B
''';

const String singleCiYamlWithTwoTargetsBringup = r'''
enabled_branches:
  - master

targets:
  - name: Linux A
  - name: Linux B
    bringup: true
''';

const String engineCiYaml = r'''
enabled_branches:
  - master

targets:
  - name: Linux Engine
''';
