// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
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

    final commit = generateCommit(1);

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      config = FakeConfig(firestoreService: mockFirestoreService);
      config.db.values[commit.key] = commit;

      tester = RequestHandlerTester();
      handler = VacuumStaleTasks(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
    });

    test('skips when tasks have a build number', () async {
      final originalTasks = <Task>[
        generateTask(
          1,
          status: Task.statusInProgress,
          parent: commit,
          buildNumber: 123,
        ),
      ];
      await config.db.commit(inserts: originalTasks);

      await tester.get(handler);

      final tasks = config.db.values.values.whereType<Task>().toList();
      expect(tasks[0].status, Task.statusInProgress);
    });

    test(
      'skips when tasks are not yet old enough to be considered stale',
      () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final originalTasks = <Task>[
          generateTask(
            1,
            status: Task.statusInProgress,
            parent: commit,
            created: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ];
        await config.db.commit(inserts: originalTasks);

        await tester.get(handler);

        final tasks = config.db.values.values.whereType<Task>().toList();
        expect(tasks[0].status, Task.statusInProgress);
      },
    );

    test('resets stale task', () async {
      when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<CommitResponse>.value(CommitResponse());
      });
      final originalTasks = <Task>[
        generateTask(1, status: Task.statusInProgress, parent: commit),
        generateTask(2, status: Task.statusSucceeded, parent: commit),
        // Task 3 should be vacuumed
        generateTask(
          3,
          status: Task.statusInProgress,
          parent: commit,
          created: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];
      final datastore = DatastoreService(config.db, 5);
      await datastore.insert(originalTasks);

      await tester.get(handler);

      final tasks = config.db.values.values.whereType<Task>().toList();
      expect(tasks[0].status, Task.statusNew);
      expect(tasks[2].status, Task.statusNew);

      final captured =
          verify(mockFirestoreService.writeViaTransaction(captureAny)).captured;
      expect(captured.length, 1);
      final commitResponse = captured[0] as List<Write>;
      expect(commitResponse.length, 2);
      final taskDocuemnt1 = firestore.Task.fromDocument(
        taskDocument: commitResponse[0].update!,
      );
      final taskDocuemnt2 = firestore.Task.fromDocument(
        taskDocument: commitResponse[0].update!,
      );
      expect(taskDocuemnt1.status, firestore.Task.statusNew);
      expect(taskDocuemnt2.status, firestore.Task.statusNew);
    });
  });
}
