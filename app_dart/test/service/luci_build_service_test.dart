// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart'
    as firestore_commit;
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci_build_service/opaque_commit.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:gcloud/datastore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late CacheService cache;
  late FakeConfig config;
  late MockBuildBucketClient mockBuildBucketClient;
  late LuciBuildService service;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakePubSub pubsub;

  setUp(() {
    mockGithubChecksUtil = MockGithubChecksUtil();
  });

  group('checkRerunBuilder', () {
    late Commit commit;
    late Commit totCommit;
    late DatastoreService datastore;
    late MockFirestoreService mockFirestoreService;
    firestore.Task? firestoreTask;
    firestore_commit.Commit? firestoreCommit;
    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      firestoreTask = null;
      firestoreCommit = null;
      mockFirestoreService = MockFirestoreService();
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
        mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      // ignore: discarded_futures
      when(mockFirestoreService.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<firestore_commit.Commit>.value(firestoreCommit);
      });
      when(
        // ignore: discarded_futures
        mockFirestoreService.queryRecentCommits(
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
        commit: OpaqueCommit.fromDatastore(totCommit),
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
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
        commit: OpaqueCommit.fromDatastore(totCommit),
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
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
        commit: OpaqueCommit.fromDatastore(totCommit),
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
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
        when(
          mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
        ).thenAnswer((Invocation invocation) {
          throw InternalError();
        });
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
          commit: OpaqueCommit.fromDatastore(totCommit),
          task: task,
          target: target,
          datastore: datastore,
          firestoreService: mockFirestoreService,
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
        commit: OpaqueCommit.fromDatastore(totCommit),
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
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
        commit: OpaqueCommit.fromDatastore(totCommit),
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
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
        commit: OpaqueCommit.fromDatastore(commit),
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
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
      expect(firestoreTask!.currentAttempt, 1);
      final rerunFlag = await service.checkRerunBuilder(
        commit: OpaqueCommit.fromDatastore(totCommit),
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isTrue);

      expect(firestoreTask!.currentAttempt, 2);
      final captured =
          verify(
            mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
          ).captured;
      expect(captured.length, 2);
      final batchWriteRequest = captured[0] as BatchWriteRequest;
      expect(batchWriteRequest.writes!.length, 1);
      final insertedTaskDocument = batchWriteRequest.writes![0].update!;
      expect(insertedTaskDocument, firestoreTask);
      expect(firestoreTask!.status, firestore.Task.statusInProgress);
    });
  });

  group('scheduleMergeGroupBuilds', () {
    late MockFirestoreService mockFirestoreService;
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

      mockFirestoreService = MockFirestoreService();
      when(
        // ignore: discarded_futures
        mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      // ignore: discarded_futures
      when(mockFirestoreService.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<firestore_commit.Commit>.value(firestoreCommit);
      });
      when(
        // ignore: discarded_futures
        mockFirestoreService.queryRecentCommits(
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
