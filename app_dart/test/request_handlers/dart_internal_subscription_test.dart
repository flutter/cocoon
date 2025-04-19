// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  // Omit the timestamps for expect purposes.
  const buildJson = '''{
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

  const buildMessageJson = '''{
    "build": $buildJson
  }''';

  late DartInternalSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late MockBuildBucketClient buildBucketClient;
  late SubscriptionTester tester;
  late FakeFirestoreService firestoreService;

  final dsCommit = generateCommit(
    1,
    sha: 'HASH12345',
    branch: 'test-branch',
    owner: 'flutter',
    repo: 'flutter',
    timestamp: 0,
  );

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
    firestoreService = FakeFirestoreService();
    config = FakeConfig(firestoreService: firestoreService);
    buildBucketClient = MockBuildBucketClient();
    handler = DartInternalSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeDashboardAuthentication(),
    );

    request = FakeHttpRequest();
    tester = SubscriptionTester(request: request);

    final build = bbv2.Build().createEmptyInstance();
    build.mergeFromProto3Json(jsonDecode(buildJson) as Map<String, Object?>);

    const pushMessage = PushMessage(data: buildJson, messageId: '798274983');
    tester.message = pushMessage;

    when(
      buildBucketClient.getBuild(
        any,
        buildBucketUri:
            'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds',
      ),
    ).thenAnswer((_) async => build);

    // Setup Firestore:
    firestoreService.putDocument(fsCommit);
  });

  test('creates a new task', () async {
    tester.message = const PushMessage(data: buildMessageJson);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestoreService,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber)
            .hasStatus('Succeeded'),
      ]),
    );
  });

  test('updates an existing task', () async {
    // Insert into Firestore:
    firestoreService.putDocument(
      generateFirestoreTask(
        1,
        attempts: 1,
        buildNumber: buildNumber,
        name: builder,
        status: 'In Progress',
        commitSha: dsCommit.sha,
      ),
    );

    tester.message = const PushMessage(data: buildMessageJson);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestoreService,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber)
            .hasStatus('Succeeded'),
      ]),
    );
  });

  test('records a retry of an existing task', () async {
    // Insert into Firestore:
    firestoreService.putDocument(
      generateFirestoreTask(
        1,
        attempts: 1,
        buildNumber: buildNumber - 1,
        name: builder,
        status: fs.Task.statusFailed,
        commitSha: dsCommit.sha,
      ),
    );

    tester.message = const PushMessage(data: buildMessageJson);
    await tester.post(handler);

    // Check Firestore:
    expect(
      firestoreService,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(1)
            .hasBuildNumber(buildNumber - 1)
            .hasStatus(fs.Task.statusFailed),
        isTask
            .hasTaskName(builder)
            .hasCurrentAttempt(2)
            .hasBuildNumber(buildNumber)
            .hasStatus(fs.Task.statusSucceeded),
      ]),
    );
  });
}
