// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart'
    as firestore_commit;
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/exceptions.dart';
import 'package:cocoon_service/src/service/luci_build_service/engine_artifacts.dart';
import 'package:cocoon_service/src/service/luci_build_service/firestore_task_document_name.dart';
import 'package:cocoon_service/src/service/luci_build_service/pending_task.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/build_bucket_messages.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  useTestLoggerPerTest();

  late CacheService cache;
  late FakeConfig config;
  late MockBuildBucketClient mockBuildBucketClient;
  late LuciBuildService service;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakePubSub pubsub;

  final targets = <Target>[
    generateTarget(1, properties: <String, String>{'os': 'abc'}),
  ];
  final pullRequest = generatePullRequest(id: 1, repo: 'cocoon');

  setUp(() {
    mockGithubChecksUtil = MockGithubChecksUtil();
  });

  group('getBuilds', () {
    final macBuild = generateBbv2Build(
      Int64(998),
      name: 'Mac',
      status: bbv2.Status.STARTED,
    );
    final linuxBuild = generateBbv2Build(
      Int64(998),
      name: 'Linux',
      bucket: 'try',
      status: bbv2.Status.STARTED,
    );

    setUp(() {
      cache = CacheService(inMemory: true);
      final githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        gerritService: FakeGerritService(),
        pubsub: pubsub,
      );
    });

    test('Null build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[macBuild],
              ),
            ),
          ],
        );
      });
      final builds = await service.getTryBuilds(
        sha: 'shasha',
        builderName: 'abcd',
      );
      expect(builds.first, macBuild);
    });

    test('Existing prod build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(builds: <bbv2.Build>[]),
            ),
          ],
        );
      });
      final builds = await service.getProdBuilds(builderName: 'abcd');
      expect(builds, isEmpty);
    });

    test('Existing try build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final builds = await service.getTryBuilds(
        sha: 'shasha',
        builderName: 'abcd',
      );
      expect(builds.first, linuxBuild);
    });

    test('Existing try build by pull request', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final builds = await service.getTryBuildsByPullRequest(
        pullRequest: PullRequest(
          id: 998,
          number: 1234,
          base: PullRequestHead(repo: Repository(fullName: 'flutter/cocoon')),
        ),
      );
      expect(builds.first, linuxBuild);
    });
  });

  group('getBuilders', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      final githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        gerritService: FakeGerritService(),
        pubsub: pubsub,
      );
    });

    test('with one rpc call', () async {
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'test1',
              ),
            ),
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'test2',
              ),
            ),
          ],
        );
      });
      final builders = await service.getAvailableBuilderSet();
      expect(builders.length, 2);
      expect(builders.contains('test1'), isTrue);
    });

    test('with more than one rpc calls', () async {
      var retries = -1;
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        retries++;
        if (retries == 0) {
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test1',
                ),
              ),
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test2',
                ),
              ),
            ],
            nextPageToken: 'token',
          );
        } else if (retries == 1) {
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test3',
                ),
              ),
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test4',
                ),
              ),
            ],
          );
        } else {
          return bbv2.ListBuildersResponse(builders: []);
        }
      });
      final builders = await service.getAvailableBuilderSet();
      expect(builders.length, 4);
      expect(builders, <String>{'test1', 'test2', 'test3', 'test4'});
    });
  });

  group('buildsForRepositoryAndPr', () {
    final macBuild = generateBbv2Build(
      Int64(999),
      name: 'Mac',
      status: bbv2.Status.STARTED,
    );
    final linuxBuild = generateBbv2Build(
      Int64(998),
      name: 'Linux',
      status: bbv2.Status.STARTED,
    );

    setUp(() {
      cache = CacheService(inMemory: true);
      final githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        pubsub: pubsub,
      );
    });

    test('Empty responses are handled correctly', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(builds: <bbv2.Build>[]),
            ),
          ],
        );
      });
      final builds = await service.getTryBuilds(
        sha: pullRequest.head!.sha!,
        builderName: null,
      );
      expect(builds, isEmpty);
    });

    test('Response returning a couple of builds', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[macBuild],
              ),
            ),
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final builds = await service.getTryBuilds(
        sha: pullRequest.head!.sha!,
        builderName: null,
      );
      expect(builds, equals(<bbv2.Build>{macBuild, linuxBuild}));
    });
  });

  group('scheduleTryBuilds', () {
    late FakeFirestoreService firestoreService;
    late MockCallbacks callbacks;
    late FakeGerritService gerritService;

    setUp(() {
      firestoreService = FakeFirestoreService();
      callbacks = MockCallbacks();
      cache = CacheService(inMemory: true);
      final githubService = FakeGithubService();
      config = FakeConfig(
        githubService: githubService,
        firestoreService: firestoreService,
      );
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      gerritService = FakeGerritService(branchesValue: <String>['master']);
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        githubChecksUtil: mockGithubChecksUtil,
        gerritService: gerritService,
        pubsub: pubsub,
        initializePrCheckRuns: callbacks.initializePrCheckRuns,
      );
    });

    test('schedule try builds successfully (built from source)', () async {
      when(
        callbacks.initializePrCheckRuns(
          firestoreService: anyNamed('firestoreService'),
          pullRequest: anyNamed('pullRequest'),
          checks: anyNamed('checks'),
        ),
      ).thenAnswer((inv) async {
        return Document(name: '1234-56-7890', fields: {});
      });
      final pullRequest = generatePullRequest();
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              scheduleBuild: generateBbv2Build(Int64(1)),
            ),
          ],
        );
      });
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      final scheduledTargets = await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
        engineArtifacts: EngineArtifacts.builtFromSource(
          commitSha: pullRequest.head!.sha!,
        ),
      );

      final result = verify(
        callbacks.initializePrCheckRuns(
          firestoreService: anyNamed('firestoreService'),
          pullRequest: argThat(equals(pullRequest), named: 'pullRequest'),
          checks: captureAnyNamed('checks'),
        ),
      )..called(1);
      final checkRuns = result.captured.first as List<CheckRun>;
      expect(checkRuns, hasLength(1));
      expect(checkRuns.first.id, 1);
      expect(checkRuns.first.name, 'Linux 1');

      final scheduledTargetNames = scheduledTargets.map(
        (Target target) => target.value.name,
      );
      expect(scheduledTargetNames, <String>['Linux 1']);

      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubsub.messages.single);
      expect(batchRequest.requests.single.scheduleBuild, isNotNull);

      final scheduleBuild = batchRequest.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'try');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-presubmit',
      );

      final userData = PresubmitUserData.fromBytes(
        scheduleBuild.notify.userData,
      );

      expect(
        userData,
        PresubmitUserData(
          repoOwner: 'flutter',
          repoName: 'flutter',
          commitSha: 'abc',
          checkRunId: 1,
          commitBranch: 'master',
        ),
      );

      final properties = scheduleBuild.properties.fields;
      final dimensions = scheduleBuild.dimensions;
      expect(properties, <String, bbv2.Value>{
        'os': bbv2.Value(stringValue: 'abc'),
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'master'),
        'git_url': bbv2.Value(
          stringValue: 'https://github.com/flutter/flutter',
        ),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
        'git_repo': bbv2.Value(stringValue: 'flutter'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
        'is_fusion': bbv2.Value(stringValue: 'true'),
        'flutter_prebuilt_engine_version': bbv2.Value(stringValue: 'abc'),
        'flutter_realm': bbv2.Value(
          stringValue: 'flutter_archives_v2',
        ), // presubmit builds
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    test('schedule try builds successfully (use existing engine)', () async {
      when(
        callbacks.initializePrCheckRuns(
          firestoreService: anyNamed('firestoreService'),
          pullRequest: anyNamed('pullRequest'),
          checks: anyNamed('checks'),
        ),
      ).thenAnswer((inv) async {
        return Document(name: '1234-56-7890', fields: {});
      });
      final pullRequest = generatePullRequest();
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              scheduleBuild: generateBbv2Build(Int64(1)),
            ),
          ],
        );
      });
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      final scheduledTargets = await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
        engineArtifacts: EngineArtifacts.usingExistingEngine(
          commitSha: pullRequest.base!.sha!,
        ),
      );

      final result = verify(
        callbacks.initializePrCheckRuns(
          firestoreService: anyNamed('firestoreService'),
          pullRequest: argThat(equals(pullRequest), named: 'pullRequest'),
          checks: captureAnyNamed('checks'),
        ),
      )..called(1);
      final checkRuns = result.captured.first as List<CheckRun>;
      expect(checkRuns, hasLength(1));
      expect(checkRuns.first.id, 1);
      expect(checkRuns.first.name, 'Linux 1');

      final scheduledTargetNames = scheduledTargets.map(
        (Target target) => target.value.name,
      );
      expect(scheduledTargetNames, <String>['Linux 1']);

      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubsub.messages.single);
      expect(batchRequest.requests.single.scheduleBuild, isNotNull);

      final scheduleBuild = batchRequest.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'try');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-presubmit',
      );

      final userData = PresubmitUserData.fromBytes(
        scheduleBuild.notify.userData,
      );
      expect(
        userData,
        PresubmitUserData(
          repoOwner: 'flutter',
          repoName: 'flutter',
          commitSha: 'abc',
          checkRunId: 1,
          commitBranch: 'master',
        ),
      );

      final properties = scheduleBuild.properties.fields;
      final dimensions = scheduleBuild.dimensions;
      expect(properties, <String, bbv2.Value>{
        'os': bbv2.Value(stringValue: 'abc'),
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'master'),
        'git_url': bbv2.Value(
          stringValue: 'https://github.com/flutter/flutter',
        ),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
        'git_repo': bbv2.Value(stringValue: 'flutter'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
        'is_fusion': bbv2.Value(stringValue: 'true'),
        'flutter_prebuilt_engine_version': bbv2.Value(stringValue: 'def'),
        'flutter_realm': bbv2.Value(stringValue: ''),
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    // Regression test for https://github.com/flutter/flutter/issues/166014.
    test('provides override labels for flutter/packages', () async {
      when(
        callbacks.initializePrCheckRuns(
          firestoreService: anyNamed('firestoreService'),
          pullRequest: anyNamed('pullRequest'),
          checks: anyNamed('checks'),
        ),
      ).thenAnswer((inv) async {
        return Document(name: '1234-56-7890', fields: {});
      });
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux repo_check'));

      await service.scheduleTryBuilds(
        pullRequest: generatePullRequest(
          repo: 'packages',
          labels: [
            IssueLabel(name: 'override: no versioning needed'),
            IssueLabel(name: 'override: no changelog needed'),
          ],
        ),
        targets: targets,
        engineArtifacts: EngineArtifacts.usingExistingEngine(
          commitSha: pullRequest.base!.sha!,
        ),
      );

      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubsub.messages.single);
      expect(batchRequest.requests.single.scheduleBuild, isNotNull);

      final scheduleBuild = batchRequest.requests.single.scheduleBuild;
      final properties = scheduleBuild.properties.fields;
      expect(
        properties,
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
          // ignore: discarded_futures
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
        when(
          // ignore: discarded_futures
          callbacks.initializePrCheckRuns(
            firestoreService: anyNamed('firestoreService'),
            pullRequest: anyNamed('pullRequest'),
            checks: anyNamed('checks'),
          ),
        ).thenAnswer((inv) async {
          return Document(name: '1234-56-7890', fields: {});
        });
      });

      test(
        'uses the default recipe without warning outside of flutter/flutter',
        () async {
          await service.scheduleTryBuilds(
            pullRequest: generatePullRequest(repo: 'packages'),
            targets: targets,
            engineArtifacts: const EngineArtifacts.noFrameworkTests(
              reason: 'Not flutter/flutter',
            ),
          );

          expect(log, isNot(loggedFallingBackToDefaultRecipe));

          final scheduleBuild =
              pubsub.messages.first['requests'].first['scheduleBuild']
                  as Map<String, Object?>;
          expect(
            scheduleBuild['properties'],
            containsPair('exe_cipd_version', 'refs/heads/main'),
          );
        },
      );

      test(
        'uses the default recipe without warning when using flutter/flutter master',
        () async {
          await service.scheduleTryBuilds(
            pullRequest: generatePullRequest(repo: 'flutter', branch: 'master'),
            targets: targets,
            engineArtifacts: const EngineArtifacts.builtFromSource(
              commitSha: 'abc123',
            ),
          );

          expect(log, isNot(loggedFallingBackToDefaultRecipe));

          final scheduleBuild =
              pubsub.messages.first['requests'].first['scheduleBuild']
                  as Map<String, Object?>;
          expect(
            scheduleBuild['properties'],
            containsPair('exe_cipd_version', 'refs/heads/main'),
          );
        },
      );

      test(
        'fallsback to the default recipe if the branch is not found on gerrit',
        () async {
          await service.scheduleTryBuilds(
            pullRequest: generatePullRequest(
              repo: 'flutter',
              branch: '3.7.0-19.0.pre',
            ),
            targets: targets,
            engineArtifacts: const EngineArtifacts.builtFromSource(
              commitSha: 'abc123',
            ),
          );

          expect(log, loggedFallingBackToDefaultRecipe);

          final scheduleBuild =
              pubsub.messages.first['requests'].first['scheduleBuild']
                  as Map<String, Object?>;
          expect(
            scheduleBuild['properties'],
            containsPair('exe_cipd_version', 'refs/heads/main'),
          );
        },
      );

      test('uses the CIPD branch if the branch is found on gerrit', () async {
        gerritService.branchesValue = [
          'refs/heads/master',
          'refs/heads/3.7.0-19.0.pre',
        ];
        await service.scheduleTryBuilds(
          pullRequest: generatePullRequest(
            repo: 'flutter',
            branch: '3.7.0-19.0.pre',
          ),
          targets: targets,
          engineArtifacts: const EngineArtifacts.builtFromSource(
            commitSha: 'abc123',
          ),
        );

        expect(log, isNot(loggedFallingBackToDefaultRecipe));

        final scheduleBuild =
            pubsub.messages.first['requests'].first['scheduleBuild']
                as Map<String, Object?>;
        expect(
          scheduleBuild['properties'],
          containsPair('exe_cipd_version', 'refs/heads/3.7.0-19.0.pre'),
        );
      });
    });

    test('schedule try builds with github build labels successfully', () async {
      final pullRequest = generatePullRequest();
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              scheduleBuild: generateBbv2Build(Int64(1)),
            ),
          ],
        );
      });
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final scheduledTargets = await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
        engineArtifacts: EngineArtifacts.builtFromSource(
          commitSha: pullRequest.head!.sha!,
        ),
      );
      final scheduledTargetNames = scheduledTargets.map(
        (Target target) => target.value.name,
      );
      expect(scheduledTargetNames, <String>['Linux 1']);

      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubsub.messages.single);
      expect(batchRequest.requests.single.scheduleBuild, isNotNull);

      final scheduleBuild = batchRequest.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'try');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-presubmit',
      );

      final userData = PresubmitUserData.fromBytes(
        scheduleBuild.notify.userData,
      );
      expect(
        userData,
        PresubmitUserData(
          repoOwner: 'flutter',
          repoName: 'flutter',
          commitSha: 'abc',
          checkRunId: 1,
          commitBranch: 'master',
        ),
      );

      final properties = scheduleBuild.properties.fields;
      final dimensions = scheduleBuild.dimensions;
      expect(properties, <String, bbv2.Value>{
        'os': bbv2.Value(stringValue: 'abc'),
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'master'),
        'is_fusion': bbv2.Value(stringValue: 'true'),
        'git_url': bbv2.Value(
          stringValue: 'https://github.com/flutter/flutter',
        ),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
        'git_repo': bbv2.Value(stringValue: 'flutter'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
        'flutter_prebuilt_engine_version': bbv2.Value(stringValue: 'abc'),
        'flutter_realm': bbv2.Value(stringValue: 'flutter_archives_v2'),
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    test(
      'schedule try builds includes flutter_prebuilt_engine_version',
      () async {
        when(
          callbacks.initializePrCheckRuns(
            firestoreService: anyNamed('firestoreService'),
            pullRequest: anyNamed('pullRequest'),
            checks: anyNamed('checks'),
          ),
        ).thenAnswer((inv) async {
          return Document(name: '1234-56-7890', fields: {});
        });
        final pullRequest = generatePullRequest();
        when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
          return bbv2.BatchResponse(
            responses: <bbv2.BatchResponse_Response>[
              bbv2.BatchResponse_Response(
                scheduleBuild: generateBbv2Build(Int64(1)),
              ),
            ],
          );
        });
        when(
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

        final scheduledTargets = await service.scheduleTryBuilds(
          pullRequest: pullRequest,
          targets: targets,
          engineArtifacts: EngineArtifacts.usingExistingEngine(
            commitSha: pullRequest.base!.sha!,
          ),
        );

        final result = verify(
          callbacks.initializePrCheckRuns(
            firestoreService: anyNamed('firestoreService'),
            pullRequest: argThat(equals(pullRequest), named: 'pullRequest'),
            checks: captureAnyNamed('checks'),
          ),
        )..called(1);
        final checkRuns = result.captured.first as List<CheckRun>;
        expect(checkRuns, hasLength(1));
        expect(checkRuns.first.id, 1);
        expect(checkRuns.first.name, 'Linux 1');

        final scheduledTargetNames = scheduledTargets.map(
          (Target target) => target.value.name,
        );
        expect(scheduledTargetNames, <String>['Linux 1']);

        final batchRequest = bbv2.BatchRequest().createEmptyInstance();
        batchRequest.mergeFromProto3Json(pubsub.messages.single);
        expect(batchRequest.requests.single.scheduleBuild, isNotNull);

        final scheduleBuild = batchRequest.requests.single.scheduleBuild;
        expect(scheduleBuild.builder.bucket, 'try');
        expect(scheduleBuild.builder.builder, 'Linux 1');
        expect(
          scheduleBuild.notify.pubsubTopic,
          'projects/flutter-dashboard/topics/build-bucket-presubmit',
        );

        final userData = PresubmitUserData.fromBytes(
          scheduleBuild.notify.userData,
        );
        expect(
          userData,
          PresubmitUserData(
            repoOwner: 'flutter',
            repoName: 'flutter',
            commitSha: 'abc',
            checkRunId: 1,
            commitBranch: 'master',
          ),
        );

        final properties = scheduleBuild.properties.fields;
        final dimensions = scheduleBuild.dimensions;
        expect(properties, <String, bbv2.Value>{
          'os': bbv2.Value(stringValue: 'abc'),
          'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
          'bringup': bbv2.Value(boolValue: false),
          'git_branch': bbv2.Value(stringValue: 'master'),
          'git_url': bbv2.Value(
            stringValue: 'https://github.com/flutter/flutter',
          ),
          'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
          'git_repo': bbv2.Value(stringValue: 'flutter'),
          'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
          'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
          'is_fusion': bbv2.Value(stringValue: 'true'),
          'flutter_prebuilt_engine_version': bbv2.Value(stringValue: 'def'),
          'flutter_realm': bbv2.Value(stringValue: ''),
        });
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'os');
        expect(dimensions[0].value, 'abc');
      },
    );

    test('schedule try builds with github build labels successfully', () async {
      final pullRequest = generatePullRequest();
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              scheduleBuild: generateBbv2Build(Int64(1)),
            ),
          ],
        );
      });
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final scheduledTargets = await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
        engineArtifacts: EngineArtifacts.builtFromSource(
          commitSha: pullRequest.head!.sha!,
        ),
      );
      final scheduledTargetNames = scheduledTargets.map(
        (Target target) => target.value.name,
      );
      expect(scheduledTargetNames, <String>['Linux 1']);

      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubsub.messages.single);
      expect(batchRequest.requests.single.scheduleBuild, isNotNull);

      final scheduleBuild = batchRequest.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'try');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-presubmit',
      );

      final userData = PresubmitUserData.fromBytes(
        scheduleBuild.notify.userData,
      );
      expect(
        userData,
        PresubmitUserData(
          repoOwner: 'flutter',
          repoName: 'flutter',
          commitSha: 'abc',
          checkRunId: 1,
          commitBranch: 'master',
        ),
      );

      final properties = scheduleBuild.properties.fields;
      final dimensions = scheduleBuild.dimensions;
      expect(properties, <String, bbv2.Value>{
        'os': bbv2.Value(stringValue: 'abc'),
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'master'),
        'git_url': bbv2.Value(
          stringValue: 'https://github.com/flutter/flutter',
        ),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
        'git_repo': bbv2.Value(stringValue: 'flutter'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
        'is_fusion': bbv2.Value(stringValue: 'true'),
        'flutter_prebuilt_engine_version': bbv2.Value(stringValue: 'abc'),
        'flutter_realm': bbv2.Value(stringValue: 'flutter_archives_v2'),
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    test(
      'schedule try builds includes flutter_prebuilt_engine_version',
      () async {
        when(
          callbacks.initializePrCheckRuns(
            firestoreService: anyNamed('firestoreService'),
            pullRequest: anyNamed('pullRequest'),
            checks: anyNamed('checks'),
          ),
        ).thenAnswer((inv) async {
          return Document(name: '1234-56-7890', fields: {});
        });
        final pullRequest = generatePullRequest();
        when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
          return bbv2.BatchResponse(
            responses: <bbv2.BatchResponse_Response>[
              bbv2.BatchResponse_Response(
                scheduleBuild: generateBbv2Build(Int64(1)),
              ),
            ],
          );
        });
        when(
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

        await service.scheduleTryBuilds(
          pullRequest: pullRequest,
          targets: targets,
          engineArtifacts: const EngineArtifacts.builtFromSource(
            commitSha: 'sha1234',
          ),
        );

        final batchRequest = bbv2.BatchRequest().createEmptyInstance();
        batchRequest.mergeFromProto3Json(pubsub.messages.single);
        expect(batchRequest.requests.single.scheduleBuild, isNotNull);

        final scheduleBuild = batchRequest.requests.single.scheduleBuild;
        final properties = scheduleBuild.properties.fields;

        expect(properties, contains('flutter_prebuilt_engine_version'));
        expect(
          properties['flutter_prebuilt_engine_version']!.stringValue,
          'sha1234',
        );
        expect(properties, contains('flutter_realm'));
        expect(properties['flutter_realm']!.stringValue, 'flutter_archives_v2');
      },
    );

    test('Schedule builds no-ops when targets list is empty', () async {
      await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: <Target>[],
        engineArtifacts: const EngineArtifacts.noFrameworkTests(
          reason: 'Just a test',
        ),
      );
      verifyNever(mockGithubChecksUtil.createCheckRun(any, any, any, any));
    });
  });

  group('schedulePostsubmitBuilds', () {
    late DatastoreService datastore;
    late FakeFirestoreService firestoreService;

    setUp(() {
      config = FakeConfig();
      datastore = DatastoreService(config.db, 5);
      firestoreService = FakeFirestoreService();
      cache = CacheService(inMemory: true);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
    });

    test('schedule packages postsubmit builds successfully', () async {
      final commit = generateCommit(1, branch: 'main', repo: 'packages');
      when(
        mockGithubChecksUtil.createCheckRun(
          any,
          Config.packagesSlug,
          any,
          'Linux 1',
        ),
      ).thenAnswer((_) async => generateCheckRun(1));
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 1',
              ),
            ),
          ],
        );
      });
      final toBeScheduled = PendingTask(
        target: generateTarget(
          1,
          properties: <String, String>{
            'recipe': 'devicelab/devicelab',
            'os': 'debian-10.12',
          },
          slug: Config.packagesSlug,
        ),
        task: generateTask(1, parent: commit),
        priority: LuciBuildService.kDefaultPriority,
      );
      await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <PendingTask>[toBeScheduled],
      );
      // Only one batch request should be published
      expect(pubsub.messages.length, 1);

      final request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      expect(request.requests.single.scheduleBuild, isNotNull);

      final scheduleBuild = request.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'prod');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-postsubmit',
      );

      final userData = PostsubmitUserData.fromBytes(
        scheduleBuild.notify.userData,
      );
      expect(
        userData,
        PostsubmitUserData(
          commitKey: 'flutter/packages/main/1',
          taskKey: '1',
          firestoreTaskDocumentName: FirestoreTaskDocumentName.parse(
            '1_task1_1',
          ),
          checkRunId: 1,
        ),
      );

      final properties = scheduleBuild.properties.fields;
      expect(properties, <String, bbv2.Value>{
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'main'),
        'git_repo': bbv2.Value(stringValue: 'packages'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
        'os': bbv2.Value(stringValue: 'debian-10.12'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
      });

      expect(
        scheduleBuild.exe,
        bbv2.Executable(cipdVersion: 'refs/heads/main'),
      );
      expect(scheduleBuild.dimensions, isNotEmpty);
      expect(
        scheduleBuild.dimensions
            .singleWhere(
              (bbv2.RequestedDimension dimension) => dimension.key == 'os',
            )
            .value,
        'debian-10.12',
      );
    });

    test(
      'schedule packages postsubmit builds successfully with fusion',
      () async {
        final commit = generateCommit(0);
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            Config.packagesSlug,
            any,
            'Linux 1',
          ),
        ).thenAnswer((_) async => generateCheckRun(1));
        when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'Linux 1',
                ),
              ),
            ],
          );
        });
        final toBeScheduled = PendingTask(
          target: generateTarget(
            1,
            properties: <String, String>{
              'recipe': 'devicelab/devicelab',
              'os': 'debian-10.12',
            },
            slug: Config.packagesSlug,
          ),
          task: generateTask(1),
          priority: LuciBuildService.kDefaultPriority,
        );
        await service.schedulePostsubmitBuilds(
          commit: commit,
          toBeScheduled: <PendingTask>[toBeScheduled],
        );
        // Only one batch request should be published
        expect(pubsub.messages.length, 1);

        final request = bbv2.BatchRequest().createEmptyInstance();
        request.mergeFromProto3Json(pubsub.messages.single);
        expect(request.requests.single.scheduleBuild, isNotNull);

        final scheduleBuild = request.requests.single.scheduleBuild;
        expect(scheduleBuild.builder.bucket, 'prod');
        expect(scheduleBuild.builder.builder, 'Linux 1');
        expect(
          scheduleBuild.notify.pubsubTopic,
          'projects/flutter-dashboard/topics/build-bucket-postsubmit',
        );

        final userData = PostsubmitUserData.fromBytes(
          scheduleBuild.notify.userData,
        );
        expect(
          userData,
          PostsubmitUserData(
            commitKey: 'flutter/flutter/master/1',
            taskKey: '1',
            firestoreTaskDocumentName: FirestoreTaskDocumentName.parse(
              '0_task1_1',
            ),
            checkRunId: 1,
          ),
        );

        final properties = scheduleBuild.properties.fields;
        expect(properties, <String, bbv2.Value>{
          'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
          'bringup': bbv2.Value(boolValue: false),
          'git_branch': bbv2.Value(stringValue: 'master'),
          'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/master'),
          'os': bbv2.Value(stringValue: 'debian-10.12'),
          'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
          'is_fusion': bbv2.Value(stringValue: 'true'),
          'git_repo': bbv2.Value(stringValue: 'flutter'),
        });

        expect(
          scheduleBuild.exe,
          bbv2.Executable(cipdVersion: 'refs/heads/master'),
        );
        expect(scheduleBuild.dimensions, isNotEmpty);
        expect(
          scheduleBuild.dimensions
              .singleWhere(
                (bbv2.RequestedDimension dimension) => dimension.key == 'os',
              )
              .value,
          'debian-10.12',
        );
      },
    );

    test(
      'schedule postsubmit builds with correct userData for checkRuns',
      () async {
        when(
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
        final commit = generateCommit(0, repo: 'packages');
        when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'Linux 1',
                ),
              ),
            ],
          );
        });
        final toBeScheduled = PendingTask(
          target: generateTarget(
            1,
            properties: <String, String>{'os': 'debian-10.12'},
            slug: RepositorySlug('flutter', 'packages'),
          ),
          task: generateTask(1),
          priority: LuciBuildService.kDefaultPriority,
        );
        await service.schedulePostsubmitBuilds(
          commit: commit,
          toBeScheduled: <PendingTask>[toBeScheduled],
        );
        // Only one batch request should be published
        expect(pubsub.messages.length, 1);

        final request = bbv2.BatchRequest().createEmptyInstance();
        request.mergeFromProto3Json(pubsub.messages.single);
        expect(request.requests.single.scheduleBuild, isNotNull);

        final scheduleBuild = request.requests.single.scheduleBuild;
        expect(scheduleBuild.builder.bucket, 'prod');
        expect(scheduleBuild.builder.builder, 'Linux 1');
        expect(
          scheduleBuild.notify.pubsubTopic,
          'projects/flutter-dashboard/topics/build-bucket-postsubmit',
        );

        final userData = PostsubmitUserData.fromBytes(
          scheduleBuild.notify.userData,
        );
        expect(
          userData,
          PostsubmitUserData(
            commitKey: 'flutter/flutter/master/1',
            taskKey: '1',
            firestoreTaskDocumentName: FirestoreTaskDocumentName.parse(
              '0_task1_1',
            ),
            checkRunId: 1,
          ),
        );
      },
    );

    test(
      'return the orignal list when hitting buildbucket exception',
      () async {
        final commit = generateCommit(0, repo: 'packages');
        when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
          throw const BuildBucketException(1, 'error');
        });
        final toBeScheduled = PendingTask(
          target: generateTarget(
            1,
            properties: <String, String>{'os': 'debian-10.12'},
            slug: RepositorySlug('flutter', 'packages'),
          ),
          task: generateTask(1),
          priority: LuciBuildService.kDefaultPriority,
        );
        final results = await service.schedulePostsubmitBuilds(
          commit: commit,
          toBeScheduled: <PendingTask>[toBeScheduled],
        );
        expect(results, <PendingTask>[toBeScheduled]);
      },
    );

    test('reschedule using checkrun event fails gracefully', () async {
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(builds: <bbv2.Build>[]),
            ),
          ],
        );
      });

      final pushMessage = generateCheckRunEvent(
        action: 'created',
        numberOfPullRequests: 1,
      );
      final jsonMap = json.decode(pushMessage.data!) as Map<String, dynamic>;
      final jsonSubMap =
          json.decode(jsonMap['2'] as String) as Map<String, dynamic>;
      final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(jsonSubMap);

      expect(
        () async => service.reschedulePostsubmitBuildUsingCheckRunEvent(
          checkRunEvent,
          commit: generateCommit(0),
          task: generateTask(0),
          target: generateTarget(0),
          taskDocument: generateFirestoreTask(0),
          datastore: datastore,
          firestoreService: firestoreService,
        ),
        throwsA(const TypeMatcher<NoBuildFoundException>()),
      );
    });

    test('reschedule using checkrun event successfully', () async {
      when(
        firestoreService.mock.batchWriteDocuments(captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  generateBbv2Build(
                    Int64(999),
                    name: 'Linux 1',
                    status: bbv2.Status.ENDED_MASK,
                    input: bbv2.Build_Input(
                      properties: bbv2.Struct(fields: {}),
                    ),
                    tags: <bbv2.StringPair>[],
                  ),
                ],
              ),
            ),
          ],
        );
      });

      final pushMessage = generateCheckRunEvent(
        action: 'created',
        numberOfPullRequests: 1,
      );
      final jsonMap = json.decode(pushMessage.data!) as Map<String, dynamic>;
      final jsonSubMap =
          json.decode(jsonMap['2'] as String) as Map<String, dynamic>;
      final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(jsonSubMap);

      final taskDocument = generateFirestoreTask(0);
      final task = generateTask(0);
      expect(taskDocument.attempts, 1);
      expect(task.attempts, 1);
      await service.reschedulePostsubmitBuildUsingCheckRunEvent(
        checkRunEvent,
        commit: generateCommit(0),
        task: task,
        target: generateTarget(0),
        taskDocument: taskDocument,
        datastore: datastore,
        firestoreService: firestoreService,
      );
      expect(taskDocument.attempts, 2);
      expect(task.attempts, 2);
      expect(pubsub.messages.length, 1);
    });

    test(
      'do not create postsubmit checkrun for bringup: true target',
      () async {
        when(
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
        final commit = generateCommit(0, repo: Config.packagesSlug.name);
        when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'Linux 1',
                ),
              ),
            ],
          );
        });
        final toBeScheduled = PendingTask(
          target: generateTarget(
            1,
            properties: <String, String>{'os': 'debian-10.12'},
            bringup: true,
            slug: Config.packagesSlug,
          ),
          task: generateTask(1, parent: commit),
          priority: LuciBuildService.kDefaultPriority,
        );
        await service.schedulePostsubmitBuilds(
          commit: commit,
          toBeScheduled: <PendingTask>[toBeScheduled],
        );
        // Only one batch request should be published
        expect(pubsub.messages.length, 1);

        final request = bbv2.BatchRequest().createEmptyInstance();
        request.mergeFromProto3Json(pubsub.messages.single);
        expect(request.requests.single.scheduleBuild, isNotNull);

        final scheduleBuild = request.requests.single.scheduleBuild;
        expect(scheduleBuild.builder.bucket, 'staging');
        expect(scheduleBuild.builder.builder, 'Linux 1');
        expect(
          scheduleBuild.notify.pubsubTopic,
          'projects/flutter-dashboard/topics/build-bucket-postsubmit',
        );
        final userData = PostsubmitUserData.fromBytes(
          scheduleBuild.notify.userData,
        );
        expect(
          userData,
          PostsubmitUserData(
            commitKey: 'flutter/packages/master/0',
            taskKey: '1',
            firestoreTaskDocumentName: FirestoreTaskDocumentName.parse(
              '0_task1_1',
            ),
            checkRunId: null,
          ),
        );
      },
    );

    test('Skip non-existing builder', () async {
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final commit = generateCommit(0);
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 2'));
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 2',
              ),
            ),
          ],
        );
      });
      final toBeScheduled1 = PendingTask(
        target: generateTarget(
          1,
          properties: <String, String>{'os': 'debian-10.12'},
        ),
        task: generateTask(1),
        priority: LuciBuildService.kDefaultPriority,
      );
      final toBeScheduled2 = PendingTask(
        target: generateTarget(
          2,
          properties: <String, String>{'os': 'debian-10.12'},
        ),
        task: generateTask(1),
        priority: LuciBuildService.kDefaultPriority,
      );
      await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <PendingTask>[toBeScheduled1, toBeScheduled2],
      );
      expect(pubsub.messages.length, 1);
      final request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      // Only existing builder: `Linux 2` is scheduled.
      expect(request.requests.length, 1);
      expect(request.requests.single.scheduleBuild, isNotNull);
      final scheduleBuild = request.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'prod');
      expect(scheduleBuild.builder.builder, 'Linux 2');
    });
  });

  group('schedulePresubmitBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: FakeConfig(),
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
    });
  });

  group('cancelBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        pubsub: pubsub,
      );
    });

    test('Cancel builds when build list is empty', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(responses: <bbv2.BatchResponse_Response>[]);
      });
      await service.cancelBuilds(
        pullRequest: pullRequest,
        reason: 'new builds',
      );
      // This is okay, it is getting called twice when it runs cancel builds
      // because the call is no longer being short-circuited. It calls batch in
      // tryBuildsForPullRequest and it calls in the top level cancelBuilds
      // function.
      verify(mockBuildBucketClient.batch(any)).called(1);
    });

    test('Cancel builds that are scheduled', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  generateBbv2Build(
                    Int64(998),
                    name: 'Linux',
                    status: bbv2.Status.STARTED,
                  ),
                ],
              ),
            ),
          ],
        );
      });
      await service.cancelBuilds(
        pullRequest: pullRequest,
        reason: 'new builds',
      );

      final captured = verify(mockBuildBucketClient.batch(captureAny)).captured;

      final capturedBatchRequests = <bbv2.BatchRequest_Request>[];
      for (dynamic cap in captured) {
        capturedBatchRequests.add((cap as bbv2.BatchRequest).requests.first);
      }

      final searchBuildRequest =
          capturedBatchRequests
              .firstWhere((req) => req.hasSearchBuilds())
              .searchBuilds;
      final cancelBuildRequest =
          capturedBatchRequests
              .firstWhere((req) => req.hasCancelBuild())
              .cancelBuild;
      expect(searchBuildRequest, isNotNull);
      expect(cancelBuildRequest, isNotNull);

      expect(cancelBuildRequest.id, Int64(998));
      expect(cancelBuildRequest.summaryMarkdown, 'new builds');
    });
  });

  group('failedBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      final githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        pubsub: pubsub,
      );
    });

    test('Failed builds from an empty list', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(responses: <bbv2.BatchResponse_Response>[]);
      });
      final result = await service.failedBuilds(
        pullRequest: pullRequest,
        targets: <Target>[],
      );
      expect(result, isEmpty);
    });

    test('Failed builds from a list of builds with failures', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  generateBbv2Build(
                    Int64(998),
                    name: 'Linux 1',
                    status: bbv2.Status.FAILURE,
                  ),
                ],
              ),
            ),
          ],
        );
      });
      final result = await service.failedBuilds(
        pullRequest: pullRequest,
        targets: <Target>[generateTarget(1)],
      );
      expect(result, hasLength(1));
    });
  });

  group('rescheduleBuild', () {
    late bbv2.BuildsV2PubSub rescheduleBuild;

    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        pubsub: pubsub,
      );
      rescheduleBuild = createBuild(
        Int64(1),
        status: bbv2.Status.FAILURE,
        builder: 'Linux Host Engine',
      );
    });

    test('Reschedule an existing build', () async {
      when(
        mockBuildBucketClient.scheduleBuild(any),
      ).thenAnswer((_) async => generateBbv2Build(Int64(1)));
      final build = await service.reschedulePresubmitBuild(
        builderName: 'mybuild',
        build: rescheduleBuild.build,
        nextAttempt: 2,
        userData: PresubmitUserData(
          repoOwner: 'flutter',
          repoName: 'flutter',
          commitBranch: 'master',
          commitSha: 'abc123',
          checkRunId: 1234,
        ),
      );
      expect(build.id, Int64(1));
      expect(build.status, bbv2.Status.SUCCESS);
      final captured =
          verify(mockBuildBucketClient.scheduleBuild(captureAny)).captured;
      expect(captured.length, 1);

      final scheduleBuildRequest = captured[0] as bbv2.ScheduleBuildRequest;
      expect(scheduleBuildRequest, isNotNull);
      expect(scheduleBuildRequest.hasGitilesCommit(), isFalse);
      final tags = scheduleBuildRequest.tags;
      final attemptPair = tags.firstWhere(
        (element) => element.key == 'current_attempt',
      );
      expect(attemptPair.value, '2');
    });

    test('Reschedules merge queue with gitiles', () async {
      when(
        mockBuildBucketClient.scheduleBuild(any),
      ).thenAnswer((_) async => generateBbv2Build(Int64(1)));
      rescheduleBuild.build.tags.add(
        bbv2.StringPair(key: LuciBuildService.kMergeQueueKey, value: 'true'),
      );
      rescheduleBuild.build.input.gitilesCommit = bbv2.GitilesCommit(
        project: 'mirrors/flutter',
        host: 'flutter.googlesource.com',
        ref:
            'refs/heads/gh-readonly-queue/master/pr-160690-021b2b36275342ad94a1ef44f9748b1e6153b0a3',
        id: '3dc695d1ad9a76a56420efc09fd66abd501fc691',
      );
      final build = await service.reschedulePresubmitBuild(
        builderName: 'mybuild',
        build: rescheduleBuild.build,
        nextAttempt: 2,
        userData: PresubmitUserData(
          repoOwner: 'flutter',
          repoName: 'flutter',
          commitBranch: 'master',
          commitSha: 'abc123',
          checkRunId: 1234,
        ),
      );
      expect(build.id, Int64(1));
      expect(build.status, bbv2.Status.SUCCESS);
      final captured =
          verify(mockBuildBucketClient.scheduleBuild(captureAny)).captured;
      expect(captured.length, 1);

      final scheduleBuildRequest = captured[0] as bbv2.ScheduleBuildRequest;
      expect(scheduleBuildRequest, isNotNull);
      expect(scheduleBuildRequest.hasGitilesCommit(), isTrue);
      final tags = scheduleBuildRequest.tags;
      final attemptPair = tags.firstWhere(
        (element) => element.key == 'current_attempt',
      );
      expect(attemptPair.value, '2');
      expect(
        scheduleBuildRequest.tags,
        contains(
          bbv2.StringPair(key: LuciBuildService.kMergeQueueKey, value: 'true'),
        ),
      );
      expect(
        scheduleBuildRequest.gitilesCommit,
        bbv2.GitilesCommit(
          project: 'mirrors/flutter',
          host: 'flutter.googlesource.com',
          ref:
              'refs/heads/gh-readonly-queue/master/pr-160690-021b2b36275342ad94a1ef44f9748b1e6153b0a3',
          id: '3dc695d1ad9a76a56420efc09fd66abd501fc691',
        ),
      );
    });
  });

  group('checkRerunBuilder', () {
    late Commit commit;
    late Commit totCommit;
    late DatastoreService datastore;
    late FakeFirestoreService firestoreService;

    firestore.Task? firestoreTask;
    firestore_commit.Commit? firestoreCommit;
    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      firestoreTask = null;
      firestoreCommit = null;
      firestoreService = FakeFirestoreService();
      mockBuildBucketClient = MockBuildBucketClient();
      when(
        // ignore: discarded_futures
        mockGithubChecksUtil.createCheckRun(
          any,
          any,
          any,
          any,
          output: anyNamed('output'),
        ),
      ).thenAnswer((realInvocation) async => generateCheckRun(1));
      when(
        // ignore: discarded_futures
        firestoreService.mock.batchWriteDocuments(captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      // ignore: discarded_futures
      when(firestoreService.mock.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<firestore_commit.Commit>.value(firestoreCommit);
      });
      when(
        // ignore: discarded_futures
        firestoreService.mock.queryRecentCommits(
          limit: captureAnyNamed('limit'),
          slug: captureAnyNamed('slug'),
          branch: captureAnyNamed('branch'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<firestore_commit.Commit>>.value(
          <firestore_commit.Commit>[firestoreCommit!],
        );
      });
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
      datastore = DatastoreService(config.db, 5);
    });

    test('Pass repo and properties correctly', () async {
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusFailed,
      );
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1, repo: 'flutter', branch: 'main');
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final task = generateTask(
        1,
        status: Task.statusFailed,
        parent: totCommit,
        buildNumber: 1,
      );
      final target = generateTarget(1);
      expect(task.attempts, 1);
      expect(task.status, Task.statusFailed);
      final rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: firestoreService,
        taskDocument: firestoreTask!,
      );
      expect(pubsub.messages.length, 1);

      final request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      expect(request, isNotNull);
      final scheduleBuildRequest = request.requests.first.scheduleBuild;

      final properties = scheduleBuildRequest.properties.fields;
      for (var key in Config.defaultProperties.keys) {
        expect(properties.containsKey(key), true);
      }
      expect(scheduleBuildRequest.priority, LuciBuildService.kRerunPriority);
      expect(scheduleBuildRequest.gitilesCommit.project, 'mirrors/flutter');
      expect(
        scheduleBuildRequest.tags
            .firstWhere((tag) => tag.key == 'trigger_type')
            .value,
        'auto_retry',
      );
      expect(rerunFlag, isTrue);
      expect(task.attempts, 2);
      expect(task.status, Task.statusInProgress);
    });

    test('Rerun a test failed builder', () async {
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusFailed,
      );
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final task = generateTask(
        1,
        status: Task.statusFailed,
        parent: totCommit,
        buildNumber: 1,
      );
      final target = generateTarget(1);
      final rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: firestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isTrue);
    });

    test('Rerun an infra failed builder', () async {
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusInfraFailure,
      );
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: totCommit,
        buildNumber: 1,
      );
      final target = generateTarget(1);
      final rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: firestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isTrue);
    });

    test(
      'Skip rerun a failed test when task status update hit exception',
      () async {
        firestoreTask = generateFirestoreTask(
          1,
          attempts: 1,
          status: firestore.Task.statusInfraFailure,
        );

        // Insert the task attempt+1 ahead of time so that the insert fails.
        await firestoreService.insert(generateFirestoreTask(1, attempts: 2));

        firestoreCommit = generateFirestoreCommit(1);
        totCommit = generateCommit(1);
        config.db.values[totCommit.key] = totCommit;
        config.maxLuciTaskRetriesValue = 1;
        final task = generateTask(
          1,
          status: Task.statusFailed,
          parent: totCommit,
          buildNumber: 1,
        );
        final target = generateTarget(1);
        final rerunFlag = await service.checkRerunBuilder(
          commit: totCommit,
          task: task,
          target: target,
          datastore: datastore,
          firestoreService: firestoreService,
          taskDocument: firestoreTask!,
        );
        expect(rerunFlag, isFalse);
        expect(pubsub.messages.length, 0);
      },
    );

    test('Do not rerun a successful builder', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final task = generateTask(
        1,
        status: Task.statusSucceeded,
        parent: totCommit,
        buildNumber: 1,
      );
      final target = generateTarget(1);
      final rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: firestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isFalse);
    });

    test('Do not rerun a builder exceeding retry limit', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: totCommit,
        buildNumber: 1,
        attempts: 2,
      );
      final target = generateTarget(1);
      final rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: firestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isFalse);
    });

    test('Do not rerun a builder when not tip of tree', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1);
      totCommit = generateCommit(2, sha: 'def');
      commit = generateCommit(1, sha: 'abc');
      config.db.values[totCommit.key] = totCommit;
      config.db.values[commit.key] = commit;
      config.maxLuciTaskRetriesValue = 1;
      final task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: commit,
        buildNumber: 1,
      );
      final target = generateTarget(1);
      final rerunFlag = await service.checkRerunBuilder(
        commit: commit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: firestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isFalse);
    });

    test('insert retried task document to firestore', () async {
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusInfraFailure,
      );
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: totCommit,
        buildNumber: 1,
      );
      final target = generateTarget(1);
      expect(firestoreTask!.attempts, 1);
      final rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: firestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isTrue);
      expect(firestoreTask!.attempts, 2);

      final savedTask = firestore.Task.fromDocument(
        await firestoreService.api.getByPath(
          'tasks/${firestoreTask!.commitSha}_${firestoreTask!.taskName}_2',
        ),
      );
      expect(savedTask.status, firestore.Task.statusInProgress);
      expect(savedTask.attempts, 2);
    });
  });

  group('scheduleMergeGroupBuilds', () {
    late FakeFirestoreService firestoreService;
    firestore_commit.Commit? firestoreCommit;
    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      firestoreCommit = null;
      mockBuildBucketClient = MockBuildBucketClient();
      // ignore: discarded_futures
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 1',
              ),
            ),
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 2',
              ),
            ),
          ],
        );
      });

      when(
        // ignore: discarded_futures
        mockGithubChecksUtil.createCheckRun(
          any,
          any,
          any,
          any,
          output: anyNamed('output'),
        ),
      ).thenAnswer((realInvocation) async => generateCheckRun(1));

      firestoreService = FakeFirestoreService();
      when(
        // ignore: discarded_futures
        firestoreService.mock.batchWriteDocuments(captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      // ignore: discarded_futures
      when(firestoreService.mock.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<firestore_commit.Commit>.value(firestoreCommit);
      });
      when(
        // ignore: discarded_futures
        firestoreService.mock.queryRecentCommits(
          limit: captureAnyNamed('limit'),
          slug: captureAnyNamed('slug'),
          branch: captureAnyNamed('branch'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<firestore_commit.Commit>>.value(
          <firestore_commit.Commit>[firestoreCommit!],
        );
      });
      pubsub = FakePubSub();

      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
    });

    test('schedules prod builds for commit', () async {
      final commit = generateCommit(
        100,
        sha: 'abc1234',
        repo: 'flutter',
        branch: 'gh-readonly-queue/master/pr-1234-abcd',
      );
      final targets = <Target>[
        generateTarget(
          1,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
        generateTarget(
          2,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
      ];
      await service.scheduleMergeGroupBuilds(commit: commit, targets: targets);

      verify(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 1',
        ),
      ).called(1);
      verify(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 2',
        ),
      ).called(1);
      expect(pubsub.messages, hasLength(1));
      final batchRequest =
          bbv2.BatchRequest()..mergeFromProto3Json(pubsub.messages.first);
      expect(batchRequest.requests, hasLength(2));

      void validateSchedule(
        bbv2.ScheduleBuildRequest scheduleBuild,
        String builderName,
      ) {
        expect(scheduleBuild.builder.bucket, 'prod');
        expect(scheduleBuild.builder.builder, builderName);
        expect(
          scheduleBuild.notify.pubsubTopic,
          'projects/flutter-dashboard/topics/build-bucket-presubmit',
        );

        expect(
          scheduleBuild.tags,
          contains(bbv2.StringPair(key: 'in_merge_queue', value: 'true')),
        );

        final userData = PresubmitUserData.fromBytes(
          scheduleBuild.notify.userData,
        );
        expect(
          userData,
          PresubmitUserData(
            repoOwner: 'flutter',
            repoName: 'flutter',
            checkRunId: 1,
            commitSha: 'abc1234',
            commitBranch: 'gh-readonly-queue/master/pr-1234-abcd',
          ),
        );

        final properties = scheduleBuild.properties.fields;
        final dimensions = scheduleBuild.dimensions;

        expect(properties, <String, bbv2.Value>{
          'os': bbv2.Value(stringValue: 'abc'),
          'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
          'bringup': bbv2.Value(boolValue: false),
          'git_branch': bbv2.Value(
            stringValue: 'gh-readonly-queue/master/pr-1234-abcd',
          ),
          'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/master'),
          'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
          'is_fusion': bbv2.Value(stringValue: 'true'),
          'git_repo': bbv2.Value(stringValue: 'flutter'),
          'in_merge_queue': bbv2.Value(boolValue: true),
        });
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'os');
        expect(dimensions[0].value, 'abc');
      }

      validateSchedule(batchRequest.requests[0].scheduleBuild, 'Linux 1');
      validateSchedule(batchRequest.requests[1].scheduleBuild, 'Linux 2');
    });

    test('skips unmatched builders', () async {
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 1',
              ),
            ),
          ],
        );
      });
      final commit = generateCommit(
        100,
        sha: 'abc1234',
        repo: 'flutter',
        branch: 'gh-readonly-queue/master/pr-1234-abcd',
      );
      final targets = <Target>[
        generateTarget(
          1,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
        generateTarget(
          2,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
      ];
      await service.scheduleMergeGroupBuilds(commit: commit, targets: targets);

      verify(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 1',
        ),
      ).called(1);
      verifyNever(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 2',
        ),
      );
      expect(pubsub.messages, hasLength(1));
      final batchRequest =
          bbv2.BatchRequest()..mergeFromProto3Json(pubsub.messages.first);
      expect(batchRequest.requests, hasLength(1));
    });
  });
}
