// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/utilities/entity_generators.dart';

void main() {
  group(VacuumStaleTasks, () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late VacuumStaleTasks handler;

    final Commit commit = generateCommit(1);
    final DateTime now = DateTime(2023, 2, 9, 13, 37);

    /// Helper function for returning test times relative to [now].
    DateTime relativeToNow(int minutes) {
      final Duration duration = Duration(minutes: minutes);

      return now.subtract(duration);
    }

    setUp(() {
      config = FakeConfig();
      config.db.values[commit.key] = commit;

      tester = RequestHandlerTester();
      handler = VacuumStaleTasks(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
    });

    test('skips when no tasks are stale', () async {
      final List<Task> expectedTasks = <Task>[
        generateTask(
          1,
          status: Task.statusInProgress,
          created: relativeToNow(1),
          parent: commit,
        ),
        generateTask(
          2,
          status: Task.statusSucceeded,
          created: relativeToNow(VacuumStaleTasks.kTimeoutLimit.inMinutes + 5),
          parent: commit,
        ),
        generateTask(
          3,
          status: Task.statusInProgress,
          created: relativeToNow(VacuumStaleTasks.kTimeoutLimit.inMinutes),
          parent: commit,
        ),
      ];
      await config.db.commit(inserts: expectedTasks);

      await tester.get(handler);

      final List<Task> tasks = config.db.values.values.whereType<Task>().toList();
      expect(tasks, expectedTasks);
    });

    test('resets stale task', () async {
      final List<Task> originalTasks = <Task>[
        generateTask(
          1,
          status: Task.statusInProgress,
          created: relativeToNow(1),
          parent: commit,
        ),
        generateTask(
          2,
          status: Task.statusSucceeded,
          created: relativeToNow(VacuumStaleTasks.kTimeoutLimit.inMinutes + 5),
          parent: commit,
        ),
        // Task 3 should be vacuumed
        generateTask(
          3,
          status: Task.statusInProgress,
          created: relativeToNow(VacuumStaleTasks.kTimeoutLimit.inMinutes + 1),
          parent: commit,
        ),
      ];
      final DatastoreService datastore = DatastoreService(config.db, 5);
      await datastore.insert(originalTasks);

      await tester.get(handler);

      final List<Task> tasks = config.db.values.values.whereType<Task>().toList();
      expect(tasks[0], originalTasks[0]);
      expect(tasks[1], originalTasks[1]);
      expect(tasks[2].status, Task.statusNew);
      expect(tasks[2].createTimestamp, 0);
    });
  });
}
