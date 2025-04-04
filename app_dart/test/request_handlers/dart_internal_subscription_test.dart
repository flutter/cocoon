// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  // Omit the timestamps for expect purposes.
  const buildJson = '''
{
  "id": "8766855135863637953",
  "builder": {
    "project": "dart-internal",
    "bucket": "flutter",
    "builder": "Linux packaging_release_builder"
  },
  "number": 123456,
  "status": "SUCCESS",
  "input": {
    "gitilesCommit": {
      "project": "flutter/flutter",
      "id": "HASH12345",
      "ref": "refs/heads/test-branch"
    }
  }
}
''';

  const buildMessageJson = '''
{
  "build": {
    "id": "8766855135863637953",
    "builder": {
      "project": "dart-internal",
      "bucket": "flutter",
      "builder": "Linux packaging_release_builder"
    },
    "number": 123456,
    "status": "SUCCESS",
    "input": {
      "gitilesCommit": {
        "project": "flutter/flutter",
        "id": "HASH12345",
        "ref": "refs/heads/test-branch"
      }
    }
  }
}
''';

  late DartInternalSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late MockBuildBucketClient buildBucketClient;
  late SubscriptionTester tester;
  late MockFirestoreService mockFirestoreService;
  late Commit commit;

  // ignore: unused_local_variable
  const project = 'dart-internal';
  const bucket = 'flutter';
  const builder = 'Linux packaging_release_builder';
  const buildNumber = 123456;
  // ignore: unused_local_variable
  final buildId = Int64(8766855135863637953);
  const fakeHash = 'HASH12345';
  const fakeBranch = 'test-branch';

  setUp(() async {
    mockFirestoreService = MockFirestoreService();
    config = FakeConfig(firestoreService: mockFirestoreService);
    buildBucketClient = MockBuildBucketClient();
    handler = DartInternalSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(request: request);

    commit = generateCommit(
      1,
      sha: fakeHash,
      branch: fakeBranch,
      owner: 'flutter',
      repo: 'flutter',
      timestamp: 0,
    );

    // final bbv2.PubSubCallBack pubSubCallBackTest = bbv2.PubSubCallBack();
    // pubSubCallBackTest.mergeFromProto3Json(jsonDecode(message));
    final build = bbv2.Build().createEmptyInstance();
    build.mergeFromProto3Json(jsonDecode(buildJson) as Map<String, dynamic>);

    const pushMessage = PushMessage(data: buildJson, messageId: '798274983');
    tester.message = pushMessage;

    when(
      buildBucketClient.getBuild(
        any,
        buildBucketUri:
            'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds',
      ),
    ).thenAnswer((_) => Future<bbv2.Build>.value(build));

    final datastoreCommit = <Commit>[commit];
    await config.db.commit(inserts: datastoreCommit);
  });

  test('creates a new task successfully', () async {
    when(
      mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
    ).thenAnswer((Invocation invocation) {
      return Future<BatchWriteResponse>.value(BatchWriteResponse());
    });
    tester.message = const PushMessage(data: buildMessageJson);

    await tester.post(handler);

    verify(buildBucketClient.getBuild(any)).called(1);

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
    expect(commitInDb.id, equals(taskInDb.commitKey?.id));

    expect(commitInDb.id, equals(taskInDb.parentKey?.id));

    // Ensure the task in the db is exactly what we expect
    final expectedTask = Task(
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

    expect(taskInDb.toString(), equals(expectedTask.toString()));

    final captured =
        verify(
          mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
        ).captured;
    expect(captured.length, 2);
    final batchWriteRequest = captured[0] as BatchWriteRequest;
    expect(batchWriteRequest.writes!.length, 1);
    final insertedTaskDocument = firestore.Task.fromDocument(
      batchWriteRequest.writes![0].update!,
    );
    expect(insertedTaskDocument.taskName, expectedTask.name);
  });

  test('updates an existing task successfully', () async {
    when(
      mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
    ).thenAnswer((Invocation invocation) {
      return Future<BatchWriteResponse>.value(BatchWriteResponse());
    });
    const existingTaskId = 123;
    final fakeTask = Task(
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
    final datastoreCommit = <Task>[fakeTask];
    await config.db.commit(inserts: datastoreCommit);

    const pushMessage = PushMessage(
      data: buildMessageJson,
      messageId: '798274983',
    );
    tester.message = pushMessage;

    await tester.post(handler);

    verify(buildBucketClient.getBuild(any)).called(1);

    // This is used for testing to pull the data out of the "datastore" so that
    // we can verify what was saved.
    final expectedBuilderList =
        '${existingTaskId.toString()},${buildNumber.toString()}';
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
    expect(commitInDb.id, equals(taskInDb.commitKey?.id));

    expect(commitInDb.id, equals(taskInDb.parentKey?.id));

    // Ensure the task in the db is exactly what we expect
    final expectedTask = Task(
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

    expect(taskInDb.toString(), equals(expectedTask.toString()));

    final captured =
        verify(
          mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
        ).captured;
    expect(captured.length, 2);
    final batchWriteRequest = captured[0] as BatchWriteRequest;
    expect(batchWriteRequest.writes!.length, 1);
    final insertedTaskDocument = firestore.Task.fromDocument(
      batchWriteRequest.writes![0].update!,
    );
    expect(insertedTaskDocument.status, expectedTask.status);
  });

  test('ignores message with empty build data', () async {
    tester.message = const PushMessage();
    expect(await tester.post(handler), equals(Body.empty));
  });

  // // TODO create a construction method for this to simplify testing.
  test('ignores message not from flutter bucket', () async {
    const dartMessage = '''
{
  "build": {
    "id": "8766855135863637953",
    "builder": {
      "project": "dart-internal",
      "bucket": "dart",
      "builder": "Linux packaging_release_builder"
    },
    "number": 123456,
    "status": "SUCCESS",
    "input": {
      "gitilesCommit": {
        "project":"flutter/flutter",
        "id":"HASH12345",
        "ref":"refs/heads/test-branch"
      }
    }
  }
}
''';

    const pushMessage = PushMessage(data: dartMessage, messageId: '798274983');
    tester.message = pushMessage;
    expect(await tester.post(handler), equals(Body.empty));
  });

  test('ignores message not from dart-internal project', () async {
    const unsupportedProjectMessage = '''
{
  "build": {
    "id": "8766855135863637953",
    "builder": {
      "project": "unsupported-project",
      "bucket": "dart",
      "builder": "Linux packaging_release_builder"
    },
    "number": 123456,
    "status": "SUCCESS",
    "input": {
      "gitilesCommit": {
        "project": "flutter/flutter",
        "id": "HASH12345",
        "ref": "refs/heads/test-branch"
      }
    }
  }
}
''';

    const pushMessage = PushMessage(
      data: unsupportedProjectMessage,
      messageId: '798274983',
    );
    tester.message = pushMessage;
    expect(await tester.post(handler), equals(Body.empty));
  });

  test('ignores message not from an accepted builder', () async {
    const unknownBuilderMessage = '''
{
  "build": {
    "id": "8766855135863637953",
    "builder": {
      "project": "dart-internal",
      "bucket": "dart",
      "builder": "different builder"
    },
    "number": 123456,
    "status": "SUCCESS",
    "input": {
      "gitilesCommit": {
        "project": "flutter/flutter",
        "id": "HASH12345",
        "ref": "refs/heads/test-branch"
      }
    }
  }
}
''';

    const pushMessage = PushMessage(
      data: unknownBuilderMessage,
      messageId: '798274983',
    );
    tester.message = pushMessage;
    expect(await tester.post(handler), equals(Body.empty));
  });
}
