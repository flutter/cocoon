// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/state/flutter_build.dart';
import 'package:app_flutter/commit_box.dart';
import 'package:app_flutter/status_grid.dart';
import 'package:app_flutter/task_box.dart';

void main() {
  group('StatusGrid', () {
    List<CommitStatus> statuses;

    StatusGridHelper helper;

    setUpAll(() async {
      final FakeCocoonService service = FakeCocoonService();
      final CocoonResponse<List<CommitStatus>> response =
          await service.fetchCommitStatuses();
      statuses = response.data;
      helper = StatusGridHelper(statuses: statuses);
    });

    testWidgets('shows loading indicator when statuses is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              ChangeNotifierProvider<FlutterBuildState>(
                builder: (_) => FlutterBuildState(),
                child: const StatusGridContainer(),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('commits show in the same column', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              StatusGrid(
                statuses: statuses,
                taskColumnMap: helper.taskColumnMap,
                taskMatrix: helper.taskMatrix,
                taskIconRow: helper.taskIconRow,
              ),
            ],
          ),
        ),
      );

      final List<Element> commits = find.byType(CommitBox).evaluate().toList();

      final double xPosition = commits.first.size.topLeft(Offset.zero).dx;

      for (Element commit in commits) {
        // All the x positions should match the first instance if they're all in the same column
        expect(commit.size.topLeft(Offset.zero).dx, xPosition);
        tester.takeException();
      }
    });

    testWidgets('first task in grid is the first task given',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              StatusGrid(
                statuses: statuses,
                taskColumnMap: helper.taskColumnMap,
                taskMatrix: helper.taskMatrix,
                taskIconRow: helper.taskIconRow,
              ),
            ],
          ),
        ),
      );

      final TaskBox firstTask = find.byType(TaskBox).evaluate().first.widget;
      expect(firstTask.task, statuses[0].stages[0].tasks[0]);
    });

    testWidgets('last task in grid is the last task given',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              StatusGrid(
                statuses: statuses,
                taskColumnMap: helper.taskColumnMap,
                taskMatrix: helper.taskMatrix,
                taskIconRow: helper.taskIconRow,
              ),
            ],
          ),
        ),
      );

      final TaskBox lastTaskWidget =
          find.byType(TaskBox).evaluate().last.widget;

      final Task lastTask = helper.taskMatrix.last.last;

      expect(lastTaskWidget.task, lastTask);
    });

    int _totalTasksInCommitStatus(CommitStatus status) {
      int totalTasksInCommitStatus = 0;
      for (Stage stage in status.stages) {
        totalTasksInCommitStatus += stage.tasks.length;
      }

      return totalTasksInCommitStatus;
    }

    test('a basic task matrix works', () {
      // The fake data creates a perfect grid, so the task matrix should match statuses

      final int totalTasksInCommitStatus =
          _totalTasksInCommitStatus(statuses[0]);
      expect(helper.taskMatrix.length, statuses.length);
      expect(helper.taskMatrix[0].length, totalTasksInCommitStatus);
    });

    test('task matrix builds correctly when statuses have different tasks', () {
      final CommitStatus statusA = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..status = TaskBox.statusSucceeded
                    ..stageName = 'special stage'
                    ..name = 'special task'));

      final CommitStatus statusB = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..status = TaskBox.statusSucceeded
                    ..stageName = 'different stage'
                    ..name = 'special task'));

      final List<CommitStatus> statusesAB = <CommitStatus>[statusA, statusB];
      final StatusGridHelper helper = StatusGridHelper(statuses: statusesAB);

      expect(helper.taskMatrix[0].length, 2);
    });

    test('sort column key index sorts', () {
      final Map<String, int> columnKeyIndex = <String, int>{
        'A': 0,
        'B': 1,
        'C': 2,
        'D': 3,
        'E': 4,
        'F': 5,
        'G': 6,
      };
      final List<int> weights = <int>[28, 13, 18, 1, 0, 10, 4];

      final Map<String, int> sortedColumnKeyIndex = <String, int>{
        'A': 6,
        'B': 4,
        'C': 5,
        'D': 1,
        'E': 0,
        'F': 3,
        'G': 2,
      };

      expect(StatusGridHelper.sortColumnKeyIndex(columnKeyIndex, weights),
          sortedColumnKeyIndex);
    });

    List<List<Task>> _createTaskMatrix(List<List<String>> matrix) {
      final List<List<Task>> taskMatrix = List<List<Task>>.generate(
          matrix.length, (_) => List<Task>(matrix[0].length));

      for (int row = 0; row < matrix.length; row++) {
        for (int col = 0; col < matrix[0].length; col++) {
          if (matrix[row][col] != null) {
            taskMatrix[row][col] = Task()
              ..status = matrix[row][col]
              ..stageName = '$col'
              ..name = '$col';
          }
        }
      }

      return taskMatrix;
    }

    test('task matrix shows most recent failures in leftmost columns', () {
      final List<List<Task>> matrix = _createTaskMatrix(<List<String>>[
        <String>[
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded
        ],
        <String>[
          TaskBox.statusSucceeded,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded
        ],
        <String>[
          TaskBox.statusFailed,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded
        ],
        <String>[
          TaskBox.statusSucceeded,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded
        ],
      ]);
      final Map<String, int> keyIndex = <String, int>{
        '0:0': 0,
        '1:1': 1,
        '2:2': 2,
        '3:3': 3,
      };

      final Map<int, int> columnMap = StatusGridHelper(statuses: statuses)
          .sortByRecentlyFailed(matrix, keyIndex: keyIndex, tasks: matrix[0]);

      expect(columnMap, <int, int>{
        0: 2,
        1: 1,
        2: 0,
        3: 3,
      });
    });

    test('calculates fail weights correctly', () {
      final List<List<Task>> matrix = _createTaskMatrix(<List<String>>[
        <String>[
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded
        ],
        <String>[
          TaskBox.statusSucceeded,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded
        ],
        <String>[
          TaskBox.statusFailed,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded
        ],
        <String>[
          TaskBox.statusSucceeded,
          TaskBox.statusFailed,
          TaskBox.statusSucceeded,
          TaskBox.statusSucceeded
        ],
      ]);

      final List<int> failWeights = StatusGridHelper(statuses: statuses)
          .calculateRecentlyFailedWeights(matrix);

      expect(failWeights, <int>[2, 1, 0, 4]);
    });
  });
}
