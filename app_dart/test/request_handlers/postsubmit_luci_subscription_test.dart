// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/push_message.dart';

void main() {
  late PostsubmitLuciSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late SubscriptionTester tester;

  setUp(() async {
    config = FakeConfig(maxLuciTaskRetriesValue: 3);
    handler = PostsubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      datastoreProvider: (_) => DatastoreService(config.db, 5),
      luciBuildService: FakeLuciBuildService(config),
      scheduler: FakeScheduler(
        ciYaml: exampleConfig,
        config: config,
      ),
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(
      request: request,
    );
  });

  test('throws exception when task key is not in message', () async {
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      userData: '{}',
    );

    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('throws exception if task key does not exist in datastore', () {
    final Task task = generateTask(1);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(() => tester.post(handler), throwsA(isA<KeyNotFoundException>()));
  });

  test('updates task based on message', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      parent: commit,
    );

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    config.db.values[task.key] = task;

    expect(task.status, Task.statusNew);
    expect(task.endTimestamp, 0);

    await tester.post(handler);

    expect(task.status, Task.statusSucceeded);
    expect(task.endTimestamp, 1565049193786);
  });

  test('does not fail on empty user data', () async {
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      userData: null,
    );

    expect(await tester.post(handler), Body.empty);
  });

  test('on failed builds auto-rerun the build', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusInProgress,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'FAILURE',
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusInProgress);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusNew);
  });
}
