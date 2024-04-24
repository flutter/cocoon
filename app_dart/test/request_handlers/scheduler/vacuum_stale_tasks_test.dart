// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as firestore_commit;
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  group(VacuumStaleTasks, () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late VacuumStaleTasks handler;
    late MockFirestoreService mockFirestoreService;

    final Commit commit = generateCommit(1);

    final firestore_commit.Commit firestoreCommit = generateFirestoreCommit(1);

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      config = FakeConfig(firestoreService: mockFirestoreService);
      config.db.values[commit.key] = commit;

      tester = RequestHandlerTester();
      handler = VacuumStaleTasks(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );

      final List<firestore.Task> originalFirestoreTasks = <firestore.Task>[
        generateFirestoreTask(
          1,
          status: firestore.Task.statusInProgress,
          commitSha: firestoreCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: firestore.Task.statusSucceeded,
          commitSha: firestoreCommit.sha,
        ),
        // Task 3 should be vacuumed
        generateFirestoreTask(
          3,
          status: firestore.Task.statusInProgress,
          commitSha: firestoreCommit.sha,
        ),
      ];

      final List<firestore.FullTask> originalFullTasks =
          originalFirestoreTasks.map((firestore.Task task) => firestore.FullTask(task, firestoreCommit)).toList();

      final List<String> repositories = ['cocoon', 'engine', 'packages', 'flutter'];

      // Loop through repos to cover all mocking scenarios
      for (String repository in repositories) {
        when(
          mockFirestoreService.queryRecentTasks(
            taskName: anyNamed('taskName'),
            commitLimit: 20,
            branch: anyNamed('branch'),
            slug: RepositorySlug('flutter', repository),
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<List<firestore.FullTask>>.value(originalFullTasks);
        });
      }

      when(
        mockFirestoreService.writeViaTransaction(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<CommitResponse>.value(CommitResponse());
      });
    });

    test('skips when no tasks are stale', () async {
      final List<Task> originalTasks = <Task>[
        generateTask(
          1,
          status: Task.statusInProgress,
          parent: commit,
          buildNumber: 123,
        ),
      ];
      await config.db.commit(inserts: originalTasks);

      await tester.get(handler);

      final List<Task> tasks = config.db.values.values.whereType<Task>().toList();
      expect(tasks[0].status, Task.statusInProgress);
    });

    test('resets stale task', () async {
      final List<Task> originalTasks = <Task>[
        generateTask(
          1,
          status: Task.statusInProgress,
          parent: commit,
        ),
        generateTask(
          2,
          status: Task.statusSucceeded,
          parent: commit,
        ),
        // Task 3 should be vacuumed
        generateTask(
          3,
          status: Task.statusInProgress,
          parent: commit,
        ),
      ];

      final DatastoreService datastore = DatastoreService(config.db, 5);
      await datastore.insert(originalTasks);

      await tester.get(handler);

      final List<Task> tasks = config.db.values.values.whereType<Task>().toList();
      expect(tasks[0].createTimestamp, 0);
      expect(tasks[0].status, Task.statusNew);
      expect(tasks[2].createTimestamp, 0);
      expect(tasks[2].status, Task.statusNew);

      final List<dynamic> captured = verify(mockFirestoreService.writeViaTransaction(captureAny)).captured;
      expect(captured.length, 1);
      final List<Write> commitResponse = captured[0] as List<Write>;
      expect(commitResponse.length, 2);
      final firestore.Task taskDocuemnt1 = firestore.Task.fromDocument(taskDocument: commitResponse[0].update!);
      final firestore.Task taskDocuemnt2 = firestore.Task.fromDocument(taskDocument: commitResponse[0].update!);
      expect(taskDocuemnt1.status, firestore.Task.statusNew);
      expect(taskDocuemnt2.status, firestore.Task.statusNew);
    });
  });
}
