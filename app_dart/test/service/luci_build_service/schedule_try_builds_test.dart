// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/pr_check_runs.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/engine_artifacts.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/model/ci_yaml_matcher.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

/// Tests [LuciBuildService] public API related to fetching try-bot builds.
///
/// Specifically:
/// - [LuciBuildService.scheduleTryBuilds]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    luci = LuciBuildService(
      config: FakeConfig(firestoreService: firestoreService),
      cache: CacheService(inMemory: true),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
    );
  });

  test('builds from source', () async {
    final pullRequest = generatePullRequest(
      id: 1,
      repo: 'flutter',
      headSha: 'headsha123',
    );

    final buildTarget = generateTarget(
      1,
      properties: {'os': 'abc'},
      slug: RepositorySlug.full('flutter/flutter'),
      name: 'Linux foo',
    );

    when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((
      i,
    ) async {
      final [
        _,
        RepositorySlug slug,
        String sha,
        String name, //
      ] = i.positionalArguments;

      expect(slug, RepositorySlug.full('flutter/flutter'));
      expect(sha, 'headsha123');
      expect(name, 'Linux foo');

      return generateCheckRun(1, name: 'Linux foo');
    });

    await expectLater(
      luci.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: [buildTarget],
        engineArtifacts: EngineArtifacts.builtFromSource(
          commitSha: pullRequest.head!.sha!,
        ),
      ),
      completion([isTarget.hasName('Linux foo')]),
    );

    expect(
      firestoreService,
      existsInStorage(PrCheckRuns.metadata, [isPrCheckRun.hasCheckRuns({})]),
    );
  });
}
