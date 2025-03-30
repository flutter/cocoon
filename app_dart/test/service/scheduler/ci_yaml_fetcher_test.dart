// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  // githubFileContent, which is what downloads .ci.yaml, has logic that looks
  // at the length of the SHA to determine whether is a branch name or a SHA
  // reference, so these need to be "real" (40 character-length) SHAs.
  const currentSha = '42f53a3e65dbebce34b52d4a97dd70f08621875c';
  const totSha = 'bf58e0e6dffbfd759a3b2b5c56a2b5b115506c91';
  assert(currentSha.length >= 40);
  assert(totSha.length >= 40);

  late CacheService cache;
  late FakeConfig config;
  late MockClient httpClient;
  late MockFirestoreService firestoreService;

  late CiYamlFetcher ciYamlFetcher;

  setUp(() {
    cache = CacheService(inMemory: true);
    config = FakeConfig();
    httpClient = MockClient((request) async {
      return http.Response('Missing file: ${request.url}', HttpStatus.notFound);
    });

    firestoreService = MockFirestoreService();
    config.firestoreService = firestoreService;

    ciYamlFetcher = CiYamlFetcher(
      cache: cache,
      config: config,
      fusionTester: const FusionTester(),
      httpClientProvider: () => httpClient,
      retryOptions: const RetryOptions(maxAttempts: 1),
    );
  });

  void mockFillFirestore({
    required RepositorySlug slug,
    required String branch,
  }) {
    when(
      // ignore: discarded_futures
      firestoreService.queryRecentCommits(
        slug: argThat(equals(slug), named: 'slug'),
        limit: argThat(equals(1), named: 'limit'),
        timestamp: argThat(isNull, named: 'timestamp'),
        branch: argThat(equals(branch), named: 'branch'),
      ),
    ).thenAnswer((_) async {
      return [
        generateFirestoreCommit(
          1,
          sha: 'bf58e0e6dffbfd759a3b2b5c56a2b5b115506c91',
          owner: slug.owner,
          repo: slug.name,
        ),
      ];
    });
  }

  test('fetches the root .ci.yaml for a repository (GitHub)', () async {
    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.packagesSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      if (ref == totSha || ref == currentSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    mockFillFirestore(slug: Config.packagesSlug, branch: 'main');

    final ciYaml = await ciYamlFetcher.getCiYaml(
      slug: Config.packagesSlug,
      commitSha: currentSha,
      commitBranch: 'main',
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
      expect(repository, Config.packagesSlug.name);
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

    mockFillFirestore(slug: Config.packagesSlug, branch: 'main');

    final ciYaml = await ciYamlFetcher.getCiYaml(
      slug: Config.packagesSlug,
      commitSha: currentSha,
      commitBranch: 'main',
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
      expect('$owner/$repository', Config.packagesSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      if (ref == totSha || ref == currentSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    mockFillFirestore(slug: Config.packagesSlug, branch: 'main');

    final ciYaml = await ciYamlFetcher.getCiYamlByDatastoreCommit(
      generateCommit(1, sha: currentSha, repo: 'packages', branch: 'main'),
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
      expect('$owner/$repository', Config.packagesSlug.fullName);
      expect(p.joinAll(path), kCiYamlPath);

      if (ref == totSha || ref == currentSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    mockFillFirestore(slug: Config.packagesSlug, branch: 'main');

    final ciYaml = await ciYamlFetcher.getCiYamlByFirestoreCommit(
      generateFirestoreCommit(
        1,
        sha: currentSha,
        repo: 'packages',
        branch: 'main',
      ),
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
      expect('$owner/$repository', Config.packagesSlug.fullName);
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

    mockFillFirestore(slug: Config.packagesSlug, branch: 'main');

    await expectLater(
      ciYamlFetcher.getCiYaml(
        slug: Config.packagesSlug,
        commitSha: currentSha,
        commitBranch: 'main',
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
      expect('$owner/$repository', Config.packagesSlug.fullName);
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

    mockFillFirestore(slug: Config.packagesSlug, branch: 'main');

    final ciYaml = await ciYamlFetcher.getCiYamlByFirestoreCommit(
      generateFirestoreCommit(
        1,
        sha: currentSha,
        repo: 'packages',
        branch: 'main',
      ),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A', 'Linux B']),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/165433.
  test('fetches ToT .ci.yaml from the default branch only', () async {
    httpClient = MockClient((request) async {
      if (request.url.host != 'raw.githubusercontent.com') {
        fail('Unexpected host: ${request.url}');
      }

      // Extract the URL request ($slug/$ref/$file);
      final [owner, repository, ref, ...path] = request.url.pathSegments;
      expect('$owner/$repository', Config.flutterSlug.fullName);

      if (ref == totSha || ref == currentSha) {
        return http.Response(singleCiYaml, HttpStatus.ok);
      }

      fail('Should not occur. Unexpected request: ${request.url}');
    });

    mockFillFirestore(
      slug: Config.flutterSlug,
      branch: Config.defaultBranch(Config.flutterSlug),
    );

    final ciYaml = await ciYamlFetcher.getCiYamlByFirestoreCommit(
      generateFirestoreCommit(
        1,
        sha: currentSha,
        branch: 'flutter-0.42-candidate.0',
      ),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.value.name),
      unorderedEquals(['Linux A']),
    );
  });

  test('merges targets from dual .ci.yaml in a fusion repo', () async {
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

    mockFillFirestore(slug: Config.flutterSlug, branch: 'master');

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

  test('fails with an empty config', () async {
    httpClient = MockClient((_) async {
      return http.Response('', HttpStatus.ok);
    });

    mockFillFirestore(slug: Config.flutterSlug, branch: 'master');

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
          contains('must have at least 1 target'),
        ),
      ),
    );
  });

  test('fails with unknown dependencies', () async {
    httpClient = MockClient((_) async {
      return http.Response('''
enabled_branches:
  - master
targets:
  - name: A
    builder: Linux A
    dependencies:
      - B
          ''', HttpStatus.ok);
    });

    mockFillFirestore(slug: Config.flutterSlug, branch: 'master');

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
          contains('A depends on B which does not exist'),
        ),
      ),
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
