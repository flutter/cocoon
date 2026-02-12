// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart' hide Response;
import 'package:cocoon_service/src/model/firestore/content_aware_hash_builds.dart';
import 'package:cocoon_service/src/model/github/workflow_job.dart';
import 'package:cocoon_service/src/service/big_query.dart';
import 'package:cocoon_service/src/service/content_aware_hash_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../model/github/workflow_job_data.dart';
import '../content_aware_hash_service_test.dart' show goodAnnotation;
import 'ci_yaml_strings.dart';
import 'create_check_run.dart';

void main() {
  useTestLoggerPerTest();

  late CacheService cache;
  late FakeConfig config;
  late FakeCiYamlFetcher ciYamlFetcher;
  late FakeFirestoreService firestore;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late Scheduler scheduler;
  late FakeGetFilesChanged getFilesChanged;
  late BigQueryService bigQuery;
  late ContentAwareHashService cahs;
  late MockLuciBuildService luci;

  setUp(() {
    ciYamlFetcher = FakeCiYamlFetcher();

    ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionDualCiYaml);
    luci = MockLuciBuildService();
    when(
      luci.getAvailableBuilderSet(
        project: anyNamed('project'),
        bucket: anyNamed('bucket'),
      ),
    ).thenAnswer((inv) async {
      return {'Mac engine_build'};
    });
    when(
      luci.scheduleTryBuilds(
        targets: anyNamed('targets'),
        pullRequest: anyNamed('pullRequest'),
        engineArtifacts: anyNamed('engineArtifacts'),
        checkRunGuard: anyNamed('checkRunGuard'),
      ),
    ).thenAnswer((inv) async {
      return [];
    });
    mockGithubChecksUtil = MockGithubChecksUtil();
    final checkRuns = <CheckRun>[];
    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((inv) async {
      final slug = inv.positionalArguments[1] as RepositorySlug;
      final sha = inv.positionalArguments[2] as String;
      final name = inv.positionalArguments[3] as String?;
      checkRuns.add(
        createGithubCheckRun(
          id: 1,
          owner: slug.owner,
          repo: slug.name,
          sha: sha,
          name: name,
        ),
      );
      return checkRuns.last;
    });
    getFilesChanged = FakeGetFilesChanged.inconclusive();
    getFilesChanged.cannedFiles = ['abc/def'];
    cache = CacheService(inMemory: true);

    final github = MockGitHub();
    when(
      github.request(
        'GET',
        argThat(
          equals(
            'https://api.github.com/repos/flutter/flutter/check-runs/40533761873/annotations',
          ),
        ),
      ),
    ).thenAnswer((_) async => Response(goodAnnotation(), 200));

    final githubService = FakeGithubService(client: github);
    config = FakeConfig(githubService: githubService, githubClient: github);
    firestore = FakeFirestoreService();
    bigQuery = BigQueryService.forTesting(
      MockTabledataResource(),
      MockJobsResource(),
    );

    cahs = ContentAwareHashService(config: config, firestore: firestore);
    scheduler = Scheduler(
      cache: cache,
      config: config,
      githubChecksService: GithubChecksService(
        config,
        githubChecksUtil: mockGithubChecksUtil,
      ),
      getFilesChanged: getFilesChanged,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: luci,
      contentAwareHash: cahs,
      firestore: firestore,
      bigQuery: bigQuery,
    );
  });

  test('only processes workflow events !waitOnContentHash', () async {
    config.dynamicConfig = DynamicConfig.fromJson({
      ...config.dynamicConfig.toJson(),
      'contentAwareHashing': {'waitOnContentHash': false},
    });

    final job = workflowJobTemplate().toWorkflowJob();
    await scheduler.processWorkflowJob(job);

    expect(firestore.documents, isNotEmpty);
    expect(
      firestore,
      existsInStorage(ContentAwareHashBuilds.metadata, [
        isContentAwareHashBuilds
            .hasCommitSha('27bfdee25949bc48044c4e16678f3449dd213b6e')
            .hasContentHash('65038ef4984b927fd1762ef01d35c5ecc34ff5f7')
            .hasStatus(BuildStatus.inProgress)
            .hasWaitingShas([]),
      ]),
    );
    verifyNever(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
        conclusion: anyNamed('conclusion'),
      ),
    );
  });

  test('triggers tests on waitOnContentHash', () async {
    config.dynamicConfig = DynamicConfig.fromJson({
      'contentAwareHashing': {'waitOnContentHash': true},
    });

    final job = workflowJobTemplate().toWorkflowJob();
    await scheduler.processWorkflowJob(job);

    expect(firestore.documents, isNotEmpty);
    expect(
      firestore,
      existsInStorage(ContentAwareHashBuilds.metadata, [
        isContentAwareHashBuilds
            .hasCommitSha('27bfdee25949bc48044c4e16678f3449dd213b6e')
            .hasContentHash('65038ef4984b927fd1762ef01d35c5ecc34ff5f7')
            .hasStatus(BuildStatus.inProgress)
            .hasWaitingShas([]),
      ]),
    );
    verify(
      mockGithubChecksUtil.createCheckRun(
        any,
        RepositorySlug.full('flutter/flutter'),
        '27bfdee25949bc48044c4e16678f3449dd213b6e',
        'Merge Queue Guard',
        output: anyNamed('output'),
        conclusion: anyNamed('conclusion'),
      ),
    ).called(1);

    verify(
      luci.scheduleMergeGroupBuilds(
        commit: anyNamed('commit'),
        targets: anyNamed('targets'),
        contentHash: '65038ef4984b927fd1762ef01d35c5ecc34ff5f7',
      ),
    ).called(1);
  });

  test(
    'triggers tests on waitOnContentHash + completed artifacts (PRE-CAH flip over)',
    () async {
      config.dynamicConfig = DynamicConfig.fromJson({
        'contentAwareHashing': {'waitOnContentHash': true},
      });

      final job = workflowJobTemplate().toWorkflowJob();

      firestore.putDocument(
        ContentAwareHashBuilds(
          createdOn: DateTime(2025, 05, 20),
          contentHash: '65038ef4984b927fd1762ef01d35c5ecc34ff5f7',
          commitSha: 'a' * 40,
          buildStatus: BuildStatus.success,
          waitingShas: [],
        ),
      );

      await scheduler.processWorkflowJob(job);

      verify(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug.full('flutter/flutter'),
          '27bfdee25949bc48044c4e16678f3449dd213b6e',
          'Merge Queue Guard',
          output: anyNamed('output'),
          conclusion: anyNamed('conclusion'),
        ),
      ).called(1);
    },
  );

  test('cancelDestroyedMergeGroupTargets failes the hash document', () async {
    firestore.putDocument(
      ContentAwareHashBuilds(
        createdOn: DateTime(2025, 05, 20),
        contentHash: '65038ef4984b927fd1762ef01d35c5ecc34ff5f7',
        commitSha: 'a' * 40,
        buildStatus: BuildStatus.inProgress,
        waitingShas: [],
      ),
    );

    await scheduler.cancelDestroyedMergeGroupTargets(headSha: 'a' * 40);

    expect(
      firestore,
      existsInStorage(ContentAwareHashBuilds.metadata, [
        isContentAwareHashBuilds
            .hasCommitSha('a' * 40)
            .hasContentHash('65038ef4984b927fd1762ef01d35c5ecc34ff5f7')
            .hasStatus(BuildStatus.failure)
            .hasWaitingShas([]),
      ]),
    );
  });
}

extension on String {
  WorkflowJobEvent toWorkflowJob() =>
      WorkflowJobEvent.fromJson(json.decode(this) as Map<String, Object?>);
}
