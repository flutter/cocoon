// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/build_status_provider/commit_tasks_status.dart';
import 'package:test/test.dart';

import '../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  group('collateTasksByTaskName', () {
    test('surfaces the latest task as FullTask.task', () {
      final status = CommitTasksStatus(generateFirestoreCommit(1), [
        generateFirestoreTask(1, attempts: 2, buildNumber: 1002),
        generateFirestoreTask(1, attempts: 3, buildNumber: 1003),
        generateFirestoreTask(1, attempts: 1, buildNumber: 1001),
      ]);

      final collate = status.collateTasksByTaskName();
      expect(collate, [
        isA<FullTask>()
            .having((t) => t.task.taskName, 'task.taskName', 'task1')
            .having((t) => t.task.currentAttempt, 'task.attempts', 3)
            .having((t) => t.buildList, 'buildList', [1001, 1002, 1003]),
      ]);
    });

    test('skips null build numbers', () {
      final status = CommitTasksStatus(generateFirestoreCommit(1), [
        generateFirestoreTask(1, attempts: 2, buildNumber: 1002),
        generateFirestoreTask(1, attempts: 3, buildNumber: null),
        generateFirestoreTask(1, attempts: 1, buildNumber: 1001),
      ]);

      final collate = status.collateTasksByTaskName();
      expect(collate, [
        isA<FullTask>()
            .having((t) => t.task.taskName, 'task.taskName', 'task1')
            .having((t) => t.task.currentAttempt, 'task.attempts', 3)
            .having((t) => t.buildList, 'buildList', [1001, 1002]),
      ]);
    });
  });
}
