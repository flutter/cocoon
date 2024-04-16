// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as firestore_commit;
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/request_handlers/postsubmit_luci_subscription_v2.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_v2_tester.dart';
import '../src/service/fake_luci_build_service_v2.dart';
import '../src/service/fake_scheduler_v2.dart';
import '../src/utilities/build_bucket_v2_messages.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  late PostsubmitLuciSubscriptionV2 handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late MockFirestoreService mockFirestoreService;
  late SubscriptionV2Tester tester;
  late MockGithubChecksServiceV2 mockGithubChecksService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeSchedulerV2 scheduler;
  firestore.Task? firestoreTask;
  firestore_commit.Commit? firestoreCommit;
  late int attempt;

  setUp(() async {
    firestoreTask = null;
    attempt = 0;
    mockGithubChecksUtil = MockGithubChecksUtil();
    mockFirestoreService = MockFirestoreService();
    config = FakeConfig(
      maxLuciTaskRetriesValue: 3,
      firestoreService: mockFirestoreService,
    );
    mockGithubChecksService = MockGithubChecksServiceV2();
    when(mockGithubChecksService.githubChecksUtil).thenReturn(mockGithubChecksUtil);
    when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
        .thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
    when(
      mockFirestoreService.getDocument(
        captureAny,
      ),
    ).thenAnswer((Invocation invocation) {
      attempt++;
      if (attempt == 1) {
        return Future<Document>.value(
          firestoreTask,
        );
      } else {
        return Future<Document>.value(
          firestoreCommit,
        );
      }
    });
    when(
      mockFirestoreService.queryRecentCommits(
        limit: captureAnyNamed('limit'),
        slug: captureAnyNamed('slug'),
        branch: captureAnyNamed('branch'),
      ),
    ).thenAnswer((Invocation invocation) {
      return Future<List<firestore_commit.Commit>>.value(
        <firestore_commit.Commit>[firestoreCommit!],
      );
    });
    // when(
    //   mockFirestoreService.getDocument(
    //     'projects/flutter-dashboard/databases/cocoon/documents/tasks/87f88734747805589f2131753620d61b22922822_Linux A_1',
    //   ),
    // ).thenAnswer((Invocation invocation) {
    //   return Future<Document>.value(
    //     firestoreCommit,
    //   );
    // });
    when(
      mockFirestoreService.batchWriteDocuments(
        captureAny,
        captureAny,
      ),
    ).thenAnswer((Invocation invocation) {
      return Future<BatchWriteResponse>.value(BatchWriteResponse());
    });
    final FakeLuciBuildServiceV2 luciBuildService = FakeLuciBuildServiceV2(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
    );
    scheduler = FakeSchedulerV2(
      ciYaml: exampleConfig,
      config: config,
      luciBuildService: luciBuildService,
    );
    handler = PostsubmitLuciSubscriptionV2(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      githubChecksService: mockGithubChecksService,
      datastoreProvider: (_) => DatastoreService(config.db, 5),
      scheduler: scheduler,
    );
    request = FakeHttpRequest();

    tester = SubscriptionV2Tester(
      request: request,
    );
  });

  test('throws exception when task document name is not in message', () async {
    const Map<String, dynamic> userDataMap = {
      'commit_key': 'flutter/main/abc123',
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: '',
      userData: userDataMap,
    );

    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('updates task based on message', () async {
    firestoreTask = generateFirestoreTask(1, attempts: 2, name: 'Linux A');
    when(mockGithubChecksService.currentAttempt(any)).thenAnswer((_) => 2);
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      name: 'Linux A',
      parent: commit,
    );
    final String taskDocumentName = '${commit.sha}_${task.name}_${task.attempts}';

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      userData: userDataMap,
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
    expect(task.endTimestamp, 1697672824674);

    // Firestore checks after API call.
    final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
    expect(captured.length, 2);
    final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
    expect(batchWriteRequest.writes!.length, 1);
    final Document updatedDocument = batchWriteRequest.writes![0].update!;
    expect(updatedDocument.name, firestoreTask!.name);
    expect(firestoreTask!.status, Task.statusSucceeded);
    expect(firestoreTask!.buildNumber, 259942);
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SCHEDULED,
      builder: 'Linux A',
      userData: userDataMap,
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.STARTED,
      builder: 'Linux A',
      userData: userDataMap,
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.STARTED,
      builder: 'Linux B',
      userData: userDataMap,
    );

    expect(task.status, Task.statusSucceeded);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);
  });

  test('does not fail on empty user data', () async {
    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
    );
    expect(await tester.post(handler), Body.empty);
  });

  test('on failed builds auto-rerun the build', () async {
    firestoreTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      status: firestore.Task.statusFailed,
      commitSha: '87f88734747805589f2131753620d61b22922822',
    );
    firestoreCommit = generateFirestoreCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.FAILURE,
      builder: 'Linux A',
      userData: userDataMap,
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
    firestoreTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      status: firestore.Task.statusInfraFailure,
      commitSha: '87f88734747805589f2131753620d61b22922822',
    );
    firestoreCommit = generateFirestoreCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.CANCELED,
      builder: 'Linux A',
      userData: userDataMap,
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
    firestoreTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      status: firestore.Task.statusInfraFailure,
      commitSha: '87f88734747805589f2131753620d61b22922822',
    );
    firestoreCommit = generateFirestoreCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.INFRA_FAILURE,
      builder: 'Linux A',
      userData: userDataMap,
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
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
      userData: userDataMap,
    );

    await tester.post(handler);
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).called(1);
  });

  test('bringup target does not update check run', () async {
    firestoreTask = generateFirestoreTask(1, name: 'Linux bringup');
    scheduler.ciYaml = bringupPackagesConfig;
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux bringup',
      userData: userDataMap,
    );

    await tester.post(handler);
    verifyNever(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    );
  });

  test('unsupported repo target does not update check run', () async {
    scheduler.ciYaml = unsupportedPostsubmitCheckrunConfig;
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
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

    final Map<String, dynamic> userDataMap = {
      'task_key': '${task.key.id}',
      'commit_key': '${task.key.parent?.id}',
      'firestore_commit_document_name': commit.sha,
      'firestore_task_document_name': taskDocumentName,
    };

    tester.message = createPushMessageV2(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux bringup',
      userData: userDataMap,
    );

    await tester.post(handler);
    verifyNever(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        userDataMap: anyNamed('userDataMap'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    );
  });
}
