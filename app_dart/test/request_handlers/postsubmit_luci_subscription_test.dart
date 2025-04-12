// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_ci_yaml_fetcher.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/build_bucket_messages.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late PostsubmitLuciSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late FakeFirestoreService firestore;
  late SubscriptionTester tester;
  late MockGithubChecksService mockGithubChecksService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeScheduler scheduler;
  late FakeCiYamlFetcher ciYamlFetcher;

  setUp(() async {
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestore = FakeFirestoreService();
    config = FakeConfig(
      maxLuciTaskRetriesValue: 3,
      firestoreService: firestore,
    );
    mockGithubChecksService = MockGithubChecksService();
    when(
      mockGithubChecksService.githubChecksUtil,
    ).thenReturn(mockGithubChecksUtil);
    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
    final luciBuildService = FakeLuciBuildService(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
    );
    scheduler = FakeScheduler(
      config: config,
      luciBuildService: luciBuildService,
    );
    ciYamlFetcher = FakeCiYamlFetcher();
    handler = PostsubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      githubChecksService: mockGithubChecksService,
      scheduler: scheduler,
      ciYamlFetcher: ciYamlFetcher,
    );
    request = FakeHttpRequest();
    tester = SubscriptionTester(request: request);
  });

  test('updates task based on message', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final task = generateTask(4507531199512576, name: 'Linux A');

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      userData: PostsubmitUserData(
        checkRunId: null,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
      number: 63405,
    );

    config.db.values[task.key] = task;

    expect(task.status, Task.statusNew);
    expect(task.endTimestamp, 0);

    // Firestore checks before API call.
    expect(fsTask.status, Task.statusNew);
    expect(fsTask.buildNumber, null);

    await tester.post(handler);

    expect(task.status, Task.statusSucceeded);
    expect(task.endTimestamp, 1717430718072);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux A')
            .hasStatus(fs.Task.statusSucceeded)
            .hasBuildNumber(63405),
      ]),
    );
  });

  test('skips task processing when build is with scheduled status', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: fs.Task.statusInProgress,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final task = generateTask(
      4507531199512576,
      name: 'Linux A',
      status: Task.statusInProgress,
    );
    config.db.values[task.key] = task;

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SCHEDULED,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
    );

    expect(await tester.post(handler), Body.empty);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux A')
            .hasStatus(fs.Task.statusInProgress)
            .hasCurrentAttempt(1),
      ]),
    );
  });

  test('skips task processing when task has already finished', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: fs.Task.statusSucceeded,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final task = generateTask(
      4507531199512576,
      name: 'Linux A',
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.STARTED,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
    );

    expect(task.status, Task.statusSucceeded);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux A')
            .hasStatus(fs.Task.statusSucceeded)
            .hasCurrentAttempt(1),
      ]),
    );
  });

  test('skips task processing when target has been deleted', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux B',
      commitSha: fsCommit.sha,
      status: fs.Task.statusSucceeded,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final task = generateTask(
      4507531199512576,
      name: 'Linux B',
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;

    final userData = PostsubmitUserData(
      checkRunId: null,
      taskKey: '${task.key.id}',
      commitKey: '${task.key.parent?.id}',
      firestoreTaskDocumentName: fs.TaskId(
        commitSha: fsCommit.sha,
        taskName: task.name!,
        currentAttempt: task.attempts!,
      ),
    );
    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.STARTED,
      builder: 'Linux B',
      userData: userData,
    );

    expect(task.status, Task.statusSucceeded);
    expect(task.attempts, 1);
    expect(await tester.post(handler), Body.empty);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux B')
            .hasStatus(fs.Task.statusSucceeded)
            .hasCurrentAttempt(1),
      ]),
    );
  });

  test('on failed builds auto-rerun the build', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: fs.Task.statusFailed,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final task = generateTask(
      4507531199512576,
      name: 'Linux A',
      status: Task.statusFailed,
    );
    config.db.values[task.key] = task;

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.FAILURE,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
    );

    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(
        fs.Task.metadata,
        contains(
          isTask
              .hasTaskName('Linux A')
              .hasStatus(fs.Task.statusInProgress)
              .hasCurrentAttempt(2),
        ),
      ),
    );
  });

  test('on canceled builds auto-rerun the build if they timed out', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: fs.Task.statusInfraFailure,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final task = generateTask(
      4507531199512576,
      name: 'Linux A',
      status: Task.statusInfraFailure,
    );
    config.db.values[task.key] = task;

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.CANCELED,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
    );

    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(
        fs.Task.metadata,
        contains(
          isTask
              .hasTaskName('Linux A')
              .hasStatus(fs.Task.statusInProgress)
              .hasCurrentAttempt(2),
        ),
      ),
    );
  });

  test(
    'on builds resulting in an infra failure auto-rerun the build if they timed out',
    () async {
      final fsCommit = generateFirestoreCommit(
        1,
        sha: '87f88734747805589f2131753620d61b22922822',
      );
      final fsTask = generateFirestoreTask(
        1,
        name: 'Linux A',
        commitSha: fsCommit.sha,
        status: fs.Task.statusInfraFailure,
      );
      firestore.putDocument(fsCommit);
      firestore.putDocument(fsTask);

      final task = generateTask(
        4507531199512576,
        name: 'Linux A',
        status: Task.statusInfraFailure,
      );
      config.db.values[task.key] = task;

      tester.message = createPushMessage(
        Int64(1),
        status: bbv2.Status.INFRA_FAILURE,
        builder: 'Linux A',
        userData: PostsubmitUserData(
          checkRunId: null,
          taskKey: '${task.key.id}',
          commitKey: '${task.key.parent?.id}',
          firestoreTaskDocumentName: fs.TaskId(
            commitSha: fsCommit.sha,
            taskName: task.name!,
            currentAttempt: task.attempts!,
          ),
        ),
      );

      await tester.post(handler);

      expect(
        firestore,
        existsInStorage(
          fs.Task.metadata,
          contains(
            isTask
                .hasTaskName('Linux A')
                .hasStatus(fs.Task.statusInProgress)
                .hasCurrentAttempt(2),
          ),
        ),
      );
    },
  );

  test('non-bringup target updates check run', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
      repo: 'packages',
      branch: Config.defaultBranch(Config.packagesSlug),
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux nonbringup',
      commitSha: fsCommit.sha,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    ciYamlFetcher.ciYaml = nonBringupPackagesConfig;
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
    final task = generateTask(4507531199512576, name: 'Linux nonbringup');
    config.db.values[task.key] = task;

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: 1,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
    );

    await tester.post(handler);
    verify(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).called(1);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux nonbringup')
            .hasStatus(fs.Task.statusSucceeded),
      ]),
    );
  });

  test('bringup target does not update check run', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux bringup',
      commitSha: fsCommit.sha,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    ciYamlFetcher.ciYaml = bringupPackagesConfig;
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);
    final task = generateTask(4507531199512576, name: 'Linux bringup');
    config.db.values[task.key] = task;

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux bringup',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
    );

    await tester.post(handler);
    verifyNever(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    );
  });

  test('unsupported repo target does not update check run', () async {
    ciYamlFetcher.ciYaml = unsupportedPostsubmitCheckrunConfig;
    when(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    ).thenAnswer((_) async => true);

    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux flutter',
      commitSha: fsCommit.sha,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final task = generateTask(4507531199512576, name: 'Linux flutter');
    config.db.values[task.key] = task;

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux bringup',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskKey: '${task.key.id}',
        commitKey: '${task.key.parent?.id}',
        firestoreTaskDocumentName: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: task.name!,
          currentAttempt: task.attempts!,
        ),
      ),
    );

    await tester.post(handler);
    verifyNever(
      mockGithubChecksService.updateCheckStatus(
        build: anyNamed('build'),
        checkRunId: anyNamed('checkRunId'),
        luciBuildService: anyNamed('luciBuildService'),
        slug: anyNamed('slug'),
      ),
    );

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasTaskName('Linux flutter').hasStatus(fs.Task.statusSucceeded),
      ]),
    );
  });
}
