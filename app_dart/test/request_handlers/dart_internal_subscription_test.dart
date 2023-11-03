// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/src/generated/google/protobuf/timestamp.pb.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/model/luci/pubsub_message_v2.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_v2_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {

  final DateTime startTime = DateTime(2023, 11, 03, 20, 25, 0, 518383633);
  final DateTime endTime = DateTime(2023, 11, 03, 20, 25, 0, 518383633);

  // Omit the timestamps for expect purposes.
  const String message = '''
{
  "buildPubsub":{
    "build":{
      "id":8766855135863637953,
      "builder":{
        "project":"dart-internal",
        "bucket":"flutter",
        "builder":"Linux packaging_release_builder"
      },
      "number":123456,
      "status":"SUCCESS",
      "input":{
        "gitilesCommit":{
          "project":"flutter/flutter",
          "id":"HASH12345",
          "ref":"refs/heads/test-branch"
        }
      }
    }
  }
}
''';

  late DartInternalSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late MockBuildBucketV2Client buildBucketClient;
  late SubscriptionV2Tester tester;
  late Commit commit;

  // ignore: unused_local_variable
  const String project = 'dart-internal';
  const String bucket = 'flutter';
  const String builder = 'Linux packaging_release_builder';
  const int buildNumber = 123456;
  // ignore: unused_local_variable
  final Int64 buildId = Int64(8766855135863637953);
  const String fakeHash = 'HASH12345';
  const String fakeBranch = 'test-branch';

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

    final bbv2.PubSubCallBack pubSubCallBackTest = bbv2.PubSubCallBack();
    pubSubCallBackTest.mergeFromProto3Json(jsonDecode(message));

    const PushMessageV2 pushMessageV2 = PushMessageV2(data: message, messageId: '798274983');
    tester.message = pushMessageV2;

    when(
      buildBucketClient.getBuild(
        any,
        buildBucketUri: 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds',
      ),
    ).thenAnswer((_) => Future<bbv2.Build>.value(pubSubCallBackTest.buildPubsub.build));

    final List<Commit> datastoreCommit = <Commit>[commit];
    await config.db.commit(inserts: datastoreCommit);
  });

  test('creates a new task successfully', () async {
    // This needs to be written as JSON for some reason for it to be parsed successfully.
    final bbv2.PubSubCallBack pubSubCallBackTest = bbv2.PubSubCallBack();
    pubSubCallBackTest.mergeFromProto3Json(jsonDecode(message));
    
    const PushMessageV2 pushMessageV2 = PushMessageV2(data: message, messageId: '798274983');
    tester.message = pushMessageV2;

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
      luciBucket: bucket,
      name: builder,
      stageName: 'dart-internal',
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
      luciBucket: bucket,
      name: builder,
      stageName: 'dart-internal',
      status: 'Succeeded',
      key: commit.key.append(Task),
      timeoutInMinutes: 0,
      reason: '',
      requiredCapabilities: [],
      reservedForAgentId: '',
    );
    final List<Task> datastoreCommit = <Task>[fakeTask];
    await config.db.commit(inserts: datastoreCommit);

     final bbv2.PubSubCallBack pubSubCallBackTest = bbv2.PubSubCallBack();
    pubSubCallBackTest.mergeFromProto3Json(jsonDecode(message));
    
    const PushMessageV2 pushMessageV2 = PushMessageV2(data: message, messageId: '798274983');
    tester.message = pushMessageV2;

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
      luciBucket: bucket,
      name: builder,
      stageName: 'dart-internal',
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

  test('ignores message with empty build data', () async {
    tester.message = const PushMessageV2();
    expect(await tester.post(handler), equals(Body.empty));
  });

  // // TODO create a construction method for this to simplify testing.
  test('ignores message not from flutter bucket', () async {
    const String dartMessage = '''
{
  "buildPubsub":{
    "build":{
      "id":8766855135863637953,
      "builder":{
        "project":"dart-internal",
        "bucket":"dart",
        "builder":"Linux packaging_release_builder"
      },
      "number":123456,
      "status":"SUCCESS",
      "input":{
        "gitilesCommit":{
          "project":"flutter/flutter",
          "id":"HASH12345",
          "ref":"refs/heads/test-branch"
        }
      }
    }
  }
}
''';

    final bbv2.PubSubCallBack pubSubCallBackTest = bbv2.PubSubCallBack();
    pubSubCallBackTest.mergeFromProto3Json(jsonDecode(dartMessage));
    
    const PushMessageV2 pushMessageV2 = PushMessageV2(data: dartMessage, messageId: '798274983');
    tester.message = pushMessageV2;
    expect(await tester.post(handler), equals(Body.empty));
  });

  test('ignores message not from dart-internal project', () async {
     const String unsupportedProjectMessage = '''
{
  "buildPubsub":{
    "build":{
      "id":8766855135863637953,
      "builder":{
        "project":"unsupported-project",
        "bucket":"dart",
        "builder":"Linux packaging_release_builder"
      },
      "number":123456,
      "status":"SUCCESS",
      "input":{
        "gitilesCommit":{
          "project":"flutter/flutter",
          "id":"HASH12345",
          "ref":"refs/heads/test-branch"
        }
      }
    }
  }
}
''';

    final bbv2.PubSubCallBack pubSubCallBackTest = bbv2.PubSubCallBack();
    pubSubCallBackTest.mergeFromProto3Json(jsonDecode(unsupportedProjectMessage));
    
    const PushMessageV2 pushMessageV2 = PushMessageV2(data: unsupportedProjectMessage, messageId: '798274983');
    tester.message = pushMessageV2;
    expect(await tester.post(handler), equals(Body.empty));
  });

  test('ignores message not from an accepted builder', () async {
    const String unknownBuilderMessage = '''
{
  "buildPubsub":{
    "build":{
      "id":8766855135863637953,
      "builder":{
        "project":"dart-internal",
        "bucket":"dart",
        "builder":"different builder"
      },
      "number":123456,
      "status":"SUCCESS",
      "input":{
        "gitilesCommit":{
          "project":"flutter/flutter",
          "id":"HASH12345",
          "ref":"refs/heads/test-branch"
        }
      }
    }
  }
}
''';

    final bbv2.PubSubCallBack pubSubCallBackTest = bbv2.PubSubCallBack();
    pubSubCallBackTest.mergeFromProto3Json(jsonDecode(unknownBuilderMessage));
    
    const PushMessageV2 pushMessageV2 = PushMessageV2(data: unknownBuilderMessage, messageId: '798274983');
    tester.message = pushMessageV2;
    expect(await tester.post(handler), equals(Body.empty));
  });
}

