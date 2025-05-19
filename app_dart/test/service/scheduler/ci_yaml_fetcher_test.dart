// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';

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
  late MockClient httpClient;
  late FakeFirestoreService firestore;

  late CiYamlFetcher ciYamlFetcher;

  setUp(() {
    cache = CacheService(inMemory: true);
    httpClient = MockClient((request) async {
      return http.Response('Missing file: ${request.url}', HttpStatus.notFound);
    });

    firestore = FakeFirestoreService();

    ciYamlFetcher = CiYamlFetcher(
      cache: cache,
      httpClientProvider: () => httpClient,
      retryOptions: const RetryOptions(maxAttempts: 1),
      firestore: firestore,
    );
  });

  void mockFillFirestore({
    required RepositorySlug slug,
    required String branch,
  }) {
    firestore.putDocument(
      generateFirestoreCommit(
        1,
        sha: currentSha,
        owner: slug.owner,
        repo: slug.name,
        branch: branch,
      ),
    );
    firestore.putDocument(
      generateFirestoreCommit(
        2,
        sha: totSha,
        owner: slug.owner,
        repo: slug.name,
        branch: branch,
      ),
    );
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

    final ciYaml = await ciYamlFetcher.getCiYamlByCommit(
      CommitRef(slug: Config.packagesSlug, sha: currentSha, branch: 'main'),
      validate: true,
    );

    expect(ciYaml.targets().map((t) => t.name), unorderedEquals(['Linux A']));
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

    final ciYaml = await ciYamlFetcher.getCiYamlByCommit(
      CommitRef(slug: Config.packagesSlug, sha: currentSha, branch: 'main'),
      validate: true,
      postsubmit: true,
    );

    expect(ciYaml.targets().map((t) => t.name), unorderedEquals(['Linux A']));
  });

  test('fetches the root .ci.yaml for a commit ref', () async {
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

    final ciYaml = await ciYamlFetcher.getCiYamlByCommit(
      generateFirestoreCommit(
        1,
        sha: currentSha,
        repo: 'packages',
        branch: 'main',
      ).toRef(),
      validate: true,
    );

    expect(ciYaml.targets().map((t) => t.name), unorderedEquals(['Linux A']));
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
      ciYamlFetcher.getCiYamlByCommit(
        CommitRef(slug: Config.packagesSlug, sha: currentSha, branch: 'main'),
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

  test('ignores an invalid target in postsubmit: true', () async {
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
      ciYamlFetcher.getCiYamlByCommit(
        CommitRef(slug: Config.packagesSlug, sha: currentSha, branch: 'main'),
        postsubmit: true,
      ),
      completes,
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

    final ciYaml = await ciYamlFetcher.getCiYamlByCommit(
      generateFirestoreCommit(
        1,
        sha: currentSha,
        repo: 'packages',
        branch: 'main',
      ).toRef(),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.name),
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

    final ciYaml = await ciYamlFetcher.getCiYamlByCommit(
      generateFirestoreCommit(
        1,
        sha: currentSha,
        branch: 'flutter-0.42-candidate.0',
      ).toRef(),
      validate: true,
    );

    expect(ciYaml.targets().map((t) => t.name), unorderedEquals(['Linux A']));
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

    final ciYaml = await ciYamlFetcher.getCiYamlByCommit(
      generateFirestoreCommit(1, sha: currentSha).toRef(),
      validate: true,
    );

    expect(
      ciYaml.targets().map((t) => t.name),
      unorderedEquals(['Linux A']),
      reason: 'Root .ci.yaml should only contain Linux A',
    );

    expect(
      ciYaml.targets(type: CiType.fusionEngine).map((t) => t.name),
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
      ciYamlFetcher.getCiYamlByCommit(
        CommitRef(slug: Config.flutterSlug, sha: currentSha, branch: 'master'),
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
