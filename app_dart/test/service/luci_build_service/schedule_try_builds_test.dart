// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/pr_check_runs.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/engine_artifacts.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/model/ci_yaml_matcher.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

/// Tests [LuciBuildService] public API related to fetching try-bot builds.
///
/// Specifically:
/// - [LuciBuildService.scheduleTryBuilds]
/// - [LuciBuildService.reschedulePresubmitBuild]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;
  late FakePubSub pubSub;
  late FakeGerritService gerritService;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    pubSub = FakePubSub();
    gerritService = FakeGerritService();
    luci = LuciBuildService(
      config: FakeConfig(firestoreService: firestoreService),
      cache: CacheService(inMemory: true),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
      pubsub: pubSub,
      gerritService: gerritService,
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
      existsInStorage(PrCheckRuns.metadata, [
        isPrCheckRun.hasCheckRuns({'Linux foo': '1'}),
      ]),
    );

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }
    expect(
      PresubmitUserData.fromBytes(scheduleBuild.notify.userData),
      PresubmitUserData(
        repoOwner: 'flutter',
        repoName: 'flutter',
        commitSha: 'headsha123',
        checkRunId: 1,
        commitBranch: 'master',
      ),
    );

    expect(scheduleBuild.properties.fields, {
      'os': bbv2.Value(stringValue: 'abc'),
      'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
      'bringup': bbv2.Value(boolValue: false),
      'git_branch': bbv2.Value(stringValue: 'master'),
      'git_url': bbv2.Value(stringValue: 'https://github.com/flutter/flutter'),
      'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
      'git_repo': bbv2.Value(stringValue: 'flutter'),
      'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
      'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
      'is_fusion': bbv2.Value(stringValue: 'true'),
      'flutter_prebuilt_engine_version': bbv2.Value(stringValue: 'headsha123'),
      'flutter_realm': bbv2.Value(stringValue: 'flutter_archives_v2'),
    });
    expect(scheduleBuild.dimensions, [
      isA<bbv2.RequestedDimension>()
          .having((d) => d.key, 'key', 'os')
          .having((d) => d.value, 'value', 'abc'),
    ]);
  });

  test('builds using an existing engine', () async {
    final pullRequest = generatePullRequest(
      id: 1,
      repo: 'flutter',
      headSha: 'headsha123',
      baseSha: 'basesha123',
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
        engineArtifacts: EngineArtifacts.usingExistingEngine(
          commitSha: pullRequest.base!.sha!,
        ),
      ),
      completion([isTarget.hasName('Linux foo')]),
    );

    expect(
      firestoreService,
      existsInStorage(PrCheckRuns.metadata, [
        isPrCheckRun.hasCheckRuns({'Linux foo': '1'}),
      ]),
    );

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }

    expect(
      PresubmitUserData.fromBytes(scheduleBuild.notify.userData),
      PresubmitUserData(
        repoOwner: 'flutter',
        repoName: 'flutter',
        commitSha: 'headsha123',
        checkRunId: 1,
        commitBranch: 'master',
      ),
    );

    expect(scheduleBuild.properties.fields, {
      'os': bbv2.Value(stringValue: 'abc'),
      'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
      'bringup': bbv2.Value(boolValue: false),
      'git_branch': bbv2.Value(stringValue: 'master'),
      'git_url': bbv2.Value(stringValue: 'https://github.com/flutter/flutter'),
      'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
      'git_repo': bbv2.Value(stringValue: 'flutter'),
      'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
      'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
      'is_fusion': bbv2.Value(stringValue: 'true'),
      'flutter_prebuilt_engine_version': bbv2.Value(stringValue: 'basesha123'),
      'flutter_realm': bbv2.Value(stringValue: ''),
    });
    expect(scheduleBuild.dimensions, [
      isA<bbv2.RequestedDimension>()
          .having((d) => d.key, 'key', 'os')
          .having((d) => d.value, 'value', 'abc'),
    ]);
  });

  // Regression test for https://github.com/flutter/flutter/issues/166014.
  test('provides override labels for flutter/packages', () async {
    final pullRequest = generatePullRequest(
      id: 1,
      repo: 'packages',
      headSha: 'headsha123',
      baseSha: 'basesha123',
      labels: [
        IssueLabel(name: 'override: no versioning needed'),
        IssueLabel(name: 'override: no changelog needed'),
      ],
    );

    final buildTarget = generateTarget(
      1,
      properties: {'os': 'abc'},
      slug: RepositorySlug.full('flutter/packages'),
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

      expect(slug, RepositorySlug.full('flutter/packages'));
      expect(sha, 'headsha123');
      expect(name, 'Linux foo');

      return generateCheckRun(1, name: 'Linux foo');
    });

    await luci.scheduleTryBuilds(
      pullRequest: pullRequest,
      targets: [buildTarget],
      engineArtifacts: EngineArtifacts.usingExistingEngine(
        commitSha: pullRequest.base!.sha!,
      ),
    );

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }

    expect(
      scheduleBuild.properties.fields,
      containsPair(
        'overrides',
        isA<bbv2.Value>().having(
          (v) => v.listValue.values.map((v) => v.stringValue),
          'listValue',
          ['override: no versioning needed', 'override: no changelog needed'],
        ),
      ),
    );
  });

  group('CIPD', () {
    final loggedFallingBackToDefaultRecipe = bufferedLoggerOf(
      contains(logThat(message: contains('Falling back to default recipe'))),
    );

    setUp(() {
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
    });

    test(
      'uses the default recipe without warning outside of flutter/flutter',
      () async {
        await luci.scheduleTryBuilds(
          pullRequest: generatePullRequest(repo: 'packages'),
          targets: [generateTarget(1)],
          engineArtifacts: const EngineArtifacts.noFrameworkTests(
            reason: 'Not flutter/flutter',
          ),
        );

        expect(log, isNot(loggedFallingBackToDefaultRecipe));

        final bbv2.ScheduleBuildRequest scheduleBuild;
        {
          final batchRequest = bbv2.BatchRequest().createEmptyInstance();
          batchRequest.mergeFromProto3Json(pubSub.messages.single);

          expect(batchRequest.requests, hasLength(1));
          scheduleBuild = batchRequest.requests.single.scheduleBuild;
        }

        expect(
          scheduleBuild.properties.fields,
          containsPair(
            'exe_cipd_version',
            isA<bbv2.Value>().having(
              (v) => v.stringValue,
              'stringValue',
              'refs/heads/main',
            ),
          ),
        );
      },
    );

    test(
      'uses the default recipe without warning when using flutter/flutter master',
      () async {
        await luci.scheduleTryBuilds(
          pullRequest: generatePullRequest(repo: 'flutter', branch: 'master'),
          targets: [generateTarget(1)],
          engineArtifacts: const EngineArtifacts.builtFromSource(
            commitSha: 'abc123',
          ),
        );

        expect(log, isNot(loggedFallingBackToDefaultRecipe));

        final bbv2.ScheduleBuildRequest scheduleBuild;
        {
          final batchRequest = bbv2.BatchRequest().createEmptyInstance();
          batchRequest.mergeFromProto3Json(pubSub.messages.single);

          expect(batchRequest.requests, hasLength(1));
          scheduleBuild = batchRequest.requests.single.scheduleBuild;
        }

        expect(
          scheduleBuild.properties.fields,
          containsPair(
            'exe_cipd_version',
            isA<bbv2.Value>().having(
              (v) => v.stringValue,
              'stringValue',
              'refs/heads/main',
            ),
          ),
        );
      },
    );

    test(
      'fallsback to the default recipe if the branch is not found on gerrit',
      () async {
        await luci.scheduleTryBuilds(
          pullRequest: generatePullRequest(
            repo: 'flutter',
            branch: '3.7.0-19.0.pre',
          ),
          targets: [generateTarget(1)],
          engineArtifacts: const EngineArtifacts.builtFromSource(
            commitSha: 'abc123',
          ),
        );

        expect(log, loggedFallingBackToDefaultRecipe);

        final bbv2.ScheduleBuildRequest scheduleBuild;
        {
          final batchRequest = bbv2.BatchRequest().createEmptyInstance();
          batchRequest.mergeFromProto3Json(pubSub.messages.single);

          expect(batchRequest.requests, hasLength(1));
          scheduleBuild = batchRequest.requests.single.scheduleBuild;
        }

        expect(
          scheduleBuild.properties.fields,
          containsPair(
            'exe_cipd_version',
            isA<bbv2.Value>().having(
              (v) => v.stringValue,
              'stringValue',
              'refs/heads/main',
            ),
          ),
        );
      },
    );

    test('uses the CIPD branch if the branch is found on gerrit', () async {
      gerritService.branchesValue = [
        'refs/heads/master',
        'refs/heads/3.7.0-19.0.pre',
      ];
      await luci.scheduleTryBuilds(
        pullRequest: generatePullRequest(
          repo: 'flutter',
          branch: '3.7.0-19.0.pre',
        ),
        targets: [generateTarget(1)],
        engineArtifacts: const EngineArtifacts.builtFromSource(
          commitSha: 'abc123',
        ),
      );

      expect(log, isNot(loggedFallingBackToDefaultRecipe));

      final bbv2.ScheduleBuildRequest scheduleBuild;
      {
        final batchRequest = bbv2.BatchRequest().createEmptyInstance();
        batchRequest.mergeFromProto3Json(pubSub.messages.single);

        expect(batchRequest.requests, hasLength(1));
        scheduleBuild = batchRequest.requests.single.scheduleBuild;
      }

      expect(
        scheduleBuild.properties.fields,
        containsPair(
          'exe_cipd_version',
          isA<bbv2.Value>().having(
            (v) => v.stringValue,
            'stringValue',
            'refs/heads/3.7.0-19.0.pre',
          ),
        ),
      );
    });
  });

  group('reschedulePresubmitBuild', () {
    test('reschedule an existing build', () async {
      late final bbv2.ScheduleBuildRequest scheduleBuildRequest;
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((i) async {
        [scheduleBuildRequest] = i.positionalArguments;
        return generateBbv2Build(Int64(1));
      });

      await expectLater(
        luci.reschedulePresubmitBuild(
          builderName: 'mybuild',
          build: generateBbv2Build(
            Int64(1),
            status: bbv2.Status.FAILURE,
            name: 'Linux Host Engine',
          ),
          nextAttempt: 2,
          userData: PresubmitUserData(
            repoOwner: 'flutter',
            repoName: 'flutter',
            commitBranch: 'master',
            commitSha: 'abc123',
            checkRunId: 1234,
          ),
        ),
        completion(
          isA<bbv2.Build>()
              .having((b) => b.id, 'id', Int64(1))
              .having((b) => b.status, 'status', bbv2.Status.SUCCESS),
        ),
      );

      expect(scheduleBuildRequest.hasGitilesCommit(), isFalse);
      expect(
        scheduleBuildRequest.tags,
        contains(bbv2.StringPair(key: 'current_attempt', value: '2')),
      );
    });

    test('reschedule a a merge queue with gitiles', () async {
      late final bbv2.ScheduleBuildRequest scheduleBuildRequest;
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((i) async {
        [scheduleBuildRequest] = i.positionalArguments;
        return generateBbv2Build(Int64(1));
      });

      await expectLater(
        luci.reschedulePresubmitBuild(
          builderName: 'mybuild',
          nextAttempt: 2,
          userData: PresubmitUserData(
            repoOwner: 'flutter',
            repoName: 'flutter',
            commitBranch: 'master',
            commitSha: 'abc123',
            checkRunId: 1234,
          ),
          build: generateBbv2Build(
            Int64(1),
            status: bbv2.Status.FAILURE,
            name: 'Linux Host Engine',
            input: bbv2.Build_Input(
              gitilesCommit: bbv2.GitilesCommit(
                project: 'mirrors/flutter',
                host: 'flutter.googlesource.com',
                ref:
                    'refs/heads/gh-readonly-queue/master/'
                    'pr-160690-021b2b36275342ad94a1ef44f9748b1e6153b0a3',
                id: '3dc695d1ad9a76a56420efc09fd66abd501fc691',
              ),
            ),
          ),
        ),
        completion(
          isA<bbv2.Build>()
              .having((b) => b.id, 'id', Int64(1))
              .having((b) => b.status, 'status', bbv2.Status.SUCCESS),
        ),
      );

      expect(
        scheduleBuildRequest.gitilesCommit,
        bbv2.GitilesCommit(
          project: 'mirrors/flutter',
          host: 'flutter.googlesource.com',
          ref:
              'refs/heads/gh-readonly-queue/master/'
              'pr-160690-021b2b36275342ad94a1ef44f9748b1e6153b0a3',
          id: '3dc695d1ad9a76a56420efc09fd66abd501fc691',
        ),
      );
      expect(
        scheduleBuildRequest.tags,
        contains(bbv2.StringPair(key: 'current_attempt', value: '2')),
      );
    });
  });
}
