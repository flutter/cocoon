// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:googleapis/firestore/v1.dart';
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
  late MockFirestoreService mockFirestoreService;
  late SubscriptionTester tester;
  late MockGithubChecksService mockGithubChecksService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeScheduler scheduler;
  firestore.Task? firestoreTask;

  setUp(() async {
    firestoreTask = null;
    mockGithubChecksUtil = MockGithubChecksUtil();
    mockFirestoreService = MockFirestoreService();
    config = FakeConfig(
      maxLuciTaskRetriesValue: 3,
      firestoreService: mockFirestoreService,
    );
    mockGithubChecksService = MockGithubChecksService();
    when(mockGithubChecksService.githubChecksUtil).thenReturn(mockGithubChecksUtil);
    when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
        .thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    when(
      mockFirestoreService.getDocument(
        captureAny,
      ),
    ).thenAnswer((Invocation invocation) {
      return Future<Document>.value(
        firestoreTask,
      );
    });
    when(
      mockFirestoreService.batchWriteDocuments(
        captureAny,
        captureAny,
      ),
    ).thenAnswer((Invocation invocation) {
      return Future<BatchWriteResponse>.value(BatchWriteResponse());
    });
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

  test('throws exception when task document name is not in message', () async {
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: '',
      userData: '{\\"commit_key\\":\\"flutter/main/abc123\\"}',
    );

    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('updates task based on message', () async {
    firestoreTask = generateFirestoreTask(1, attempts: 2, name: 'Linux A');
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 2);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      parent: commit,
      name: 'Linux A',
    );
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );

    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;

    expect(task.status, Task.statusNew);
    expect(task.endTimestamp, 0);

    // Firestore checks before API call.
    expect(firestoreTask!.status, Task.statusNew);
    expect(firestoreTask!.buildNumber, null);

    await tester.post(handler);

    expect(task.status, Task.statusSucceeded);
    expect(task.endTimestamp, 1565049193786);

    // Firestore checks after API call.
    final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
    expect(captured.length, 2);
    final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
    expect(batchWriteRequest.writes!.length, 1);
    final Document updatedDocument = batchWriteRequest.writes![0].update!;
    expect(updatedDocument.name, firestoreTask!.name);
    expect(firestoreTask!.status, Task.statusSucceeded);
    expect(firestoreTask!.buildNumber, 1698);
  });

  test('skips task processing when build is with scheduled status', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux A', status: firestore.Task.statusInProgress);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusInProgress,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';
    tester.message = createBuildbucketPushMessage(
      'SCHEDULED',
      builderName: 'Linux A',
      result: null,
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );

    expect(firestoreTask!.status, firestore.Task.statusInProgress);
    expect(firestoreTask!.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    expect(firestoreTask!.status, firestore.Task.statusInProgress);
  });

  test('skips task processing when task has already finished', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux A', status: firestore.Task.statusSucceeded);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';
    tester.message = createBuildbucketPushMessage(
      'STARTED',
      builderName: 'Linux A',
      result: null,
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );

    expect(task.status, Task.statusSucceeded);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    expect(task.status, Task.statusSucceeded);
  });

  test('skips task processing when target has been deleted', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux B', status: firestore.Task.statusSucceeded);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux B',
      parent: commit,
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';
    tester.message = createBuildbucketPushMessage(
      'STARTED',
      builderName: 'Linux B',
      result: null,
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
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
    firestoreTask = generateFirestoreTask(1, name: 'Linux A', status: firestore.Task.statusFailed);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusFailed,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'FAILURE',
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );

    expect(firestoreTask!.status, firestore.Task.statusFailed);
    expect(firestoreTask!.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
    expect(captured.length, 2);
    final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
    expect(batchWriteRequest.writes!.length, 1);
    final Document insertedTaskDocument = batchWriteRequest.writes![0].update!;
    final firestore.Task resultTask = firestore.Task.fromDocument(taskDocument: insertedTaskDocument);
    expect(resultTask.status, firestore.Task.statusInProgress);
    expect(resultTask.attempts, 2);
  });

  test('on canceled builds auto-rerun the build if they timed out', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux A', status: firestore.Task.statusInfraFailure);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusInfraFailure,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'CANCELED',
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );

    expect(firestoreTask!.status, firestore.Task.statusInfraFailure);
    expect(firestoreTask!.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
    expect(captured.length, 2);
    final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
    expect(batchWriteRequest.writes!.length, 1);
    final Document insertedTaskDocument = batchWriteRequest.writes![0].update!;
    final firestore.Task resultTask = firestore.Task.fromDocument(taskDocument: insertedTaskDocument);
    expect(resultTask.status, firestore.Task.statusInProgress);
    expect(resultTask.attempts, 2);
  });

  test('on builds resulting in an infra failure auto-rerun the build if they timed out', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux A', status: firestore.Task.statusInfraFailure);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
      status: Task.statusInfraFailure,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      builderName: 'Linux A',
      result: 'FAILURE',
      failureReason: 'INFRA_FAILURE',
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );

    expect(task.status, Task.statusInfraFailure);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
    final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
    expect(captured.length, 2);
    final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
    expect(batchWriteRequest.writes!.length, 1);
    final Document insertedTaskDocument = batchWriteRequest.writes![0].update!;
    final firestore.Task resultTask = firestore.Task.fromDocument(taskDocument: insertedTaskDocument);
    expect(resultTask.status, firestore.Task.statusInProgress);
    expect(resultTask.attempts, 2);
  });

  test('non-bringup target updates check run', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux nonbringup');
    scheduler.ciYaml = nonBringupPackagesConfig;
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 2);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822', repo: 'packages');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux nonbringup',
      parent: commit,
    );
    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux A',
      // Use escaped string to mock json decoded ones.
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );
    await tester.post(handler);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any)).called(1);
  });

  test('bringup target does not update check run', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux bringup');
    scheduler.ciYaml = bringupPackagesConfig;
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 2);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux bringup',
      parent: commit,
    );
    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux bringup',
      // Use escaped string to mock json decoded ones.
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );
    await tester.post(handler);
    verifyNever(mockGithubChecksService.updateCheckStatus(any, any, any));
  });

  test('unsupported repo target does not update check run', () async {
    scheduler.ciYaml = unsupportedPostsubmitCheckrunConfig;
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 2);
    firestoreTask = generateFirestoreTask(1, attempts: 2, name: 'Linux flutter');

    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux flutter',
      parent: commit,
    );
    config.db.values[commit.key] = commit;
    config.db.values[task.key] = task;
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';

    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux bringup',
      // Use escaped string to mock json decoded ones.
      userData:
          '{\\"task_key\\":\\"${task.key.id}\\", \\"commit_key\\":\\"${task.key.parent?.id}\\", \\"firestore_commit_document_name\\":\\"${commit.sha}\\", \\"firestore_task_document_name\\":\\"$taskDocumentName\\"}',
    );
    await tester.post(handler);
    verifyNever(mockGithubChecksService.updateCheckStatus(any, any, any));
  });
}
