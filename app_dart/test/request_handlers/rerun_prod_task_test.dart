// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_ci_yaml_fetcher.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late RerunProdTask handler;
  late FakeConfig config;
  late MockLuciBuildService mockLuciBuildService;
  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late FakeCiYamlFetcher ciYamlFetcher;

  DateTime? now;

  setUp(() {
    final clientContext = FakeClientContext();
    firestore = FakeFirestoreService();
    clientContext.isDevelopmentEnvironment = false;
    config = FakeConfig(
      supportedBranchesValue: <String>[
        Config.defaultBranch(Config.flutterSlug),
      ],
    );
    final authContext = FakeAuthenticatedContext(clientContext: clientContext);
    tester = ApiRequestHandlerTester(context: authContext);
    mockLuciBuildService = MockLuciBuildService();
    ciYamlFetcher = FakeCiYamlFetcher(ciYaml: multiTargetFusionConfig);
    handler = RerunProdTask(
      config: config,
      authenticationProvider: FakeDashboardAuthentication(
        clientContext: clientContext,
      ),
      luciBuildService: mockLuciBuildService,
      ciYamlFetcher: ciYamlFetcher,
      firestore: firestore,
      now: () => now ?? DateTime.now(),
    );

    when(
      // ignore: discarded_futures
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    ).thenAnswer((_) async => true);
  });

  test('Schedule new task', () async {
    final fsCommit = generateFirestoreCommit(1);
    final fsTask = generateFirestoreTask(
      1,
      status: Task.statusFailed,
      name: 'Linux A',
      commitSha: fsCommit.sha,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': fsTask.taskName,
    };

    expect(await tester.post(handler), Body.empty);

    expect(
      firestore,
      existsInStorage(
        fs.Task.metadata,
        contains(
          isTask
              .hasCommitSha(fsCommit.sha)
              .hasTaskName(fsTask.taskName)
              .hasCurrentAttempt(fsTask.currentAttempt),
        ),
      ),
    );
  });

  test('Re-schedule passing all the parameters', () async {
    final fsCommit = generateFirestoreCommit(1);
    final fsTask = generateFirestoreTask(
      1,
      status: Task.statusFailed,
      name: 'Linux A',
      commitSha: fsCommit.sha,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': fsTask.taskName,
    };

    expect(await tester.post(handler), Body.empty);
    verify(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    ).called(1);
  });

  test('Re-schedule specific task cannot use a status include', () async {
    final fsCommit = generateFirestoreCommit(1);
    final fsTask = generateFirestoreTask(
      1,
      status: Task.statusFailed,
      name: 'Linux A',
      commitSha: fsCommit.sha,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': fsTask.taskName,
      'include': Task.statusSkipped,
    };

    await expectLater(
      tester.post(handler),
      throwsA(
        isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          contains('Cannot provide "include" when a task name is specified.'),
        ),
      ),
    );
  });

  test('Mark all failed tasks for rerun task name is all', () async {
    final fsCommit = generateFirestoreCommit(1);
    final fsTaskA = generateFirestoreTask(
      2,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: fs.Task.statusFailed,
    );
    final fsTaskB = generateFirestoreTask(
      3,
      name: 'Mac A',
      commitSha: fsCommit.sha,
      status: Task.statusFailed,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTaskA);
    firestore.putDocument(fsTaskB);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'all',
    };

    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    );

    expect(
      firestore,
      existsInStorage(
        fs.Task.metadata,
        unorderedEquals([
          isTask
              .hasTaskName('Linux A')
              .hasStatus(fs.Task.statusFailed)
              .hasCurrentAttempt(1),
          isTask
              .hasTaskName('Linux A')
              .hasStatus(fs.Task.statusNew)
              .hasCurrentAttempt(2),
          isTask
              .hasTaskName('Mac A')
              .hasStatus(fs.Task.statusFailed)
              .hasCurrentAttempt(1),
          isTask
              .hasTaskName('Mac A')
              .hasStatus(fs.Task.statusNew)
              .hasCurrentAttempt(2),
        ]),
      ),
    );
  });

  test('Rerun all runs nothing when everything is passed', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestore.putDocument(fsCommit);
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Windows A',
        commitSha: fsCommit.sha,
        status: fs.Task.statusSucceeded,
      ),
    );

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'all',
    };
    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    );
  });

  test('Rerun all runs nothing when everything is skipped', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestore.putDocument(fsCommit);
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Windows A',
        commitSha: fsCommit.sha,
        status: fs.Task.statusSkipped,
      ),
    );

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'all',
    };
    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    );
  });

  test('Rerun all can optionally include other statuses (skipped)', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestore.putDocument(fsCommit);
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Windows A',
        commitSha: fsCommit.sha,
        status: fs.Task.statusSkipped,
      ),
    );

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'all',
      'include': Task.statusSkipped,
    };
    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    );

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Windows A')
            .hasStatus(fs.Task.statusSkipped)
            .hasCurrentAttempt(1),
        isTask
            .hasTaskName('Windows A')
            .hasStatus(fs.Task.statusNew)
            .hasCurrentAttempt(2),
      ]),
    );
  });

  test('Rerun all cancels in-progress tasks', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestore.putDocument(fsCommit);
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Windows A',
        commitSha: fsCommit.sha,
        status: fs.Task.statusInProgress,
      ),
    );

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'all',
      'include': Task.statusInProgress,
    };
    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    );

    expect(
      firestore,
      existsInStorage(
        fs.Task.metadata,
        unorderedEquals([
          isTask
              .hasTaskName('Windows A')
              .hasStatus(fs.Task.statusCancelled)
              .hasCurrentAttempt(1),
          isTask
              .hasTaskName('Windows A')
              .hasStatus(fs.Task.statusNew)
              .hasCurrentAttempt(2),
        ]),
      ),
    );

    verify(
      mockLuciBuildService.cancelBuildsBySha(
        sha: argThat(equals(fsCommit.sha), named: 'sha'),
        reason: argThat(
          contains('cancelled build to schedule a fresh '),
          named: 'reason',
        ),
      ),
    );
  });

  test('Rerun all cancels in-progress tasks', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestore.putDocument(fsCommit);
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Windows A',
        commitSha: fsCommit.sha,
        status: fs.Task.statusInProgress,
      ),
    );

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'all',
      'include': Task.statusInProgress,
    };
    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    );

    expect(
      firestore,
      existsInStorage(
        fs.Task.metadata,
        unorderedEquals([
          isTask
              .hasTaskName('Windows A')
              .hasStatus(fs.Task.statusCancelled)
              .hasCurrentAttempt(1),
          isTask
              .hasTaskName('Windows A')
              .hasStatus(fs.Task.statusNew)
              .hasCurrentAttempt(2),
        ]),
      ),
    );

    verify(
      mockLuciBuildService.cancelBuildsBySha(
        sha: argThat(equals(fsCommit.sha), named: 'sha'),
        reason: argThat(
          contains('cancelled build to schedule a fresh '),
          named: 'reason',
        ),
      ),
    );
  });

  test('Rerun all can verifies included statuses are valid', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestore.putDocument(fsCommit);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'all',
      'include': 'Malformed',
    };

    await expectLater(
      tester.post(handler),
      throwsA(
        isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          contains('Invalid "include" statuses: Malformed.'),
        ),
      ),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/167600.
  test('Rerun all only considers the latest task for each target', () async {
    final date = DateTime(2025, 1, 1);
    final commit = generateFirestoreCommit(1);

    firestore.putDocuments([
      commit,
      generateFirestoreTask(
        1,
        name: 'Linux flutter_release_builder',
        attempts: 1,
        status: fs.Task.statusFailed,
        commitSha: '1',
        created: date,
      ),
      generateFirestoreTask(
        2,
        name: 'Linux flutter_release_builder',
        attempts: 2,
        status: fs.Task.statusSucceeded,
        commitSha: '1',
        created: date.add(const Duration(hours: 1)),
      ),
      generateFirestoreTask(
        3,
        name: 'Linux depends_on_release_builder_passing_first',
        attempts: 1,
        status: fs.Task.statusSkipped,
        commitSha: '1',
        created: date,
      ),
    ]);

    tester.requestData = {
      'branch': commit.branch,
      'repo': commit.slug.name,
      'commit': commit.sha,
      'task': 'all',
      'include': 'Skipped',
    };

    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux flutter_release_builder')
            .hasCurrentAttempt(1)
            .hasStatus(fs.Task.statusFailed),
        isTask
            .hasTaskName('Linux flutter_release_builder')
            .hasCurrentAttempt(2)
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux depends_on_release_builder_passing_first')
            .hasCurrentAttempt(1)
            .hasStatus(fs.Task.statusSkipped),
        isTask
            .hasTaskName('Linux depends_on_release_builder_passing_first')
            .hasCurrentAttempt(2)
            .hasStatus(fs.Task.statusNew),
      ]),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/167654.
  test('Rerun all marks *all* tests to be rerun, not just one', () async {
    final date = DateTime(2025, 1, 1);
    final commit = generateFirestoreCommit(1);

    firestore.putDocuments([
      commit,
      generateFirestoreTask(
        1,
        name: 'Linux A',
        attempts: 1,
        status: fs.Task.statusSkipped,
        commitSha: '1',
        created: date,
      ),
      generateFirestoreTask(
        1,
        name: 'Linux B',
        attempts: 1,
        status: fs.Task.statusSkipped,
        commitSha: '1',
        created: date,
      ),
    ]);

    tester.requestData = {
      'branch': commit.branch,
      'repo': commit.slug.name,
      'commit': commit.sha,
      'task': 'all',
      'include': 'Skipped',
    };

    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux A')
            .hasCurrentAttempt(1)
            .hasStatus(fs.Task.statusSkipped),
        isTask
            .hasTaskName('Linux B')
            .hasCurrentAttempt(1)
            .hasStatus(fs.Task.statusSkipped),
        isTask
            .hasTaskName('Linux A')
            .hasCurrentAttempt(2)
            .hasStatus(fs.Task.statusNew),
        isTask
            .hasTaskName('Linux B')
            .hasCurrentAttempt(2)
            .hasStatus(fs.Task.statusNew),
      ]),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/167654.
  test('Rerun all (Skipped -> New) updates the create timestamp', () async {
    final oldDate = DateTime(2024, 1, 1);
    final commit = generateFirestoreCommit(1);

    firestore.putDocuments([
      commit,
      generateFirestoreTask(
        1,
        name: 'Linux Old',
        attempts: 1,
        status: fs.Task.statusSkipped,
        commitSha: '1',
        created: oldDate,
      ),
    ]);

    tester.requestData = {
      'branch': commit.branch,
      'repo': commit.slug.name,
      'commit': commit.sha,
      'task': 'all',
      'include': 'Skipped',
    };

    final newDate = now = DateTime(2025, 1, 1);
    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux Old')
            .hasCurrentAttempt(1)
            .hasStatus(fs.Task.statusSkipped)
            .hasCreateTimestamp(oldDate.millisecondsSinceEpoch),
        isTask
            .hasTaskName('Linux Old')
            .hasCurrentAttempt(2)
            .hasStatus(fs.Task.statusNew)
            .hasCreateTimestamp(newDate.millisecondsSinceEpoch),
      ]),
    );
  });

  test('Rerun specific refuses flutter_release_builder', () async {
    final commit = generateFirestoreCommit(1);

    firestore.putDocuments([
      commit,
      generateFirestoreTask(
        1,
        name: 'Linux flutter_release_builder',
        attempts: 1,
        status: fs.Task.statusFailed,
        commitSha: '1',
      ),
    ]);

    tester.requestData = {
      'branch': commit.branch,
      'repo': commit.slug.name,
      'commit': commit.sha,
      'task': 'Linux flutter_release_builder',
    };

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('Rerun all ignores flutter_release_builder', () async {
    final commit = generateFirestoreCommit(1);

    firestore.putDocuments([
      commit,
      generateFirestoreTask(
        1,
        name: 'Linux flutter_release_builder',
        attempts: 1,
        status: fs.Task.statusFailed,
        commitSha: '1',
      ),
    ]);

    tester.requestData = {
      'branch': commit.branch,
      'repo': commit.slug.name,
      'commit': commit.sha,
      'task': 'all',
    };

    await tester.post(handler);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux flutter_release_builder')
            .hasCurrentAttempt(1)
            .hasStatus(fs.Task.statusFailed),
      ]),
    );
  });

  test('No matching target fails with a 500', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestore.putDocument(fsCommit);
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Windows C',
        commitSha: fsCommit.sha,
        status: fs.Task.statusSucceeded,
      ),
    );

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': 'Windows C',
    };

    when(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    ).thenAnswer((_) async => false);

    await expectLater(
      tester.post(handler),
      throwsA(isA<InternalServerError>()),
    );

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    );

    expect(
      log,
      bufferedLoggerOf(
        contains(
          logThat(
            severity: atLeastWarning,
            message: contains('No matching target'),
          ),
        ),
      ),
    );
  });

  test('Re-schedule without any parameters raises exception', () async {
    tester.requestData = <String, dynamic>{};
    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('Fails if task is not rerun', () async {
    when(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        task: anyNamed('task'),
      ),
    ).thenAnswer((_) async => false);

    final fsCommit = generateFirestoreCommit(1);
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: Task.statusFailed,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': fsTask.taskName,
    };

    expect(() => tester.post(handler), throwsA(isA<InternalServerError>()));
  });
}
