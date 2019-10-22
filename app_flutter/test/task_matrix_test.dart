// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/task_box.dart';
import 'package:app_flutter/task_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

void main() {
  group('TaskMatrix', () {
    CommitStatus statusA;
    CommitStatus statusB;

    List<CommitStatus> statuses;

    TaskMatrix matrix;

    setUp(() {
      statusA = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..status = TaskBox.statusSucceeded
                    ..stageName = 'A'
                    ..name = '1')
              ..tasks.insert(
                  1,
                  Task()
                    ..status = TaskBox.statusSucceeded
                    ..stageName = 'A'
                    ..name = '2'));

      statusB = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..status = TaskBox.statusFailed
                    ..stageName = 'A'
                    ..name = '1')
              ..tasks.insert(
                  1,
                  Task()
                    ..status = TaskBox.statusFailed
                    ..stageName = 'A'
                    ..name = '2'));

      statuses = <CommitStatus>[statusA, statusB];

      matrix = TaskMatrix(statuses: statuses);
    });

    test('task column key', () {
      final String key = matrix.taskColumnKey(Task()
        ..stageName = 'A'
        ..name = '1');

      expect(key, 'A:1');
    });

    test('create task matrix', () {
      final List<Column> matrix =
          TaskMatrix(statuses: statuses).createTaskMatrix(statuses);

      expect(matrix[0].tasks[0], statusA.stages[0].tasks[0]);
      expect(matrix[0].tasks[1], statusB.stages[0].tasks[0]);
      expect(matrix[1].tasks[0], statusA.stages[0].tasks[1]);
      expect(matrix[1].tasks[1], statusB.stages[0].tasks[1]);
    });

    test('create task matrix that has skips', () {
      final CommitStatus statusC = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..status = TaskBox.statusSucceeded
                    ..stageName = 'C'
                    ..name = 'special task'));

      final List<CommitStatus> statusesABC = <CommitStatus>[
        statusA,
        statusB,
        statusC
      ];
      final TaskMatrix matrix = TaskMatrix(statuses: statusesABC);
      
      expect(matrix.task(0, 0), statusC.stages[0].tasks[0]);
      expect(matrix.task(0, 1), isNull);
      expect(matrix.task(1, 0), isNull);
      expect(matrix.task(1, 1), statusB.stages[0].tasks[0]);

      expect(matrix.sampleTask(0), statusC.stages[0].tasks[0]);
      expect(matrix.sampleTask(1), statusB.stages[0].tasks[0]);
    });

    test('sorting by recently failed', () {});

    test('create column key index works', () {});
  });
}
