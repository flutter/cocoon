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
    List<List<Task>> taskMatrix;
    List<Task> taskIconRow;

    setUpAll(() async {
      final FakeCocoonService service = FakeCocoonService();
      final CocoonResponse<List<CommitStatus>> response =
          await service.fetchCommitStatuses();
      statuses = response.data;
      final Map<String, int> taskColumnKeyIndex =
          StatusGridContainer.createTaskColumnKeyIndex(statuses);
      taskMatrix =
          StatusGridContainer.createTaskMatrix(statuses, taskColumnKeyIndex);
      taskIconRow =
          StatusGridContainer.createTaskIconRow(statuses, taskColumnKeyIndex);
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
                taskMatrix: taskMatrix,
                taskIconRow: taskIconRow,
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
                taskMatrix: taskMatrix,
                taskIconRow: taskIconRow,
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
                taskMatrix: taskMatrix,
                taskIconRow: taskIconRow,
              ),
            ],
          ),
        ),
      );

      final TaskBox lastTaskWidget =
          find.byType(TaskBox).evaluate().last.widget;

      final Task lastTask = taskMatrix.last.last;

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
      expect(taskMatrix.length, statuses.length);
      expect(taskMatrix[0].length, totalTasksInCommitStatus);
    });

    test('task matrix builds correctly when statuses have different tasks', () {
      final CommitStatus statusA = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..stageName = 'special stage'
                    ..name = 'special task'));

      final CommitStatus statusB = CommitStatus()
        ..stages.insert(
            0,
            Stage()
              ..tasks.insert(
                  0,
                  Task()
                    ..stageName = 'different stage'
                    ..name = 'special task'));

      final List<CommitStatus> statusesAB = <CommitStatus>[statusA, statusB];

      final List<List<Task>> tasks = StatusGridContainer.createTaskMatrix(
          statusesAB, StatusGridContainer.createTaskColumnKeyIndex(statusesAB));

      expect(tasks[0].length, 2);
    });
  });
}
