// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/request_handling/subscription_tester.dart';
import '../src/utilities/build_bucket_messages.dart';

void main() {
  useTestLoggerPerTest();

  late PostsubmitLuciSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late FakeFirestoreService firestore;
  late SubscriptionTester tester;
  late MockGithubChecksService mockGithubChecksService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeCiYamlFetcher ciYamlFetcher;

  setUp(() async {
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestore = FakeFirestoreService();
    config = FakeConfig(maxLuciTaskRetriesValue: 3);
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
      firestore: firestore,
    );
    ciYamlFetcher = FakeCiYamlFetcher();
    handler = PostsubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeDashboardAuthentication(),
      githubChecksService: mockGithubChecksService,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: luciBuildService,
      firestore: firestore,
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

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
        ),
      ),
      number: 63405,
    );

    // Firestore checks before API call.
    expect(fsTask.status, TaskStatus.waitingForBackfill);
    expect(fsTask.buildNumber, null);

    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux A')
            .hasStatus(TaskStatus.succeeded)
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
      status: TaskStatus.inProgress,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SCHEDULED,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
        ),
      ),
    );

    expect(await tester.post(handler), Response.emptyOk);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux A')
            .hasStatus(TaskStatus.inProgress)
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
      status: TaskStatus.succeeded,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.STARTED,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
        ),
      ),
    );

    expect(await tester.post(handler), Response.emptyOk);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux A')
            .hasStatus(TaskStatus.succeeded)
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
      status: TaskStatus.succeeded,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    final userData = PostsubmitUserData(
      checkRunId: null,
      taskId: fs.TaskId(
        commitSha: fsCommit.sha,
        taskName: fsTask.taskName,
        currentAttempt: fsTask.currentAttempt,
      ),
    );
    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.STARTED,
      builder: 'Linux B',
      userData: userData,
    );

    expect(await tester.post(handler), Response.emptyOk);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux B')
            .hasStatus(TaskStatus.succeeded)
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
      status: TaskStatus.failed,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.FAILURE,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
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
              .hasStatus(TaskStatus.inProgress)
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
      status: TaskStatus.infraFailure,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.CANCELED,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
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
              .hasStatus(TaskStatus.inProgress)
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
        status: TaskStatus.infraFailure,
      );
      firestore.putDocument(fsCommit);
      firestore.putDocument(fsTask);

      tester.message = createPushMessage(
        Int64(1),
        status: bbv2.Status.INFRA_FAILURE,
        builder: 'Linux A',
        userData: PostsubmitUserData(
          checkRunId: null,
          taskId: fs.TaskId(
            commitSha: fsCommit.sha,
            taskName: fsTask.taskName,
            currentAttempt: fsTask.currentAttempt,
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
                .hasStatus(TaskStatus.inProgress)
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

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: 1,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
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
        isTask.hasTaskName('Linux nonbringup').hasStatus(TaskStatus.succeeded),
      ]),
    );
  });

  test('bringup target does not update check run', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
      repo: 'packages',
      branch: Config.defaultBranch(Config.packagesSlug),
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

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux bringup',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
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
    ciYamlFetcher.ciYaml = unsupportedPostsubmitCheckrunFusionConfig;
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

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux bringup',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
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
        isTask.hasTaskName('Linux flutter').hasStatus(TaskStatus.succeeded),
      ]),
    );
  });

  test('skips rerunning a successful builder', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: TaskStatus.inProgress,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.SUCCESS,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
        ),
      ),
    );

    await tester.post(handler);

    expect(firestore, existsInStorage(fs.Task.metadata, hasLength(1)));
  });

  test('skips rerunning if past retry limit', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: TaskStatus.inProgress,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.FAILURE,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
        ),
      ),
    );

    config.maxLuciTaskRetriesValue = 0;

    await tester.post(handler);

    expect(firestore, existsInStorage(fs.Task.metadata, hasLength(1)));

    expect(
      log,
      bufferedLoggerOf(
        contains(logThat(message: contains('Max retries reached'))),
      ),
    );
  });

  test('skips rerunning when builder is not in tip-of-tree', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: TaskStatus.inProgress,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    // Add another commit to ToT.
    firestore.putDocument(generateFirestoreCommit(2));

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.FAILURE,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
        ),
      ),
    );

    await tester.post(handler);

    expect(firestore, existsInStorage(fs.Task.metadata, hasLength(1)));

    expect(
      log,
      bufferedLoggerOf(contains(logThat(message: contains('Not tip of tree')))),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/168738.
  test('skips rerunning when builder is an experimental branch', () async {
    final fsCommit = generateFirestoreCommit(
      1,
      sha: '87f88734747805589f2131753620d61b22922822',
      // Notably not "master" or "flutter-X.XX-candidate.0".
      branch: 'ios-experimental',
    );
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: TaskStatus.inProgress,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    // Add another commit to ToT.
    firestore.putDocument(generateFirestoreCommit(2));

    tester.message = createPushMessage(
      Int64(1),
      status: bbv2.Status.FAILURE,
      builder: 'Linux A',
      userData: PostsubmitUserData(
        checkRunId: null,
        taskId: fs.TaskId(
          commitSha: fsCommit.sha,
          taskName: fsTask.taskName,
          currentAttempt: fsTask.currentAttempt,
        ),
      ),
    );

    await tester.post(handler);

    expect(firestore, existsInStorage(fs.Task.metadata, hasLength(1)));

    expect(
      log,
      bufferedLoggerOf(
        contains(
          logThat(
            message: contains('Skip automatic reruns for experimental branch'),
          ),
        ),
      ),
    );
  });
}
