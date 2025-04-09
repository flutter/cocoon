// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:cocoon_service/src/service/build_bucket_client.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/exceptions.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/opaque_commit.dart';
import 'package:cocoon_service/src/service/luci_build_service/pending_task.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/datastore/fake_datastore.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';
import '../../src/utilities/webhook_generators.dart';

/// Tests [LuciBuildService] public API related to fetching prod-bot builds.
///
/// Specifically:
/// - [LuciBuildService.schedulePostsubmitBuilds]
/// - [LuciBuildService.reschedulePostsubmitBuildUsingCheckRunEvent]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;
  late FakePubSub pubSub;
  late FakeDatastoreDB datastoreDB;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    datastoreDB = FakeDatastoreDB();
    pubSub = FakePubSub();

    luci = LuciBuildService(
      cache: CacheService(inMemory: true),
      config: FakeConfig(
        firestoreService: firestoreService,
        dbValue: datastoreDB,
      ),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
      pubsub: pubSub,
    );
  });

  test('schedules a post-submit build outside of flutter/flutter', () async {
    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        Config.packagesSlug,
        any,
        'Linux 1',
      ),
    ).thenAnswer((_) async => generateCheckRun(1));

    final commit = generateCommit(1, branch: 'main', repo: 'packages');

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

    await expectLater(
      luci.schedulePostsubmitBuilds(
        commit: OpaqueCommit.fromDatastore(commit),
        toBeScheduled: [
          PendingTask(
            target: generateTarget(
              1,
              properties: {
                'recipe': 'devicelab/devicelab',
                'os': 'debian-10.12',
              },
              slug: Config.packagesSlug,
            ),
            task: generateTask(1, parent: commit),
            priority: LuciBuildService.kDefaultPriority,
          ),
        ],
      ),
      completion(isEmpty),
    );

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }

    expect(
      scheduleBuild.builder,
      isA<bbv2.BuilderID>()
          .having((b) => b.bucket, 'bucket', 'prod')
          .having((b) => b.builder, 'builder', 'Linux 1'),
    );

    expect(
      scheduleBuild.notify.pubsubTopic,
      'projects/flutter-dashboard/topics/build-bucket-postsubmit',
    );

    expect(
      PostsubmitUserData.fromBytes(scheduleBuild.notify.userData),
      PostsubmitUserData(
        commitKey: 'flutter/packages/main/1',
        taskKey: '1',
        firestoreTaskDocumentName: fs.TaskId.parse('1_task1_1'),
        checkRunId: 1,
      ),
    );

    expect(scheduleBuild.properties.fields, {
      'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
      'bringup': bbv2.Value(boolValue: false),
      'git_branch': bbv2.Value(stringValue: 'main'),
      'git_repo': bbv2.Value(stringValue: 'packages'),
      'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
      'os': bbv2.Value(stringValue: 'debian-10.12'),
      'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
    });

    expect(scheduleBuild.dimensions, [
      isA<bbv2.RequestedDimension>()
          .having((d) => d.key, 'key', 'os')
          .having((d) => d.value, 'value', 'debian-10.12'),
    ]);
  });

  test('does not create a postsubmit checkrun when bringup: true', () async {
    final commit = generateCommit(1, branch: 'main', repo: 'packages');

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

    await expectLater(
      luci.schedulePostsubmitBuilds(
        commit: OpaqueCommit.fromDatastore(commit),
        toBeScheduled: [
          PendingTask(
            target: generateTarget(
              1,
              properties: {
                'recipe': 'devicelab/devicelab',
                'os': 'debian-10.12',
              },
              slug: Config.packagesSlug,
              bringup: true,
            ),
            task: generateTask(1, parent: commit),
            priority: LuciBuildService.kDefaultPriority,
          ),
        ],
      ),
      completion(isEmpty),
    );

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }

    expect(
      scheduleBuild.builder,
      isA<bbv2.BuilderID>()
          .having((b) => b.bucket, 'bucket', 'staging')
          .having((b) => b.builder, 'builder', 'Linux 1'),
    );

    expect(
      scheduleBuild.notify.pubsubTopic,
      'projects/flutter-dashboard/topics/build-bucket-postsubmit',
    );

    expect(
      PostsubmitUserData.fromBytes(scheduleBuild.notify.userData),
      PostsubmitUserData(
        commitKey: 'flutter/packages/main/1',
        taskKey: '1',
        firestoreTaskDocumentName: fs.TaskId.parse('1_task1_1'),
        checkRunId: null /* Bringup */,
      ),
    );

    expect(scheduleBuild.properties.fields, {
      'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
      'bringup': bbv2.Value(boolValue: true),
      'git_branch': bbv2.Value(stringValue: 'main'),
      'git_repo': bbv2.Value(stringValue: 'packages'),
      'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
      'os': bbv2.Value(stringValue: 'debian-10.12'),
      'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
    });

    expect(scheduleBuild.dimensions, [
      isA<bbv2.RequestedDimension>()
          .having((d) => d.key, 'key', 'os')
          .having((d) => d.value, 'value', 'debian-10.12'),
    ]);

    verifyNever(
      mockGithubChecksUtil.createCheckRun(
        any,
        Config.packagesSlug,
        any,
        'Linux 1',
      ),
    );
  });

  test('schedules a post-submit build inside of flutter/flutter', () async {
    final commit = generateCommit(1, branch: 'main', repo: 'flutter');

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

    await expectLater(
      luci.schedulePostsubmitBuilds(
        commit: OpaqueCommit.fromDatastore(commit),
        toBeScheduled: [
          PendingTask(
            target: generateTarget(
              1,
              properties: {
                'recipe': 'devicelab/devicelab',
                'os': 'debian-10.12',
              },
              slug: Config.flutterSlug,
            ),
            task: generateTask(1, parent: commit),
            priority: LuciBuildService.kDefaultPriority,
          ),
        ],
      ),
      completion(isEmpty),
    );

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }

    expect(
      scheduleBuild.builder,
      isA<bbv2.BuilderID>()
          .having((b) => b.bucket, 'bucket', 'prod')
          .having((b) => b.builder, 'builder', 'Linux 1'),
    );

    expect(
      scheduleBuild.notify.pubsubTopic,
      'projects/flutter-dashboard/topics/build-bucket-postsubmit',
    );

    expect(
      PostsubmitUserData.fromBytes(scheduleBuild.notify.userData),
      PostsubmitUserData(
        commitKey: 'flutter/flutter/main/1',
        taskKey: '1',
        firestoreTaskDocumentName: fs.TaskId.parse('1_task1_1'),
        checkRunId: null /* Uses batch backfiller */,
      ),
    );

    expect(scheduleBuild.properties.fields, {
      'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
      'bringup': bbv2.Value(boolValue: false),
      'git_branch': bbv2.Value(stringValue: 'main'),
      'git_repo': bbv2.Value(stringValue: 'flutter'),
      'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
      'os': bbv2.Value(stringValue: 'debian-10.12'),
      'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
      'is_fusion': bbv2.Value(stringValue: 'true'),
    });

    expect(scheduleBuild.dimensions, [
      isA<bbv2.RequestedDimension>()
          .having((d) => d.key, 'key', 'os')
          .having((d) => d.value, 'value', 'debian-10.12'),
    ]);

    verifyNever(
      mockGithubChecksUtil.createCheckRun(
        any,
        Config.packagesSlug,
        any,
        'Linux 1',
      ),
    );
  });

  test('does not run a non-existent builder', () async {
    final commit = generateCommit(1, branch: 'main', repo: 'flutter');

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

    await expectLater(
      luci.schedulePostsubmitBuilds(
        commit: OpaqueCommit.fromDatastore(commit),
        toBeScheduled: [
          PendingTask(
            target: generateTarget(
              1,
              properties: {
                'recipe': 'devicelab/devicelab',
                'os': 'debian-10.12',
              },
              slug: Config.flutterSlug,
            ),
            task: generateTask(1, parent: commit),
            priority: LuciBuildService.kDefaultPriority,
          ),
        ],
      ),
      completion(isEmpty),
    );

    final batchRequest = bbv2.BatchRequest().createEmptyInstance();
    batchRequest.mergeFromProto3Json(pubSub.messages.single);
    expect(batchRequest.requests, isEmpty);

    verifyNever(
      mockGithubChecksUtil.createCheckRun(
        any,
        Config.packagesSlug,
        any,
        'Linux 1',
      ),
    );
  });

  test('return the orignal list when hitting buildbucket exception', () async {
    final commit = generateCommit(0, repo: 'packages');
    when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
      throw const BuildBucketException(1, 'error');
    });

    final toBeScheduled = PendingTask(
      target: generateTarget(
        1,
        properties: <String, String>{'os': 'debian-10.12'},
        slug: Config.packagesSlug,
      ),
      task: generateTask(1),
      priority: LuciBuildService.kDefaultPriority,
    );
    await expectLater(
      luci.schedulePostsubmitBuilds(
        commit: OpaqueCommit.fromDatastore(commit),
        toBeScheduled: [toBeScheduled],
      ),
      completion([toBeScheduled]),
    );
  });

  group('reschedulePostsubmitBuildUsingCheckRunEvent', () {
    late DatastoreService datastoreService;

    setUp(() {
      datastoreService = DatastoreService(datastoreDB, 5);
    });

    test('reschedules', () async {
      when(
        mockGithubChecksUtil.createCheckRun(any, any, any, any),
      ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: [
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: [
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

      final CheckRunEvent checkRunEvent;
      {
        final pushMessage = generateCheckRunEvent(
          action: 'created',
          numberOfPullRequests: 1,
        );
        final jsonMap = json.decode(pushMessage.data!) as Map<String, Object?>;
        checkRunEvent = CheckRunEvent.fromJson(
          json.decode(jsonMap['2'] as String) as Map<String, Object?>,
        );
      }

      final dsCommit = generateCommit(0);
      final fsTask = generateFirestoreTask(0, commitSha: dsCommit.sha);
      firestoreService.putDocument(fsTask);

      await luci.reschedulePostsubmitBuildUsingCheckRunEvent(
        checkRunEvent,
        commit: OpaqueCommit.fromDatastore(dsCommit),
        task: generateTask(0, parent: dsCommit),
        target: generateTarget(0),
        taskDocument: fsTask,
        datastore: datastoreService,
        firestoreService: firestoreService,
      );

      expect(
        firestoreService,
        existsInStorage(fs.Task.metadata, [
          isTask.hasCurrentAttempt(1),
          isTask.hasCurrentAttempt(2),
        ]),
      );

      expect(pubSub.messages, hasLength(1));
    });

    test('fails gracefully when an exception is thrown', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse();
      });

      final CheckRunEvent checkRunEvent;
      {
        final pushMessage = generateCheckRunEvent(
          action: 'created',
          numberOfPullRequests: 1,
        );
        final jsonMap = json.decode(pushMessage.data!) as Map<String, Object?>;
        checkRunEvent = CheckRunEvent.fromJson(
          json.decode(jsonMap['2'] as String) as Map<String, Object?>,
        );
      }

      await expectLater(
        luci.reschedulePostsubmitBuildUsingCheckRunEvent(
          checkRunEvent,
          commit: OpaqueCommit.fromDatastore(generateCommit(0)),
          task: generateTask(0),
          target: generateTarget(0),
          taskDocument: generateFirestoreTask(0),
          datastore: datastoreService,
          firestoreService: firestoreService,
        ),
        throwsA(isA<NoBuildFoundException>()),
      );
    });
  });
}
