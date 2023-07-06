// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as push;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  late DartInternalSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late MockBuildBucketClient buildBucketClient;
  late SubscriptionTester tester;
  late Commit commit;
  final DateTime startTime = DateTime(2023, 1, 1, 0, 0, 0);
  final DateTime endTime = DateTime(2023, 1, 1, 0, 14, 23);
  const String project = "dart-internal";
  const String bucket = "flutter";
  const String builder = "Mac amazing_builder_tests";
  const String propertiesBuildName = "Mac Unit_Test";
  const int buildId = 123456;
  const String fakeHash = "HASH12345";
  const String fakeBranch = "test-branch";
  final String fakePubsubMessage = "{ \"buildbucket_id\": ${buildId.toString()} }";

  setUp(() async {
    config = FakeConfig();
    buildBucketClient = MockBuildBucketClient();
    handler = DartInternalSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      buildBucketClient: buildBucketClient,
      datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      retryOptions: const RetryOptions(maxAttempts: 3, delayFactor: Duration.zero),
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(
      request: request,
    );

    commit = generateCommit(
      1,
      sha: fakeHash,
      branch: fakeBranch,
      owner: "flutter",
      repo: "flutter",
      timestamp: 0,
    );

    final Build fakeBuild = Build(
      builderId: const BuilderId(project: project, bucket: bucket, builder: builder),
      number: buildId,
      id: 'fake-build-id',
      status: Status.success,
      startTime: startTime,
      endTime: endTime,
      input: const Input(
        gitilesCommit: GitilesCommit(
          project: "flutter/flutter",
          hash: fakeHash,
          ref: "refs/heads/$fakeBranch",
        ),
        properties: <String, Object>{
          'build': <String, String>{'name': propertiesBuildName},
        },
      ),
    );
    when(
      buildBucketClient.getBuild(
        any,
        buildBucketUri: "https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds",
      ),
    ).thenAnswer((_) => Future<Build>.value(fakeBuild));

    final List<Commit> datastoreCommit = <Commit>[commit];
    await config.db.commit(inserts: datastoreCommit);
  });

  test('creates a new task successfully', () async {
    tester.message = push.PushMessage(data: fakePubsubMessage);

    await tester.post(handler);

    verify(
      buildBucketClient.getBuild(any),
    ).called(1);

    // This is used for testing to pull the data out of the "datastore" so that
    // we can verify what was saved.
    late Task taskInDb;
    late Commit commitInDb;
    config.db.values.forEach((k, v) {
      if (v is Task && v.buildNumberList == buildId.toString()) {
        taskInDb = v;
      }
      if (v is Commit) {
        commitInDb = v;
      }
    });

    // Ensure the task has the correct parent and commit key
    expect(
      commitInDb.id,
      equals(taskInDb.commitKey?.id),
    );

    expect(
      commitInDb.id,
      equals(taskInDb.parentKey?.id),
    );

    // Ensure the task in the db is exactly what we expect
    final Task expectedTask = Task(
      attempts: 1,
      buildNumber: buildId,
      buildNumberList: buildId.toString(),
      builderName: builder,
      commitKey: commitInDb.key,
      createTimestamp: startTime.millisecondsSinceEpoch,
      endTimestamp: endTime.millisecondsSinceEpoch,
      luciBucket: bucket,
      name: propertiesBuildName,
      stageName: "dart-internal",
      startTimestamp: startTime.millisecondsSinceEpoch,
      status: "Succeeded",
      key: commit.key.append(Task),
      timeoutInMinutes: 0,
      reason: '',
      requiredCapabilities: [],
      reservedForAgentId: '',
    );

    expect(
      taskInDb.toString(),
      equals(expectedTask.toString()),
    );
  });

  test('updates an existing task successfully', () async {
    const int existingTaskId = 123;
    final Task fakeTask = Task(
      attempts: 1,
      buildNumber: existingTaskId,
      buildNumberList: existingTaskId.toString(),
      builderName: builder,
      commitKey: commit.key,
      createTimestamp: startTime.millisecondsSinceEpoch,
      endTimestamp: endTime.millisecondsSinceEpoch,
      luciBucket: bucket,
      name: propertiesBuildName,
      stageName: "dart-internal",
      startTimestamp: startTime.millisecondsSinceEpoch,
      status: "Succeeded",
      key: commit.key.append(Task),
      timeoutInMinutes: 0,
      reason: '',
      requiredCapabilities: [],
      reservedForAgentId: '',
    );
    final List<Task> datastoreCommit = <Task>[fakeTask];
    await config.db.commit(inserts: datastoreCommit);

    tester.message = push.PushMessage(data: fakePubsubMessage);

    await tester.post(handler);

    verify(
      buildBucketClient.getBuild(any),
    ).called(1);

    // This is used for testing to pull the data out of the "datastore" so that
    // we can verify what was saved.
    final String expectedBuilderList = "${existingTaskId.toString()},${buildId.toString()}";
    late Task taskInDb;
    late Commit commitInDb;
    config.db.values.forEach((k, v) {
      if (v is Task && v.buildNumberList == expectedBuilderList) {
        taskInDb = v;
      }
      if (v is Commit) {
        commitInDb = v;
      }
    });

    // Ensure the task has the correct parent and commit key
    expect(
      commitInDb.id,
      equals(taskInDb.commitKey?.id),
    );

    expect(
      commitInDb.id,
      equals(taskInDb.parentKey?.id),
    );

    // Ensure the task in the db is exactly what we expect
    final Task expectedTask = Task(
      attempts: 2,
      buildNumber: buildId,
      buildNumberList: expectedBuilderList,
      builderName: builder,
      commitKey: commitInDb.key,
      createTimestamp: startTime.millisecondsSinceEpoch,
      endTimestamp: endTime.millisecondsSinceEpoch,
      luciBucket: bucket,
      name: propertiesBuildName,
      stageName: "dart-internal",
      startTimestamp: startTime.millisecondsSinceEpoch,
      status: "Succeeded",
      key: commit.key.append(Task),
      timeoutInMinutes: 0,
      reason: '',
      requiredCapabilities: [],
      reservedForAgentId: '',
    );

    expect(
      taskInDb.toString(),
      equals(expectedTask.toString()),
    );
  });

  test('retries buildbucket when build is still in progress', () async {
    final Build fakeCompletedBuild = Build(
      builderId: const BuilderId(project: project, bucket: bucket, builder: builder),
      number: buildId,
      id: 'fake-build-id',
      status: Status.success,
      startTime: startTime,
      endTime: endTime,
      input: const Input(
        gitilesCommit: GitilesCommit(
          project: "flutter/flutter",
          hash: fakeHash,
          ref: "refs/heads/$fakeBranch",
        ),
      ),
    );

    final Build fakeInProgressBuild = Build(
      builderId: const BuilderId(project: project, bucket: bucket, builder: builder),
      number: buildId,
      id: 'fake-build-id',
      status: Status.started,
      startTime: startTime,
      endTime: null,
      input: const Input(
        gitilesCommit: GitilesCommit(
          project: "flutter/flutter",
          hash: fakeHash,
          ref: "refs/heads/$fakeBranch",
        ),
      ),
    );

    // The first time the mocked getBuild is called, return fakeInProgressBuild,
    // then return fakeCompletedBuild the second time.
    int count = 0;
    when(
      buildBucketClient.getBuild(
        any,
        buildBucketUri: "https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds",
      ),
    ).thenAnswer(
      (_) => [Future<Build>.value(fakeInProgressBuild), Future<Build>.value(fakeCompletedBuild)][count++],
    );

    tester.message = push.PushMessage(data: fakePubsubMessage);

    await tester.post(handler);

    verify(
      buildBucketClient.getBuild(any),
    ).called(2);

    // This is used for testing to pull the data out of the "datastore" so that
    // we can verify what was saved.
    late Task taskInDb;
    late Commit commitInDb;
    config.db.values.forEach((k, v) {
      if (v is Task && v.buildNumberList == buildId.toString()) {
        taskInDb = v;
      }
      if (v is Commit) {
        commitInDb = v;
      }
    });

    // Ensure the task has the correct parent and commit key
    expect(
      commitInDb.id,
      equals(taskInDb.commitKey?.id),
    );

    expect(
      commitInDb.id,
      equals(taskInDb.parentKey?.id),
    );

    // Ensure the task in the db is exactly what we expect
    final Task expectedTask = Task(
      attempts: 1,
      buildNumber: buildId,
      buildNumberList: buildId.toString(),
      builderName: builder,
      commitKey: commitInDb.key,
      createTimestamp: startTime.millisecondsSinceEpoch,
      endTimestamp: endTime.millisecondsSinceEpoch,
      luciBucket: bucket,
      name: builder,
      stageName: "dart-internal",
      startTimestamp: startTime.millisecondsSinceEpoch,
      status: "Succeeded",
      key: commit.key.append(Task),
      timeoutInMinutes: 0,
      reason: '',
      requiredCapabilities: [],
      reservedForAgentId: '',
    );

    expect(
      taskInDb.toString(),
      equals(expectedTask.toString()),
    );
  });

  test('does not retry buildbucket when buildbucket throws an exception', () async {
    when(
      await buildBucketClient.getBuild(
        any,
        buildBucketUri: "https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds",
      ),
    ).thenThrow(
      Exception("Failed to get from buildbucket for some reason!"),
    );

    tester.message = push.PushMessage(data: fakePubsubMessage);
    await expectLater(
      tester.post(handler),
      throwsA(isA<Exception>()),
    );

    verify(
      buildBucketClient.getBuild(any),
    ).called(1);
  });
}
