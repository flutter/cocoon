// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/task_box.dart';
import 'package:app_flutter/task_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

void main() {
  group('TaskMatrix', () {
    test('create task matrix', () {});

    test('create task matrix that has skips', () {
      final CommitStatus statusA = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..status = TaskBox.statusSucceeded
                    ..stageName = 'A'
                    ..name = 'special task'));

      final CommitStatus statusB = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..status = TaskBox.statusSucceeded
                    ..stageName = 'B'
                    ..name = 'special task'));

      final List<CommitStatus> statusesAB = <CommitStatus>[statusA, statusB];
      final TaskMatrix matrix = TaskMatrix(statuses: statusesAB);

      print(matrix.task(0, 0));
      print(matrix.task(0, 1));
      print(matrix.task(1, 0));
      print(matrix.task(1, 1));
      
      expect(matrix.task(0, 1), statusA.stages[0].tasks[0]);
      expect(matrix.task(0, 0), isNull);
      expect(matrix.task(1, 1), isNull);
      expect(matrix.task(1, 0), statusB.stages[0].tasks[0]);
    });

    test('sorting by recently failed', () {});
  });
}