bbv2.PubSubCallBack _constructPubSubCallBack({
  String? project,
  String? bucket,
  String? builder,
  String? gitilesCommitProject,
  String? gitilesHash,
  String? gitilesRef,
  int? buildNumber,
  Int64? buildId,
  bbv2.Status? buildStatus,
  DateTime? createTime,
  DateTime? startTime,
  DateTime? endTime,
}) {
  project = project ?? 'dart-internal';
  bucket = bucket ?? 'flutter';
  builder = builder ?? 'Linux packaging_release_builder';
  gitilesCommitProject = gitilesCommitProject ?? 'flutter/flutter';
  gitilesHash = gitilesHash ?? 'HASH12345';
  gitilesRef = gitilesRef ?? 'refs/heads/test-branch';
  buildNumber = buildNumber ?? 123456;
  buildId = buildId ?? Int64(8766855135863637953);
  buildStatus = buildStatus ?? bbv2.Status.SUCCESS;
  createTime = createTime ?? DateTime(2023, 1, 1, 0, 0, 0);
  startTime = startTime ?? DateTime(2023, 1, 1, 0, 0, 0);
  endTime = endTime ?? DateTime(2023, 1, 1, 0, 14, 23);

  final bbv2.Build fakeBuild = bbv2.Build();

  // Create the builder id for the fake build.
  final bbv2.BuilderID builderID = bbv2.BuilderID();
  builderID.project = project;
  builderID.bucket = bucket;
  builderID.builder = builder;

  // Create the gitilescommit for the build input.
  final bbv2.GitilesCommit gitilesCommit = bbv2.GitilesCommit();
  gitilesCommit.project = gitilesCommitProject;
  gitilesCommit.id = gitilesHash;
  gitilesCommit.ref = gitilesRef;

  // Init the build input which is actually just the input.
  final bbv2.Build_Input input = bbv2.Build_Input();
  input.gitilesCommit = gitilesCommit;

  // Compile the build object with the required params.
  fakeBuild.builder = builderID;
  fakeBuild.input = input;
  fakeBuild.number = buildNumber;
  fakeBuild.id = buildId;
  fakeBuild.status = buildStatus;
  final Timestamp buildCreateTime = Timestamp.fromDateTime(createTime);
  fakeBuild.createTime = buildCreateTime;
  final Timestamp buildStartTime = Timestamp.fromDateTime(startTime);
  fakeBuild.startTime = buildStartTime;
  final Timestamp buildEndTime = Timestamp.fromDateTime(endTime);
  fakeBuild.endTime = buildEndTime;

  final bbv2.PubSubCallBack pubSubCallBack = bbv2.PubSubCallBack();
  final bbv2.BuildsV2PubSub buildsV2PubSub = bbv2.BuildsV2PubSub();

  buildsV2PubSub.build = fakeBuild;

  pubSubCallBack.buildPubsub = buildsV2PubSub;

  return pubSubCallBack;
}
