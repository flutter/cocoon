// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

void main() {
  late PostsubmitLuciSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late MockGithubChecksService mockGithubChecksService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeScheduler scheduler;

  setUp(() async {
    config = FakeConfig(maxLuciTaskRetriesValue: 3);
    mockGithubChecksUtil = MockGithubChecksUtil();
    mockGithubChecksService = MockGithubChecksService();
    when(mockGithubChecksService.githubChecksUtil).thenReturn(mockGithubChecksUtil);
    when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
        .thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    final FakeLuciBuildService luciBuildService = FakeLuciBuildService(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
    );
    scheduler = FakeScheduler(
      ciYaml: exampleConfig,
      config: config,
      luciBuildService: luciBuildService,
    );
    handler = PostsubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      githubChecksService: mockGithubChecksService,
      datastoreProvider: (_) => DatastoreService(config.db, 5),
      scheduler: scheduler,
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
      builderName: '',
      userData: '{\\"commit_key\\":\\"flutter/main/abc123\\"}',
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
      name: 'Linux A',
    );

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;

    expect(task.status, Task.statusNew);
    expect(task.endTimestamp, 0);

    await tester.post(handler);

    expect(task.status, Task.statusSucceeded);
    expect(task.endTimestamp, 1565049193786);
  });

  test('skips task processing when build is with scheduled status', () async {
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
      'SCHEDULED',
      builderName: 'Linux A',
      result: null,
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusInProgress);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusInProgress);
  });

  test('skips task processing when task has already finished', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    tester.message = createBuildbucketPushMessage(
      'STARTED',
      builderName: 'Linux A',
      result: null,
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusSucceeded);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusSucceeded);
  });

  test('skips task processing when target has been deleted', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux B',
      parent: commit,
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    tester.message = createBuildbucketPushMessage(
      'STARTED',
      builderName: 'Linux B',
      result: null,
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusSucceeded);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
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
      status: Task.statusFailed,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'FAILURE',
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusFailed);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusInProgress);
    expect(task.attempts, 2);
  });

  test('on canceled builds auto-rerun the build if they timed out', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusInfraFailure,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'CANCELED',
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusInfraFailure);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusInProgress);
    expect(task.attempts, 2);
  });

  test('on builds resulting in an infra failure auto-rerun the build if they timed out', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusInfraFailure,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'INFRA_FAILURE',
      userData: '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusInfraFailure);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusInProgress);
    expect(task.attempts, 2);
  });

  test('fallback to build parameters if task_key is not present', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusNew,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'FAILURE',
      userData: '{\\"task_key\\":\\"null\\", \\"commit_key\\":\\"${task.key.parent?.id}\\"}',
    );

    expect(task.status, Task.statusNew);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusInProgress);
  });

  test('non-bringup target updates check run', () async {
    scheduler.ciYaml = nonBringupPackagesConfig;
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822', repo: 'packages');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux nonbringup',
      parent: commit,
    );
    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux A',
      // Use escaped string to mock json decoded ones.
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"packages\\"}',
    );
    await tester.post(handler);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any)).called(1);
  });

  test('bringup target does not update check run', () async {
    scheduler.ciYaml = bringupPackagesConfig;
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux bringup',
      parent: commit,
    );
    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux bringup',
      // Use escaped string to mock json decoded ones.
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"packages\\"}',
    );
    await tester.post(handler);
    verifyNever(mockGithubChecksService.updateCheckStatus(any, any, any));
  });

  test('unsupported repo target does not update check run', () async {
    scheduler.ciYaml = unsupportedPostsubmitCheckrunConfig;
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux flutter',
      parent: commit,
    );
    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux bringup',
      // Use escaped string to mock json decoded ones.
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"flutter\\"}',
    );
    await tester.post(handler);
    verifyNever(mockGithubChecksService.updateCheckStatus(any, any, any));
  });
}
