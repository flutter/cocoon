// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/src/generated/google/protobuf/timestamp.pb.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';
import 'package:gcloud/pubsub.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_v2_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  late DartInternalSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late MockBuildBucketV2Client buildBucketClient;
  late SubscriptionV2Tester tester;
  late Commit commit;

  final DateTime startTime = DateTime(2023, 1, 1, 0, 0, 0);
  final DateTime endTime = DateTime(2023, 1, 1, 0, 14, 23);

  const String project = 'dart-internal';
  const String bucket = 'flutter';
  const String builder = 'Linux packaging_release_builder';
  const int buildNumber = 123456;
  final Int64 buildId = Int64(8766855135863637953);
  const String fakeHash = 'HASH12345';
  const String fakeBranch = 'test-branch';
  final bbv2.PubSubCallBack pubSubCallBack = bbv2.PubSubCallBack();
  final bbv2.BuildsV2PubSub buildsV2PubSub = bbv2.BuildsV2PubSub();
  const String fakePubsubMessage = '''
    {
      "buildPubsub": {
        "build": {
          "id": "$buildNumber",
          "builder": {
            "project": "$project",
            "bucket": "$bucket",
            "builder": "$builder"
          }
        }
      }
    }
  ''';

  setUp(() async {
    config = FakeConfig();
    buildBucketClient = MockBuildBucketV2Client();
    handler = DartInternalSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      buildBucketV2Client: buildBucketClient,
      datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
    );
    request = FakeHttpRequest();

    tester = SubscriptionV2Tester(
      request: request,
    );

    commit = generateCommit(
      1,
      sha: fakeHash,
      branch: fakeBranch,
      owner: 'flutter',
      repo: 'flutter',
      timestamp: 0,
    );

    final bbv2.Build fakeBuild = bbv2.Build();

    // Create the builder id for the fake build.
    final bbv2.BuilderID builderID = bbv2.BuilderID();
    builderID.project = project;
    builderID.bucket = bucket;
    builderID.builder = builder; 

    // Create the gitilescommit for the build input.
    final bbv2.GitilesCommit gitilesCommit = bbv2.GitilesCommit();
    gitilesCommit.project = 'flutter/flutter';
    gitilesCommit.id = fakeHash;
    gitilesCommit.ref = 'refs/heads/$fakeBranch';

    // Init the build input which is actually just the input.
    final bbv2.Build_Input input = bbv2.Build_Input();
    input.gitilesCommit = gitilesCommit;

    // Compile the build object with the required params.
    fakeBuild.builder = builderID;
    fakeBuild.input = input;
    fakeBuild.number = buildNumber;
    fakeBuild.id = buildId;
    fakeBuild.status = bbv2.Status.SUCCESS;
    final Timestamp buildStartTime = Timestamp.fromDateTime(startTime);
    fakeBuild.startTime = buildStartTime;
    final Timestamp buildEndTime = Timestamp.fromDateTime(endTime);
    fakeBuild.endTime = buildEndTime;

    buildsV2PubSub.build = fakeBuild;

    pubSubCallBack.buildPubsub = buildsV2PubSub;
    
    when(
      buildBucketClient.getBuild(
        any,
        buildBucketUri: 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds',
      ),
    ).thenAnswer((_) => Future<bbv2.Build>.value(fakeBuild));

    final List<Commit> datastoreCommit = <Commit>[commit];
    await config.db.commit(inserts: datastoreCommit);
  });

  test('creates a new task successfully', () async {
    // This needs to be written as JSON for some reason for it to be parsed successfully.
    tester.message = Message.withString(pubSubCallBack.writeToJson());

    await tester.post(handler);

    verify(
      buildBucketClient.getBuild(any),
    ).called(1);

    // This is used for testing to pull the data out of the "datastore" so that
    // we can verify what was saved.
    late Task taskInDb;
    late Commit commitInDb;
    config.db.values.forEach((k, v) {
      if (v is Task && v.buildNumberList == buildNumber.toString()) {
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
      buildNumber: buildNumber,
      buildNumberList: buildNumber.toString(),
      builderName: builder,
      commitKey: commitInDb.key,
      createTimestamp: startTime.millisecondsSinceEpoch,
      endTimestamp: endTime.millisecondsSinceEpoch,
      luciBucket: bucket,
      name: builder,
      stageName: 'dart-internal',
      startTimestamp: startTime.millisecondsSinceEpoch,
      status: 'Succeeded',
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
      name: builder,
      stageName: 'dart-internal',
      startTimestamp: startTime.millisecondsSinceEpoch,
      status: 'Succeeded',
      key: commit.key.append(Task),
      timeoutInMinutes: 0,
      reason: '',
      requiredCapabilities: [],
      reservedForAgentId: '',
    );
    final List<Task> datastoreCommit = <Task>[fakeTask];
    await config.db.commit(inserts: datastoreCommit);

    tester.message = Message.withString(fakePubsubMessage);

    await tester.post(handler);

    verify(
      buildBucketClient.getBuild(any),
    ).called(1);

    // This is used for testing to pull the data out of the "datastore" so that
    // we can verify what was saved.
    final String expectedBuilderList = '${existingTaskId.toString()},${buildNumber.toString()}';
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
      buildNumber: buildNumber,
      buildNumberList: expectedBuilderList,
      builderName: builder,
      commitKey: commitInDb.key,
      createTimestamp: startTime.millisecondsSinceEpoch,
      endTimestamp: endTime.millisecondsSinceEpoch,
      luciBucket: bucket,
      name: builder,
      stageName: 'dart-internal',
      startTimestamp: startTime.millisecondsSinceEpoch,
      status: 'Succeeded',
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

  // test('ignores null message', () async {
  //   tester.message = Message.withString(null);
  //   expect(await tester.post(handler), equals(Body.empty));
  // });

  test('ignores message with empty build data', () async {
    tester.message = Message.withString('{}');
    expect(await tester.post(handler), equals(Body.empty));
  });

  test('ignores message not from flutter bucket', () async {
   tester.message = Message.withString(
    '''
    {
      "build": {
        "id": "$buildNumber",
        "builder": {
          "project": "$project",
          "bucket": "dart",
          "builder": "$builder"
        }
      }
    }
    ''',
    );
    expect(await tester.post(handler), equals(Body.empty));
  });

  test('ignores message not from dart-internal project', () async {
    tester.message = Message.withString(
    '''
    {
      "build": {
        "id": "$buildNumber",
        "builder": {
          "project": "different-project",
          "bucket": "$bucket",
          "builder": "$builder"
        }
      }
    }
    ''',
    );
    expect(await tester.post(handler), equals(Body.empty));
  });

  test('ignores message not from an accepted builder', () async {
    tester.message = Message.withString(
    '''
    {
      "build": {
        "id": "$buildNumber",
        "builder": {
          "project": "different-project",
          "bucket": "$bucket",
          "builder": "different-builder"
        }
      }
    }
    ''',
    );
    expect(await tester.post(handler), equals(Body.empty));
  });
}
