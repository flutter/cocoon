// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
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
  late Commit commit;
  late Task task;
  late FakeCiYamlFetcher ciYamlFetcher;

  final firestoreTask = generateFirestoreTask(1, attempts: 1);

  setUp(() {
    final datastoreDB = FakeDatastoreDB();
    final clientContext = FakeClientContext();
    firestoreService = FakeFirestoreService();
    clientContext.isDevelopmentEnvironment = false;
    config = FakeConfig(
      dbValue: datastoreDB,
      keyHelperValue: FakeKeyHelper(
        applicationContext: clientContext.applicationContext,
      ),
      supportedBranchesValue: <String>[
        Config.defaultBranch(Config.flutterSlug),
      ],
      firestoreService: firestoreService,
    );
    final authContext = FakeAuthenticatedContext(clientContext: clientContext);
    tester = ApiRequestHandlerTester(context: authContext);
    mockLuciBuildService = MockLuciBuildService();
    ciYamlFetcher = FakeCiYamlFetcher(ciYaml: exampleConfig);
    handler = RerunProdTask(
      config: config,
      authenticationProvider: FakeAuthenticationProvider(
        clientContext: clientContext,
      ),
      luciBuildService: mockLuciBuildService,
      ciYamlFetcher: ciYamlFetcher,
    );
    commit = generateCommit(1);
    task = generateTask(
      1,
      name: 'Linux A',
      parent: commit,
      status: Task.statusFailed,
    );
    tester.requestData = {
      'branch': commit.branch,
      'repo': commit.slug.name,
      'commit': commit.sha,
      'task': task.name,
    };

    // ignore: discarded_futures
    firestoreService.putDocument(firestoreTask);

    when(
      // ignore: discarded_futures
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
      ),
    ).thenAnswer((_) async => true);
  });

  test('Schedule new task', () async {
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final fsCommit = generateFirestoreCommit(1);
    final fsTask = generateFirestoreTask(
      1,
      status: Task.statusFailed,
      name: 'Linux A',
      commitSha: fsCommit.sha,
    );
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTask);

    expect(await tester.post(handler), Body.empty);

    expect(
      firestoreService,
      existsInStorage(
        fs.Task.metadata,
        contains(
          isTask
              .hasCommitSha(commit.sha)
              .hasTaskName(task.name)
              .hasCurrentAttempt(task.attempts),
        ),
      ),
    );
  });

  test('Re-schedule passing all the parameters', () async {
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;
    final fsCommit = generateFirestoreCommit(1);
    final fsTask = generateFirestoreTask(
      1,
      status: Task.statusFailed,
      name: 'Linux A',
      commitSha: fsCommit.sha,
    );
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTask);

    expect(await tester.post(handler), Body.empty);
    verify(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
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

    tester.requestData = {...tester.requestData, 'include': Task.statusSkipped};
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

  test('Rerun all failed tasks when task name is all', () async {
    final taskA = generateTask(
      2,
      name: 'Linux A',
      parent: commit,
      status: Task.statusFailed,
    );
    final taskB = generateTask(
      3,
      name: 'Mac A',
      parent: commit,
      status: Task.statusFailed,
    );
    config.db.values[taskA.key] = taskA;
    config.db.values[taskB.key] = taskB;
    config.db.values[commit.key] = commit;

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

    tester.requestData = {...tester.requestData, 'task': 'all'};
    await tester.post(handler);

    verify(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
      ),
    ).called(2);
  });

  test('Rerun all runs nothing when everything is passed', () async {
    final task = generateTask(
      2,
      name: 'Windows A',
      parent: commit,
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;

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

    tester.requestData = {...tester.requestData, 'task': 'all'};
    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
      ),
    );
  });

  test('Rerun all runs nothing when everything is skipped', () async {
    final task = generateTask(
      2,
      name: 'Windows A',
      parent: commit,
      status: Task.statusSkipped,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;

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

    tester.requestData = {...tester.requestData, 'task': 'all'};
    await tester.post(handler);

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
      ),
    );
  });

  test('Rerun all can optionally include other statuses (skipped)', () async {
    final task = generateTask(
      2,
      name: 'Windows A',
      parent: commit,
      status: Task.statusSkipped,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;

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
      ...tester.requestData,
      'task': 'all',
      'include': Task.statusSkipped,
    };
    await tester.post(handler);

    verify(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
      ),
    ).called(1);
  });

  test('Rerun all can verifies included statuses are valid', () async {
    final fsCommit = generateFirestoreCommit(1);
    firestoreService.putDocument(fsCommit);

    tester.requestData = {
      ...tester.requestData,
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
    final task = generateTask(
      2,
      // This task is in datastore, but not in .ci.yaml.
      name: 'Windows C',
      parent: commit,
      status: Task.statusSucceeded,
    );
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;

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

    tester.requestData = {...tester.requestData, 'task': 'Windows C'};
    await expectLater(
      tester.post(handler),
      throwsA(isA<InternalServerError>()),
    );

    verifyNever(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
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

  test(
    'Re-schedule existing task even though taskName is missing in the task',
    () async {
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;

      final fsCommit = generateFirestoreCommit(1);
      final fsTask = generateFirestoreTask(
        1,
        name: 'Linux A',
        commitSha: fsCommit.sha,
        status: Task.statusFailed,
      );
      firestoreService.putDocument(fsCommit);
      firestoreService.putDocument(fsTask);

      expect(await tester.post(handler), Body.empty);
    },
  );

  test('Fails if task is not rerun', () async {
    when(
      mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
        taskDocument: anyNamed('taskDocument'),
      ),
    ).thenAnswer((_) async => false);
    config.db.values[task.key] = task;
    config.db.values[commit.key] = commit;

    final fsCommit = generateFirestoreCommit(1);
    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux A',
      commitSha: fsCommit.sha,
      status: Task.statusFailed,
    );
    firestoreService.putDocument(fsCommit);
    firestoreService.putDocument(fsTask);

    expect(() => tester.post(handler), throwsA(isA<InternalServerError>()));
  });
}
