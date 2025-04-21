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
  late FakeFirestoreService firestoreService;
  late ApiRequestHandlerTester tester;
  late FakeCiYamlFetcher ciYamlFetcher;

  setUp(() {
    final clientContext = FakeClientContext();
    firestoreService = FakeFirestoreService();
    clientContext.isDevelopmentEnvironment = false;
    config = FakeConfig(
      supportedBranchesValue: <String>[
        Config.defaultBranch(Config.flutterSlug),
      ],
      firestoreService: firestoreService,
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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTask);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': fsTask.taskName,
    };

    expect(await tester.post(handler), Body.empty);

    expect(
      firestoreService,
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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTask);

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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTask);

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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTaskA);
    firestoreService.putDocument(fsTaskB);

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
      firestoreService,
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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(
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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(
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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(
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
      firestoreService,
      existsInStorage(
        fs.Task.metadata,
        unorderedEquals([
          isTask
              .hasTaskName('Windows A')
              .hasStatus(fs.Task.statusSkipped)
              .hasCurrentAttempt(1),
          isTask
              .hasTaskName('Windows A')
              .hasStatus(fs.Task.statusNew)
              .hasCurrentAttempt(2),
        ]),
      ),
    );
  });

  test('Rerun all cancels in-progress tasks', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(
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
      firestoreService,
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
    firestoreService.putDocument(fsCommit);

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

  test('No matching target fails with a 500', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(
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
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTask);

    tester.requestData = {
      'branch': fsCommit.branch,
      'repo': fsCommit.slug.name,
      'commit': fsCommit.sha,
      'task': fsTask.taskName,
    };

    expect(() => tester.post(handler), throwsA(isA<InternalServerError>()));
  });
}
