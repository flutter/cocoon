// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/request_handling/subscription_tester.dart';

void main() {
  useTestLoggerPerTest();

  // Omit the timestamps for expect purposes.
  const buildJsonSuccess = '''{
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
  }''';

  const buildMessageJsonSuccess =
      '''{
    "build": $buildJsonSuccess
  }''';

  const buildJsonInProgress = '''{
    "id": "8766855135863637953",
    "builder": {
      "project": "dart-internal",
      "bucket": "flutter",
      "builder": "Linux packaging_release_builder"
    },
    "number": 123456,
    "status": "STARTED",
    "input": {
      "gitilesCommit": {
        "project": "flutter/flutter",
        "id": "HASH12345",
        "ref": "refs/heads/test-branch"
      }
    }
  }''';

  const buildMessageJsonInProgress =
      '''{
    "build": $buildJsonInProgress
  }''';

  late DartInternalSubscription handler;
  late FakeHttpRequest request;
  late MockBuildBucketClient buildBucketClient;
  late SubscriptionTester tester;
  late FakeFirestoreService firestore;

  final fsCommit = generateFirestoreCommit(
    1,
    sha: 'HASH12345',
    branch: 'test-branch',
    owner: 'flutter',
    repo: 'flutter',
    createTimestamp: 0,
  );

  const builder = 'Linux packaging_release_builder';
  const buildNumber = 123456;

  setUp(() async {
    firestore = FakeFirestoreService();
    buildBucketClient = MockBuildBucketClient();
    handler = DartInternalSubscription(
      cache: CacheService(inMemory: true),
      config: FakeConfig(),
      authProvider: FakeDashboardAuthentication(),
      firestore: firestore,
    );

    request = FakeHttpRequest();
    tester = SubscriptionTester(request: request);

    final build = bbv2.Build().createEmptyInstance();
    build.mergeFromProto3Json(
      jsonDecode(buildJsonSuccess) as Map<String, Object?>,
    );

    const pushMessage = PushMessage(
      data: buildJsonSuccess,
      messageId: '798274983',
    );
    tester.message = pushMessage;

    when(
      buildBucketClient.getBuild(
        any,
        buildBucketUri:
            'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds',
      ),
    ).thenAnswer((_) async => build);

    // Setup Firestore:
    firestore.putDocument(fsCommit);
  });

  test('creates a new task', () async {
    tester.message = const PushMessage(data: buildMessageJsonSuccess);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber)
            .hasStatus(TaskStatus.succeeded),
      ]),
    );
  });

  test('updates an existing task', () async {
    // Insert into Firestore:
    firestore.putDocument(
      generateFirestoreTask(
        1,
        attempts: 1,
        buildNumber: buildNumber,
        name: builder,
        status: TaskStatus.inProgress,
        commitSha: fsCommit.sha,
      ),
    );

    tester.message = const PushMessage(data: buildMessageJsonSuccess);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber)
            .hasStatus(TaskStatus.succeeded),
      ]),
    );
  });

  test('updates an existing task waiting for a build number', () async {
    // Insert into Firestore:
    firestore.putDocument(
      generateFirestoreTask(
        1,
        attempts: 1,
        buildNumber: buildNumber,
        name: builder,
        status: TaskStatus.inProgress,
        commitSha: fsCommit.sha,
      ),
    );

    tester.message = const PushMessage(data: buildMessageJsonInProgress);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber)
            .hasStatus(TaskStatus.inProgress),
      ]),
    );
  });

  test('records a retry of an existing task', () async {
    // Insert into Firestore:
    firestore.putDocument(
      generateFirestoreTask(
        1,
        attempts: 1,
        buildNumber: buildNumber - 1,
        name: builder,
        status: TaskStatus.failed,
        commitSha: fsCommit.sha,
      ),
    );

    tester.message = const PushMessage(data: buildMessageJsonSuccess);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber - 1)
            .hasStatus(TaskStatus.failed),
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(2)
            .hasBuildNumber(buildNumber)
            .hasStatus(TaskStatus.succeeded),
      ]),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/170370.
  test('reuses an existing task waiting for a build number', () async {
    // Insert into Firestore:
    firestore.putDocument(
      generateFirestoreTask(
        1,
        attempts: 1,
        // Intentionally omitted.
        buildNumber: null,
        name: builder,
        status: TaskStatus.inProgress,
        commitSha: fsCommit.sha,
      ),
    );

    tester.message = const PushMessage(data: buildMessageJsonSuccess);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber)
            .hasStatus(TaskStatus.succeeded),
      ]),
    );
  });
}
