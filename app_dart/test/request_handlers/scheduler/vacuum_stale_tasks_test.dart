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
    });
  });
}
